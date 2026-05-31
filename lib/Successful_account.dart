import 'package:flutter/material.dart';

import 'custom_button.dart';
import 'hom.dart';

// اسم الكلاس صار متناسق مع اسم الملف الجديد
class SuccessfulAccount extends StatefulWidget {
  const SuccessfulAccount({super.key});

  @override
  State<SuccessfulAccount> createState() => _SuccessfulAccountState();
}

class _SuccessfulAccountState extends State<SuccessfulAccount> {
  /////////////////////************************"ميثود" هي المسؤولة عن تشغيل الحركة أول ما تفتح الصفحة. حطها تحت المتغير اللي عرفناه فوق.
  double _iconSize = 0.0; // أولاً: عرف متغير في أعلى الكلاس للتحكم بالحجم
  @override
  void initState() {
    super.initState();
    // هاد المكان الثاني: بيحكي للتطبيق أول ما تفتح الصفحة استنى شوي وكبّر الأيقونة
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _iconSize = 1.0;
        });
      }
    });
  } ///////////////////////**********************

  bool _isGoHome = false; //مشان الضغط على الزر
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
          ), // مسافة جانبية للكل
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // هاد المكان الثالث: استبدل الأيقونة القديمة بهاد الكود
              AnimatedScale(
                scale: _iconSize,
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut, // الحركة الارتدادية الفخمة
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0x1A4CAF50), // اللون الأخضر مع شفافية
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50),
                    size: 110,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "  🚀!حسابك الآن جاهز للعمل",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5, // تباعد بسيط للحروف
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              const Text(
                "لقد اكتملت عملية التسجيل. يمكنك الآن الاستمتاع بكافة الميزات وإدارة رحلاتك بكل سهولة وأمان",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5, // مسافة بين الأسطر لراحة العين
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 210),

              // الزر الفخم تبعنا (الاهتزاز فقط)
              MyMainButton(
                text: "استكشف وجهتك القادمة",
                onTap: () {
                  // الانتقال للواجهة الرئيسية وتصفير الذاكرة من الصفحات السابقة
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PullmanMainScreen(),
                    ),
                    (route) => false, // هذا السطر يحذف كل الصفحات القديمة
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
