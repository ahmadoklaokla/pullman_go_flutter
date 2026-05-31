import 'dart:async'; // مكتبة العداد

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للتحكم بالمدخلات (منع العربي)

import 'api_service.dart';
import 'custom_button.dart';
import 'reset_password_screen.dart';

class OTPScreen extends StatefulWidget {
  // 1.  هاد  عشان تستقبل الإيميل أو الرقم
  final String? emailOrPhone;

  // 2. ضيف this.emailOrPhone داخل الأقواس هون
  const OTPScreen({super.key, this.emailOrPhone});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  Timer? _timer;
  int _start = 30; // البداية 30 ثانية
  int _multiplier = 1; // معامل المضاعفة (3 أضعاف)
  bool _canResend = false;
  bool _isLoading = false;

  // متحكمات المربعات الأربعة
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  // مصفوفة للتحقق من التركيز (عشان نغير لون المربع اللي عم نكتب فيه)
  // وبتاكد اذا المربعات مو فاضيات قبل ما يبعثهن للسيرفر
  //_focusNodes: قائمة بتهتم بمكان الكيبورد (وين "الفوكس" حالياً)
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    startTimer(); // ابدأ العداد فوراً
  }

  // دالة العداد الذكي بمضاعفة 3 أضعاف
  void startTimer() {
    _timer?.cancel(); // إلغاء أي عداد نشط
    setState(() {
      _start = 30 * _multiplier; // تطبيق المعادلة: 30 * (1، 3، 9...)
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
          _multiplier *= 3;
        }); // مضاعفة المعامل للمرة القادمة
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // دالة فحص إذا تم إدخال 4 أرقام وتقوم بجمع الارقام الي دخلها المستخدم ليبعثها الى enteredCode  ليتحقق من طولها/////////////////

  String get fullCode => _controllers.map((e) => e.text).join();
  ///////////////********************

  @override
  Widget build(BuildContext context) {
    //////////////////*****************
    ////////////////*********************
    ////////////////////********************
    //هون اني غلفت ال Scaffold  ب PopScope
    return PopScope(
      canPop: false, //  بيحكي للموبايل "ممنوع ترجع لورا"
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // إظهار رسالة تنبيه للمستخدم

        //هذا هو "المسؤول" عن إظهار أي رسائل تنبيهية على الشاشة ScaffoldMessenger.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'عذراً، يجب إكمال عملية التحقق أولاً للرجوع',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.black87, // لون أسود شيك مع شفافية بسيطة
            behavior: SnackBarBehavior
                .floating, // هاد السطر بخلي الإشعار "طاير" مو ملزق تحت
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50), // انحناء الأطراف
            ),
            margin: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).size.height *
                  0.05, // رفعه لفوق بمقدار 10% من طول الشاشة
              right: 45,
              left: 45,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      //////////////////*******************
      //////////////////******************
      ///////////////////******************
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // لون خلفية هادئ واحترافي
        appBar: AppBar(
          backgroundColor: Colors.transparent, // هيدر شفاف
          elevation: 0,
          automaticallyImplyLeading:
              false, // هاد السطر بيخفي سهم الرجوع اللي فوق فوراً
          //هون بحط السهم اليدوي الخاص فيني
          actions:
              [], // فضّي الـ actions تماماً عشان يختفي السهم اللي حطيته يدويّاً
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // أيقونة حماية مودرن
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 50,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "التحقق من هويتك",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "لقد أرسلنا رمز التأكيد المكون من 4 أرقام\nإلى بريدك الإلكتروني المسجل لدينا",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 50),

              // صف المربعات بتصميم احترافي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) => _buildOtpBox(index)),
              ),

              const SizedBox(height: 40),

              // قسم إعادة الإرسال والعداد بتصميم أنيق
              _buildResendSection(),

              const SizedBox(height: 60),

              // زر التحقق النهائي بشرط الـ 4 أرقام
              MyMainButton(
                text: "تأكيد الرمز",
                isLoading: _isLoading,
                onTap: () async {
                  ////////////////////////////////////////************
                  // 1. تجميع الرمز من الـ 4 مربعات
                  String enteredCode =
                      fullCode; // اني معرف الـ fullCode فوق كـ getter

                  if (enteredCode.length < 4) {
                    // شرط المنع إذا لم تكتمل الخانات
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'الرجاء إدخال الرمز كاملاً (4 أرقام)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.05,
                          right: 45,
                          left: 45,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  ///////////////////////////*******************
                  setState(() => _isLoading = true);

                  // --- الربط مع الـ API الحقيقي (بدل المحاكاة) ---
                  ApiService api = ApiService();

                  // منبعث الإيميل/الهاتف (اللي استقبلناه بالـ Constructor) مع الرمز اللي دخله المستخدم
                  var response = await api.verifyResetOtp(
                    loginField: widget.emailOrPhone ?? "",
                    otpCode: enteredCode,
                  );

                  if (mounted) {
                    setState(() => _isLoading = false);

                    if (response.statusCode == 200) {
                      // إذا الرمز صح، بننقله لواجهة تعيين كلمة المرور الجديدة
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordScreen(
                            //   عم امرر الايميل او رقم الهاتف على صفحة اعادة التعيين
                            emailOrPhone: widget
                                .emailOrPhone, // منمرره عشان الصفحة الجاية تعرف لمين تغير الباسورد
                          ),
                        ),
                        (route) => false, // احذف كل الصفحات السابقة
                      );
                    } else {
                      // إذا الرمز خطأ، منظهر رسالة الخطأ اللي جاية من السيرفر بنفس تنسيقك الفخم
                      String errorMsg =
                          response.data['message'] ?? 'الرمز غير صحيح أو منتهي';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            errorMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.05,
                            right: 45,
                            left: 45,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت المربع الواحد بتصميم High-End
  Widget _buildOtpBox(int index) {
    return Container(
      width: 65,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? const Color(0xFF2E7D32)
              : Colors.transparent,
          width: 2,
        ), // تغيير اللون عند التركيز
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller:
            _controllers[index], //مسؤولة عن النص (شو انكتب؟ نمسح النص؟ نجيب النص؟) بدونه، ما بتقدر تعرف إن المستخدم كتب رقم "5".
        focusNode:
            _focusNodes[index], //مسؤولة عن المكان (وين الكيبورد واقف؟ المربع هاد منوّر ولا مطفي؟) بدونه، ما بتقدر تخلي الكيبورد "ينط" تلقائياً للمربع اللي بعده بس تخلص كتابة..
        onChanged: (value) {
          if (value.length == 1 && index < 3)
            _focusNodes[index + 1].requestFocus(); // الانتقال لليمين
          if (value.isEmpty && index > 0)
            _focusNodes[index - 1].requestFocus(); // الرجوع لليسار عند المسح
          setState(() {}); // لتحديث حالة الزر عند الكتابة
        },
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1), // رقم واحد فقط
          FilteringTextInputFormatter
              .digitsOnly, // **منع العربي وأي أحرف؛ أرقام إنجليزية فقط**
        ],
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  // ويدجت قسم إعادة الإرسال
  Widget _buildResendSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _canResend ? () => startTimer() : null,
              child: Text(
                "إعادة الإرسال",
                style: TextStyle(
                  color: _canResend ? const Color(0xFF2E7D32) : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Text(
              "لم يصلك الرمز؟",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // تنسيق العداد دقيقة:ثانية
        Text(
          "${(_start ~/ 60)}:${(_start % 60).toString().padLeft(2, '0')}",
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // 1. إيقاف العداد (Timer) عشان ما يضل شغال بالخلفية ويصرف بطارية بعد إغلاق الصفحة
    _timer?.cancel();

    // 2. حلقة تكرار تمر على كل "متحكم نص" (Controller) وتغلقه نهائياً
    for (var c in _controllers) {
      c.dispose(); // تنظيف ذاكرة الرام من النصوص المخزنة
    }

    // 3. حلقة تكرار تمر على كل "نقطة تركيز" (FocusNode) وتغلقها
    for (var f in _focusNodes) {
      f.dispose(); // إغلاق موارد التحكم بالكيبورد والتركيز
    }

    // 4. استدعاء الدالة الأصلية للنظام لإتمام عملية مسح الصفحة من الذاكرة
    super.dispose();
  }
}
