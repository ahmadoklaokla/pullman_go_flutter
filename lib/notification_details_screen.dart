import 'package:flutter/material.dart';

//*******
//هي صفحة تفاصيل الاشعار عندما اضغط على عرش الرسالة
class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            "تفاصيل الإشعار",
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
        body: SingleChildScrollView(
          // عشان لو الرسالة طويلة يقدر ينزل لتحت
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // يمين الشاشة
              children: [
                // --- القسم الأول: اللوغو واسم الشركة (بالنص) ---
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(39),
                        child: Image.network(
                          notification['logo_url'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 80,
                                height: 80,
                                color: const Color(0xFF162D4A).withOpacity(0.2),
                                child: const Icon(
                                  Icons.business,
                                  size: 40,
                                  color: Color(0xFF162D4A),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notification['name'] ?? 'شركة نقل',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF162D4A),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(color: Colors.grey),
                ),

                // --- القسم الثاني: العنوان (يمين) ---
                Text(
                  notification['title'] ?? 'إشعار بدون عنوان',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),

                // --- القسم الثالث: المحتوى (يمين، وياخد راحته بالأسطر) ---
                Text(
                  notification['content'] ?? 'لا يوجد محتوى',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.6, // تباعد الأسطر عشان تكون مريحة للقراءة
                  ),
                ),
                const SizedBox(height: 30),

                // --- القسم الرابع: التاريخ والوقت (أقصى اليسار) ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      notification['created_at'] ??
                          '', // هون رح ينعرض التاريخ والوقت كامل
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textDirection:
                          TextDirection.ltr, // عشان الأرقام تضل مرتبة صح
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
