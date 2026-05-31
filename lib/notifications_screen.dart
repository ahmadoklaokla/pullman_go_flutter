import 'package:flutter/material.dart';

import 'notification_details_screen.dart';
import 'notification_service.dart'; // تأكد إنك عامل استيراد لملف الرادار هون

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // دالة لجلب الإشعارات من الداتابيز وتصفير العداد
  Future<void> _loadNotifications() async {
    final notifications = await NotificationService.instance
        .getAllNotifications();

    // بمجرد ما يفتح الصفحة، بنعتبره قرأ كل الإشعارات (تصفير النقطة الحمراء)
    await NotificationService.instance.markAllAsRead();

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // ضروري عشان التنسيق العربي
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            "الإشعارات",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF162D4A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF162D4A)),
              )
            : _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "لا توجد إشعارات حالياً",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. أقصى اليمين: اللوغو الخاص بالشركة
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              notification['logo_url'] ?? '',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              // في حال فشل تحميل الصورة أو مافي نت، بنحط أيقونة احتياطية
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 40,
                                    height: 40,
                                    color: const Color(
                                      0xFF162D4A,
                                    ).withOpacity(0.2),
                                    child: const Icon(
                                      Icons.business,
                                      color: Color(0xFF162D4A),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 2. بالنصف: العنوان والمحتوى (Expanded عشان تاخد باقي المساحة)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'] ?? 'إشعار جديد',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  notification['content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. أقصى اليسار: اسم الشركة والتاريخ
                          // 3. أقصى اليسار: اسم الشركة وزر عرض الرسالة
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // اسم الشركة (الكبسولة الخضراء)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF162D4A,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  notification['name'] ?? 'شركة نقل',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF162D4A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // الزر الجديد: عرض الرسالة (مكان التاريخ القديم)
                              InkWell(
                                onTap: () {
                                  // الانتقال لصفحة التفاصيل عند الضغط على الزر
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NotificationDetailsScreen(
                                            notification: notification,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162D4A),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF162D4A,
                                        ).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "عرض ",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
