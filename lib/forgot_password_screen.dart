import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //هي المكتبة مشان تمنع الكتابة بالعربي داخل حقل البريد الالكرتوني(FilteringTextInputFormatter)

import 'api_service.dart';
import 'custom_button.dart'; //  ملف الزر المشترك مشان الاهتزاز عند الضغط وايقونة التحميل داخل الزر
import 'otp_screen.dart'; // ملف الـ OTP تبع رمز التحقق

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 1. تعريف المتحكم والمفتاح
  final TextEditingController _emailController = TextEditingController();
  //الـ Validator: المتحكمات لحالها ما بتكفي، لازم تربطها بـ Form و GlobalKey<FormState>() عشان تتأكد إن الحقول مو فاضية قبل ما السيرفر يرفض الطلب
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // لميزة أيقونة البحث/التحميل في الزر
  bool isEmail = false; //عرفت الايميل مشان الشرط للصيغة تبعيت الايميل

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 2. السهم من جهة اليمين (للتطبيقات العربية)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // إلغاء السهم التلقائي
        actions: [
          IconButton(
            // سهم الرجوع جهة اليمين (للعربي)
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Form(
          key: _formKey, // ربط الفورم بالمفتاح(مشان الربط)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // 3. أيقونة دائرية فخمة تعبر عن استعادة البيانات
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 60,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "استعادة كلمة السر",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                " أدخل بريدك الإلكتروني المرتبط بحسابك وسنرسل لك رمز التحقق المكون من 4 أرقام لإعادة تعيين كلمة السِر",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),

              // --- إضافة العنوان فوق الحقل مباشرة جهة اليمين ---
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 5, bottom: 8),
                  child: Text(
                    "رقم الهاتف أو البريد الإلكتروني",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              // 4. حقل الإدخال بتصميم عصري (Shadow خفيف)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                //هاد الابن child
                child: TextFormField(
                  controller:
                      _emailController, //الجاسوس تبع حقل البريد الالكتروني
                  // 1. تحديد نوع الكيبورد: خليه دائماً emailAddress لأنه بيشمل الأرقام والأحرف
                  keyboardType: isEmail
                      ? TextInputType.emailAddress
                      : TextInputType.text,

                  // 2. تحديد المحاذاة والاتجاه (ذكاء اصطناعي بسيط):
                  // إذا النص بيبدأ بـ "09" خليه يمين (لأنه رقم)، غير هيك خليه يسار (لأنه إيميل)
                  textAlign: _emailController.text.startsWith('09')
                      ? TextAlign.right
                      : TextAlign.left,
                  textDirection: _emailController.text.startsWith('09')
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  onChanged: (value) {
                    setState(
                      () {},
                    ); // هاد السطر بخلي الـ textAlign والـ textDirection يتحدثوا مع كل حرف بتكتبه
                  },
                  // --- منع العربي تماماً من الحقل ---
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                      RegExp(r'[أ-ي]'),
                    ), // منع أي حرف عربي فوراً
                  ],
                  /////////////////********************
                  decoration: InputDecoration(
                    hintText:
                        "أدخل رقمك أو بريدك الإلكتروني", // النص اللي بدك إياه باهت
                    // --- السر الأول: الشفافية المطلوبة ---
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 15),

                    // --- السر الثاني: الاتجاه ---
                    alignLabelWithHint: true,

                    // الأيقونة جهة اليمين
                    suffixIcon: Icon(
                      Icons.email_rounded,
                      color: Colors.grey[400], //درجة التباين تبعيت الايقونة
                    ),

                    filled:
                        true, //"يا فلاتر، أنا بدي أعبي خلفية الحقل بلون معين
                    fillColor:
                        Colors.grey[100], // لون رمادي فاتح جداً مثل الصورة

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),

                    // --- الحدود عند حدوث خطأ (تصير أحمر) ---
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ), // حدود حمراء
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ), // حدود حمراء أعرض عند الضغط
                    ),
                    //لون رسالة التنبيه
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى ملء هذا الحقل';
                    }

                    // التحقق من صيغة البريد الالكرتوني
                    final bool isEmail = RegExp(
                      r'^[a-zA-Z0-9.]+@gmail\.com$',
                    ).hasMatch(value);

                    // التحقق إذا كان المدخل "رقم هاتف" (يبدأ بـ 09 وطوله 10 وأرقام فقط)
                    final bool isPhone = RegExp(
                      r'^09[0-9]{8}$',
                    ).hasMatch(value);
                    if (isEmail) {
                      return null; // الإيميل صح
                    } else if (isPhone) {
                      return null; // الرقم صح (يبدأ بـ 09 وطوله 10)
                    } else {
                      // إذا لم يكن إيميل صحيح ولا رقم هاتف يبدأ بـ 09
                      return 'أدخل إيميل صحيح أو رقم هاتف يبدأ بـ 09 (10 أرقام)';
                    }
                  },
                ),
              ),
              const SizedBox(height: 50),

              // 5. الزر الاحترافي (اهتزاز + تحميل)
              // 5. الزر الاحترافي (اهتزاز + تحميل)
              MyMainButton(
                text: "إرسال رمز التحقق",
                isLoading: _isLoading,
                onTap: () async {
                  // المبدأ: انتهاء الاهتزاز أولاً للسلاسة
                  await Future.delayed(const Duration(milliseconds: 250));

                  //للتحقق من صحة المدخلات قبل الإرسال
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true; // تظهر أيقونة البحث/التحميل
                    });

                    // 1. مننادي الساعي تبعنا (ApiService)
                    ApiService api = ApiService();

                    // 2. منبعث الإيميل أو الرقم للسيرفر
                    var response = await api.requestPasswordReset(
                      loginField: _emailController.text,
                    );

                    if (mounted) {
                      setState(() {
                        _isLoading =
                            false; // نوقف أيقونة التحميل سواء نجح أو فشل
                      });

                      // 3. فحص رد السيرفر
                      if (response.statusCode == 200) {
                        // السيرفر لقى الحساب وبعث الرمز بنجاح

                        // رسالة خضراء حلوة للمستخدم
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response.data['message'],
                              textAlign: TextAlign.center,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // الانتقال للواجهة (OTP)
                        // ملاحظة هامة: لازم نبعث الإيميل/الرقم لشاشة الـ OTP عشان تعرف لمين تفحص الرمز!
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OTPScreen(
                              emailOrPhone: _emailController
                                  .text, //  نمرر القيمة للصفحة الجاية
                            ),
                          ),
                        );
                      } else {
                        // فشل (الحساب مو موجود، أو في مشكلة)
                        String errorMsg =
                            response.data['message'] ??
                            "حدث خطأ أثناء إرسال الرمز";

                        // رسالة حمراء بالخطأ
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMsg,
                              textAlign: TextAlign.center,
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  //مشان يمسح الحقول بعد الانتهاء من هذه الشاشة مما يقلل الضغط على حجم الرامات والذاكرة في الجهاز
  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }
}
