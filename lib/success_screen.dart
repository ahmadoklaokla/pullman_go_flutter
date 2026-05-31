import 'package:flutter/material.dart';

import 'custom_button.dart'; // الزر النار تبعنا
import 'login_screen.dart'; // صفحة تسجيل الدخول للعودة

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

// 1. استخدام SingleTickerProviderStateMixin للتحكم بالأنيميشن
class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // مدير الحركة
  late Animation<double> _scaleAnimation; // حركة التكبير
  late Animation<double> _opacityAnimation; // حركة الشفافية

  @override
  void initState() {
    super.initState();

    // 2. تعريف التايمر الإجمالي للحركة (ثانية ونصف)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 3. تعريف حركة التكبير: تبدأ من 0 وتنتهي بـ 1.1 (تكبير بسيط ثم رجوع للحجم الطبيعي)
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.7,
        curve: Curves.elasticOut,
      ), // حركة مطاطية ناعمة
    );

    // 4. تعريف حركة الشفافية: تبدأ مخفية وتظهر تدريجياً
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.5,
        curve: Curves.easeIn,
      ), // ظهور ناعم في البداية
    );

    // 5. ابدأ الحركة فوراً عند فتح الصفحة
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // إلغاء المتحكم عند الخروج لحماية الذاكرة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 6. الحصول على أبعاد الشاشة لتنسيق الأبعاد بدقة
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FA,
      ), // خلفية هادئة مائلة للرمادي الفاتح جداً
      body: Container(
        // 7. إضافة تدرج لوني خفيف للخلفية لزيادة الفخامة
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF1F8E9),
            ], // تدرج من الأبيض للأخضر الفاتح جداً
          ),
        ),
        // (SingleChildScrollView)تجعل الـ Padding وما بداخلها (الـ Column) أبناءً للويدجت
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // تأكد إن الـ screenHeight معرفة عندك فوق
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 110,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50), // مسافة ثابتة
                // 9. النصوص التوضيحية بتنسيق High-End
                const Text(
                  "!تمت العملية بنجاح", // عنوان رئيسي
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900, // خط عريض جداً
                    letterSpacing: 0.5, // مسافة بسيطة بين الحروف
                  ),
                ),
                const SizedBox(height: 18), // مسافة
                const Text(
                  "لقد تم تحديث كلمة المرور الخاصة بك بنجاح\nيمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة لضمان أمان حسابك",
                  textAlign: TextAlign.center, // توسيط النص
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    height: 1.6, // مسافة سطر مريحة للعين
                  ),
                ),

                const SizedBox(
                  height: 185,
                ), // يأخذ كل المساحة المتبقية ليدفع الزر للأسفل
                // 10. الزر الكبير في الأسفل بتنسيق احترافي
                MyMainButton(
                  text: "العودة لتسجيل الدخول",
                  isLoading: false,
                  onTap: () {
                    // تنظيف الذاكرة والرجوع لأول صفحة (Login)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.05), // مسافة سفلية مرنة
              ],
            ),
          ),
        ),
      ),
    );
  }
}
