import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'hom.dart';
import 'login_screen.dart';

//هي ال async تزامنية بين التطبيق والفايربيز
void main() async {
  // 1. لازم نأكد إن كل شي جاهز في النظام
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تشغيل الفايربيز
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 🌟  السطر الذهبي: بخلي التطبيق يشترك بقروب اسمه "passenger" 🌟
  // اللارافيل رح يبعث الإشعارات لهاد القروب، فكل جوال رح يصله الإشعار
  await FirebaseMessaging.instance.subscribeToTopic('passenger');

  // 3. تشغيل التطبيق تبعك
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. إعداد محرك الأنميشن (مدته ثانية ونصف)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 2. أنميشن التكبير الارتدادي للّوغو
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut, // حركة بوب ارتدادية فخمة
      ),
    );

    // 3. أنميشن ظهور النص بالتدريج بعد ظهور اللوغو مباشرة
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // تشغيل الأنميشن فوراً عند فتح الشاشة
    _animationController.forward();

    // مدة بقاء شاشة اللوغو (3 ثواني) ثم فحص حالة المستخدم
    Timer(const Duration(seconds: 3), () async {
      // فتح ذاكرة الجوال الداخلية
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. فحص هل هي أول مرة يفتح فيها التطبيق كاملاً؟
      bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

      // 2. فحص هل المستخدم مسجل دخول حالياً؟
      bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (mounted) {
        if (isFirstTime) {
          // حالة 1: أول مرة يفتح التطبيق -> خده على واجهات الترحيب
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const IntroScreen()),
          );
        } else if (isLoggedIn) {
          // حالة 2: فات قبل هالمرة ومسجل دخول ومو عامل تسجيل خروج -> طير فيه عالرئيسية فوراً
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PullmanMainScreen()),
          );
        } else {
          // حالة 3: فات قبل هالمرة بس مو مسجل دخول (أو عامل تسجيل خروج) -> خده على صفحة تسجيل الدخول
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // الحفاظ على تنظيف الذاكرة دائماً
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D273A),
      body: Stack(
        children: [
          // 1. إضافة أنميشن الخريطة (Lottie) في أسفل شاشة السبلاش سكرين بشكل احترافي
          // الأنميشن الأسفل: دبوس الموقع الواقعي والذكي
          Positioned(
            bottom: 60, // متموضع بالأسفل بشكل متناسق
            left: 0,
            right: 0,
            child: const RealisticPinAnimation(),
          ),

          // 2. محتوى الشاشة الأساسي (اللوغو والنص) يظل بالمنتصف تماماً فوق الأنميشن السفلي
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // تطبيق أنميشن التكبير على اللوغو
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.3),
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // تطبيق أنميشن الظهور التدريجي على النص
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'PULLMAN GO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing:
                          4, // زيادة التباعد قليلاً للمسة جمالية واحترافية
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// كلاس للشاشة الترحيب الشخصي للمستخدمين الي بعد اللوغو او السبلاش سكرين
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // سرعة اللمعة
    )..repeat();
  }

  //بيمسح" الأنميشن من ذاكرة الجوال تماماً
  @override
  void dispose() {
    //وقف النبض فوراً عشان تريح المعالج
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1D2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. البسملة
            const Text(
              'بِسْــمِ اللَّـهِ الرَّحْمَــٰنِ الرَّحِيـمِ',
              style: TextStyle(color: Colors.white70, fontSize: 22),
            ),
            const SizedBox(height: 40),

            // 2. الإيموجي
            const Text('👋', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 30),

            const Text(
              'أهلاً بك في عائلة',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),

            // 3. النص اللامع
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [
                        _controller.value - 0.2,
                        _controller.value,
                        _controller.value + 0.2,
                      ],
                      colors: [
                        const Color(0xFF162D4A),
                        Colors.white,
                        const Color(0xFF162D4A),
                      ],
                    ).createShader(rect);
                  },
                  child: const Text(
                    'PULLMAN GO',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900, // استخدمنا w900 بدل black
                      letterSpacing: 2,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'رحلتك القادمة تبدأ بضغطة زر واحدة فقط.استعد للراحة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),

            const SizedBox(height: 50),
            // هاد هو الكود اللي سألت عنه (الزر مع النبض والتوهج)
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF162D4A,
                          ).withOpacity(0.3 * _controller.value),
                          blurRadius: 15,
                          spreadRadius: 5 * _controller.value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF162D4A),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'لنبدأ الرحلة 🚀',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//الشاشة الترحيبية الاولى
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // 1. هون حط التعريفات (قبل أي شي ثاني)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  double _buttonScale = 1.0; // هاد المتغير القديم تبعك خليه مثل ما هو
  //المسؤولة عن تشغيل النبض أول ما تفتح الشاشة
  @override
  void initState() {
    super.initState();
    // هون المحرك بيبدأ يشتغل
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  //تطفي المحرك لما تطلع من الشاشة عشان توفر بطارية
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        // استخدمنا Stack عشان نتحكم بمكان الزر والنقاط بدقة
        children: [
          Column(
            children: [
              // 1. الصورة العلوية الاولى
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/images/onboarding1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // 2. النصوص مع النجمة اللي بتلمع
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- هون حطينا كود اللمعة للنجمة ---
                  Stack(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 28)),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: [
                                    _pulseController.value - 0.2,
                                    _pulseController.value,
                                    _pulseController.value + 0.2,
                                  ],
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ).createShader(rect);
                              },
                              child: const Text(
                                '✨',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // --- نهاية كود اللمعة ---
                  const Text(
                    ' راحة في كل مكان',
                    style: TextStyle(
                      color: Color(0xFF000814),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'حجوزات سهلة ومقاعد مريحة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF000814), fontSize: 19),
              ),
            ],
          ),

          // 3. النقاط في المنتصف (بالأسفل)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(true), //النقطة الاولى هي الي شغالة
                const SizedBox(width: 8),
                _buildDot(false),
                const SizedBox(width: 8),
                _buildDot(false),
              ],
            ),
          ),

          // زر السهم مع حركة النبض والانتقال
          Positioned(
            bottom: 80,
            right: 30,
            child: ScaleTransition(
              scale: _pulseAnimation, // <<< تم إضافة الربط بالنبض هنا
              child: GestureDetector(
                onTap: () {
                  // دالة الانتقال الفخمة (Slide)
                  Navigator.of(context).push(_createRoute());
                },
                // شكل الدائرة الي حوالي السهم في الشاشة الترحيبية الاولى
                child: AnimatedScale(
                  scale: _buttonScale, // هون بنطبق الحجم
                  duration: const Duration(milliseconds: 100),
                  child: Hero(
                    tag: 'arrow_button', // ويدجت الـ Hero بتبدأ هون
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162D4A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ), // إغلاق الـ Container
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة الانتقال "من اليمين لليسار"
  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SecondOnboarding(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutQuart));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  //تصميم النقاط
  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 30 : 10,
      decoration: BoxDecoration(
        // إذا كانت النقطة شغالة خليها أخضر، وإذا لا خليها رمادي غامق عشان تبين عالأبيض
        color: isActive ? Color(0xFF162D4A) : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

//الشاشة الترحيبية الثانية
class SecondOnboarding extends StatefulWidget {
  const SecondOnboarding({super.key});

  @override
  State<SecondOnboarding> createState() => _SecondOnboardingState();
}

class _SecondOnboardingState extends State<SecondOnboarding>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // إعداد المحرك المسؤول عن الحركات (مدة الدورة ثانية واحدة)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // الحركة بتروح وبترجع بشكل مستمر

    // 1. أنميشن النبض للدائرة (بتكبر من 1.0 لـ 1.12)
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 2. أنميشن اللمعان للسمايل (بيغير الشفافية من 0.3 لـ 1.0)
    _shimmerAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose(); // تنظيف الذاكرة عند الخروج
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. الصورة العلوية للشاشة الثانية (حجز بكل سهولة)
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/images/onboarding2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // 2. العنوان الجديد مع السمايل اللي بيلمع بمسحة ضوء
              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  // 1. النص العريض أولاً (بيظهر عاليمين)
                  const Text(
                    'حجز بكل سهولة',
                    style: TextStyle(
                      color: Color(0xFF000814),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 2. الموبايل اللامع (بيظهر على يسار النص)
                  Stack(
                    children: [
                      // الموبايل الأصلي
                      const Text('📱', style: TextStyle(fontSize: 32)),

                      // طبقة اللمعة اللي بتمر من فوق الموبايل
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: [
                                    _controller.value - 0.2,
                                    _controller.value,
                                    _controller.value + 0.2,
                                  ],
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ).createShader(rect);
                              },
                              child: const Text(
                                '📱', // تأكد إنك غيرت الإيموجي هون كمان
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 3. النص الفرعي الجديد
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '، اختر رحلتك واحجز مقعدك في ثواني\nواجهة بسيطة مصممة لضمان راحتك ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF000814), fontSize: 19),
                ),
              ),
            ],
          ),

          // 4. النقاط (النقطة الثانية هي النشطة)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(false),
                const SizedBox(width: 8),
                _buildDot(true), // النقطة الثانية هي الي شغالة
                const SizedBox(width: 8),
                _buildDot(false),
              ],
            ),
          ),

          // 5. زر السهم مع الدائرة النابضة بشكل مستمر
          Positioned(
            bottom: 80,
            right: 30,
            child: ScaleTransition(
              scale: _pulseAnimation, // تأثير النبض المستمر للدائرة
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, anim, secAnim) =>
                          const ThirdOnboarding(),
                      transitionsBuilder: (context, anim, secAnim, child) {
                        // تأثير السحب الناعم (Slide)
                        return SlideTransition(
                          position: anim.drive(
                            Tween(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: Curves.easeOutQuart)),
                          ),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Hero(
                  tag:
                      'arrow_button', // لازم يكون نفس الـ tag اللي بالشاشة الأولى بالظبط
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162D4A), // أخضر فاتح وفخم
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ), // تأكد من إغلاق قوس الـ Hero هون
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت النقاط ( التصميم )
  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 30 : 10,
      decoration: BoxDecoration(
        // إذا كانت النقطة شغالة خليها أخضر، وإذا لا خليها رمادي غامق عشان تبين عالأبيض
        color: isActive ? Color(0xFF162D4A) : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// الشاشة الترحيبية الثالثة
class ThirdOnboarding extends StatefulWidget {
  const ThirdOnboarding({super.key});

  @override
  State<ThirdOnboarding> createState() => _ThirdOnboardingState();
}

class _ThirdOnboardingState extends State<ThirdOnboarding>
    with SingleTickerProviderStateMixin {
  //التعريفات
  //للنبض المستمر للزر
  late AnimationController _controller;
  //للمعان على علامة الصح
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. الصورة العلوية
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/images/onboarding3.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // 2. العنوان العريض وبعده علامة الصح ✅
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'دفع إلكتروني آمن',
                    style: TextStyle(
                      color: Color(0xFF000814),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8), // مسافة بسيطة بين النص والصح
                  // علامة الصح اللي بتلمع ✅
                  _buildShiningCheck(),
                ],
              ),
              const SizedBox(height: 15),

              // 3. الشرح (سلس وآمن)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'استمتع بتجربة دفع سريعة ومحمية بالكامل\nلضمان حجز مقعدك بسهولة عبر تطبيقنا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF000814),
                    fontSize: 19,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          // 4. نقاط التنقل
          Positioned(
            //بتحكم بارتفاع النقاط
            bottom: 70,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(false),
                const SizedBox(width: 8),
                _buildDot(false),
                const SizedBox(width: 8),
                _buildDot(true),
              ],
            ),
          ),

          // 5. الزر العريض والنابض
          Positioned(
            //بتحكم بارتفاع الزر تبع ابدأ الان
            bottom: 100,
            left: 50,
            right: 50,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Hero(
                tag: 'arrow_button',
                child: ElevatedButton(
                  onPressed: () async {
                    // . وقف النبض فوراً عشان تريح المعالج
                    _controller.stop();
                    // حفظ في الذاكرة أن المستخدم شاف الواجهات الترحيبية وخلاص
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool(
                      'isFirstTime',
                      false,
                    ); // <--- السطر السحري للحفظ
                    // الانتقال لصفحة التسجيل وحذف كل واجهات الترحيب من الذاكرة نهائياً
                    // الانتقال لصفحة التسجيل وحذف كل واجهات الترحيب من الذاكرة
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    //لون الزر ابدأ الان فقط من دون الكلمة الي بداخل ازر
                    backgroundColor: Color(0xFF162D4A),
                    //لون كلمة ابدأ الان
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  child: const Text(
                    ' بسم الله نبدأ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت علامة الصح اللامعة ✅
  Widget _buildShiningCheck() {
    return Stack(
      children: [
        const Text('✅', style: TextStyle(fontSize: 28)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      _controller.value - 0.2,
                      _controller.value,
                      _controller.value + 0.2,
                    ],
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ).createShader(rect);
                },
                child: const Text(
                  '✅',
                  style: TextStyle(fontSize: 28, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ويدجت النقاط
  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 30 : 10,
      decoration: BoxDecoration(
        color: isActive ? Color(0xFF162D4A) : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
//مشان الانيميشن

class RealisticPinAnimation extends StatefulWidget {
  const RealisticPinAnimation({super.key});

  @override
  State<RealisticPinAnimation> createState() => _RealisticPinAnimationState();
}

class _RealisticPinAnimationState extends State<RealisticPinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // حركة ارتداد مستمرة وسلسة للغاية
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // فيزياء تسارع وتباطؤ حقيقي عند الارتفاع والهبوط
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // حساب الارتفاع وتغير الظل بناءً على حركة الدبوس الحالية
        double pinYTranslation =
            _animation.value * -35; // يرتفع لأعلى بمقدار 35 بكسل
        double shadowScale =
            1.0 - (_animation.value * 0.4); // يصغر الظل عند الارتفاع
        double shadowOpacity =
            0.4 - (_animation.value * 0.25); // يبهت الظل عند الارتفاع

        return SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. الظل التفاعلي الذكي بالأسفل (يكبر ويصغر ويغمق ويبهت مع حركة الدبوس)
              Positioned(
                bottom: 10,
                child: Transform.scale(
                  scale: shadowScale,
                  child: Opacity(
                    opacity: shadowOpacity.clamp(0.0, 1.0),
                    child: Container(
                      width: 45,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(45, 10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. دبوس الموقع الفخم (تصميم هندسي حاد وأنيق باللون الذهبي الدافئ)
              Positioned(
                bottom: 20,
                child: Transform.translate(
                  offset: Offset(0, pinYTranslation),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // جسم الدبوس الخارجي المائل بزاوية 45 درجة لصنع المظهر الاحترافي
                      Transform.rotate(
                        angle: 0.785,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.redAccent,
                                Color(0xFFB71C1C),
                              ], // تدرج ذهبي فخم
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: const Color(0xFF1D273A),
                              width: 3,
                            ), // تحديد متناسق مع الخلفية
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(
                                0,
                              ), // رأس حاد يشير للأسفل وللظل
                            ),
                          ),
                        ),
                      ),
                      // الدائرة المفرغة البيضاء بالمنتصف لتعطي الطابع العصري
                      Positioned(
                        top: 10,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1D273A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
