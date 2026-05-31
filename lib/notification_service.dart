import 'dart:io'; // عشان نتعامل مع الملفات

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // المكتبة المسؤولة عن شكل الإشعار
import 'package:http/http.dart' as http; // عشان نحمل صورة الشركة من الرابط
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'; // عشان نعرف وين نخزن الصورة مؤقتاً
import 'package:sqflite/sqflite.dart';

// 1. دالة استقبال الإشعارات والتطبيق مغلق (بالخلفية)
// هاي الدالة لازم تكون برا الكلاس (Top-level) عشان الفلتر يقدر يشغلها والتطبيق مسكر
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // أول ما يوصل إشعار بالخلفية، بنحفظه فوراً بقاعدة البيانات
  await NotificationService.instance.saveMessageToDB(message);
}

class NotificationService {
  // 2. تطبيق نمط Singleton عشان نضمن نسخة وحدة من الرادار شغالة بكل التطبيق
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  // 3. متغير سحري (ValueNotifier) رح نربطه بالنقطة الحمراء بالـ UI
  // أي تغيير على هاد الرقم، النقطة الحمراء رح تتحدث لحالها
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static Database? _database;

  // 4. دالة تهيئة قاعدة البيانات المحلية (SQLite)
  Future<Database> get database async {
    if (_database != null) return _database!;
    //notifications.db قاعدة البيانات على الموبايل
    _database = await _initDB('notifications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // إنشاء جدول الإشعارات مع الحقول اللي بعثناها من اللارافيل
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          notification_id TEXT,
          name TEXT,
          logo_url TEXT,
          title TEXT,
          content TEXT,
          created_at TEXT,
          is_read INTEGER DEFAULT 0 
        )
      '''); // is_read = 0 يعني الإشعار غير مقروء، 1 يعني مقروء
      },
    );
  }

  // 5. تهيئة الفايربيز والرادار (هاي الدالة بنستدعيها أول ما يفتح التطبيق)
  Future<void> initializeFCM() async {
    // --- جديد: إعداد أيقونة الإشعار الصغيرة ---
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
    // ---------------------------------------

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.subscribeToTopic('passenger');
    await updateUnreadCount();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await saveMessageToDB(message);
      await updateUnreadCount();

      // --- جديد: استدعاء دالة إظهار الإشعار باللوغو الملون ---
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // 6. دالة تفكيك البيانات الجاية من السيرفر وحفظها بالداتابيز
  Future<void> saveMessageToDB(RemoteMessage message) async {
    final db = await instance.database;

    // بنسحب المتغيرات من مصفوفة الـ Data اللي بعثناها من اللارافيل
    // استخدمنا التسميات بالضبط مثل ما عملناها بملف الـ PHP
    final notificationData = {
      'notification_id': message.data['notification_id'] ?? '',
      'name': message.data['name'] ?? 'PULLMAN GO',
      'logo_url': message.data['logo_url'] ?? '',
      'title':
          message.data['title'] ?? message.notification?.title ?? 'إشعار جديد',
      'content': message.data['content'] ?? message.notification?.body ?? '',
      'created_at': message.data['created_at'] ?? DateTime.now().toString(),
      'is_read': 0, // إشعار جديد يعني غير مقروء
    };

    await db.insert('notifications', notificationData);
  }

  // 7. دالة جلب كل الإشعارات المحفوظة (عشان نعرضهم بصفحة الإشعارات لاحقاً)
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await instance.database;
    // بنجيبهم مرتبين من الأحدث للأقدم
    return await db.query('notifications', orderBy: 'id DESC');
  }

  // 8. دالة تحديث عداد الإشعارات الغير مقروءة (للنقطة الحمراء)
  Future<void> updateUnreadCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM notifications WHERE is_read = 0',
    );
    int count = Sqflite.firstIntValue(result) ?? 0;

    // تغيير قيمة الـ ValueNotifier رح يخلي الـ UI يتحدث فوراً
    unreadCount.value = count;
  }

  // 9. دالة تحويل كل الإشعارات لـ "مقروءة" (لما المستخدم يفتح صفحة الإشعارات)
  Future<void> markAllAsRead() async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE notifications SET is_read = 1 WHERE is_read = 0',
    );
    await updateUnreadCount(); // تصفير النقطة الحمراء
  }

  // دالة لتحميل صورة الشركة وعرضها كأيقونة كبيرة في الإشعار
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final String logoUrl = message.data['logo_url'] ?? '';
    String? largeIconPath;

    // إذا فيه رابط صورة، بنحملها فوراً
    if (logoUrl.isNotEmpty) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        largeIconPath = '${directory.path}/largeIcon';
        final response = await http.get(Uri.parse(logoUrl));
        await File(largeIconPath).writeAsBytes(response.bodyBytes);
      } catch (e) {
        largeIconPath = null; // لو فشل التحميل بنعرض الإشعار بدون صورة
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'passenger_channel',
      'إشعارات المسافرين',
      importance: Importance.max,
      priority: Priority.high,
      // هاي أهم نقطة: عرض الصورة المحملة
      largeIcon: largeIconPath != null
          ? FilePathAndroidBitmap(largeIconPath)
          : null,
    );

    await _localNotifications.show(
      message.hashCode,
      message.data['title'] ?? 'إشعار جديد',
      message.data['content'] ?? '',
      NotificationDetails(android: androidDetails),
    );
  }
}
