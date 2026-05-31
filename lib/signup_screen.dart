import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضرورية للتحكم بالمدخلات

import 'api_service.dart'; // استدعاء
import 'custom_button.dart'; //مشان استدعي ملف الاهتزاز تبع الازرار عند الضغط عليهن ومشان متغير الحالة
import 'otp_account.dart'; //الانتقال الى صفحةإدخال رمز التحقق

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //مفتاح النموذج: ضروري لتفعيل عملية التحقق (Validation) عند الضغط على الزر
  //مفتاح النموذج تبع المتحكمات
  final _formKey = GlobalKey<FormState>();

  //   .تعريف المتحكمات في بداية كلاس الشاشة مشان الربط/////////*********
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  //////////////////////////////////////////////////////*********
  // متغيرات الحالة: للتحكم في إظهار/إخفاء كلمة السر وأيقونة العين
  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _showPassIcon = false;
  bool _showConfirmPassIcon = false;
  bool _isLoggingIn = false; // متغير لحالة التحميل

  @override
  void initState() {
    super.initState();
    // مستمع (Listener) لمراقبة حقل كلمة السر: تظهر العين فقط إذا بدأ المستخدم بالكتابة
    _passController.addListener(() {
      setState(() => _showPassIcon = _passController.text.isNotEmpty);
    });
    // مستمع لحقل تأكيد كلمة السر
    _confirmPassController.addListener(() {
      setState(
        () => _showConfirmPassIcon = _confirmPassController.text.isNotEmpty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
            false, // سطر مهم: بيحكي للفلاتر "لا تحط سهم يسار من عندك"
        actions: [
          // الـ actions بتبدأ من اليمين
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
              size: 20,
            ), // استخدمنا سهم iOS أرقى
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10), // مسافة بسيطة من حافة الشاشة اليمين
        ],
      ),
      // جسم الصفحة يحتوي على العناصر القابلة للتمرير (سكرول)
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Form(
            key: _formKey, // ربط النموذج بالمفتاح
            child: Column(
              children: [
                const SizedBox(height: 0),
                // قسم الشعار (Logo) بشكل دائري
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ابدأ رحلتك معنا',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  ' ...سجل الآن لتجربة سفر لا تُنسى ، واستعد لرحلتك ',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // --- قسم الحقول مع مسافات 30 ---

                // 1. الاسم الكامل (تحقق من الفراغ فقط)
                _buildField(
                  label: 'الاسم الكامل',
                  hint: 'ادخل اسمك الثلاثي',
                  icon: Icons.person,
                  controller: _nameController, //الجاسوس لهاد الحقل
                ),
                const SizedBox(height: 20),

                // 2. البريد الإلكتروني (المؤشر من اليسار + تحقق من الصيغة)
                _buildField(
                  label: 'البريد الالكتروني',
                  hint: 'أدخل بريدك الإلكتروني',
                  icon: Icons.email,
                  isEmail: true,
                  alignLeft: true, // كتابة من اليسار
                  controller: _emailController, //الجاسوس لهاد الحقل
                ),
                const SizedBox(height: 20),

                // 3. رقم الهاتف (تحقق من الفراغ)
                _buildField(
                  label: 'رقم الهاتف',
                  hint: 'أدخل رقم هاتفك',
                  icon: Icons.phone,
                  isPhone: true, // ضروري تفعلها هون
                  controller: _phoneController, //الجاسوس لهاد الحقل
                ),
                const SizedBox(height: 20),

                // 4. كلمة السر (المؤشر من اليسار + تحقق من الطول + عين ذكية)
                _buildPasswordField(
                  label: 'كلمة السر',
                  hint: 'أدخل كلمة سر قوية',
                  isObscure: _isObscure,
                  showIcon: _showPassIcon,
                  onToggle: () => setState(() => _isObscure = !_isObscure),
                  action: TextInputAction.next,
                  controller: _passController, //الجاسوس لهاد الحقل
                ),
                const SizedBox(height: 20),

                // 5. تأكيد كلمة السر (تحقق من التطابق مع الحقل الأول)
                _buildPasswordField(
                  label: 'تأكيد كلمة السر',
                  hint: '',

                  isObscure: _isConfirmObscure,
                  showIcon: _showConfirmPassIcon,
                  onToggle: () =>
                      setState(() => _isConfirmObscure = !_isConfirmObscure),
                  isConfirm: true,
                  action: TextInputAction
                      .done, // مشان يقلب زر التالي الي بلوحة المفاتيح الى تم في اخر حقل
                  controller: _confirmPassController, //الجاسوس لهاد الحقل
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // --- خاصية bottomNavigationBarلزر انشاء حساب جديد  ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(
          left: 25,
          right: 25,
          bottom: 40,
          top: 10,
        ),
        color: Colors.white,
        // استدعاء "القالب" اللي عملناه بملف custom_button
        child: MyMainButton(
          text: 'إنشاء حساب جديد',
          isLoading: _isLoggingIn, // نربط الحالة (isLoading) بالزر
          // داخل زر MyMainButton في صفحة SignUp
          onTap: () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isLoggingIn = true);

              // 1. استدعاء الساعي (ApiService)
              ApiService api = ApiService();
              var response = await api.registerUser(
                name: _nameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                password: _passController.text,
              );

              setState(() => _isLoggingIn = false);

              // 2. فحص النتيجة
              if (response.statusCode == 201) {
                //  نهاية التعديل لحفظ البروفايل فوراً
                // نجح التسجيل المبدئي -> ننتقل لصفحة الـ OTP ونأخذ الإيميل معنا
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtpAccount(
                        email: _emailController.text,
                      ), // مررنا الإيميل هون
                    ),
                  );
                }
              } else {
                // فشل (مثلاً الإيميل مكرر) -> اظهر رسالة الخطأ من السيرفر
                String errorMsg = response.data['message'] ?? "حدث خطأ ما";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMsg),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  // ويدجت بناء الحقول العادية (الاسم، الإيميل، الهاتف)
  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    bool isEmail = false,
    bool isPhone = false, // ضفنا هاي عشان نعرف إذا الحقل هو رقم هاتف
    bool alignLeft = false,
    ///////////**************
    required TextEditingController
    controller, //هاد السطر بخزن كلشي بدخلو المستخدم بالحقول بوخذها وبخزنها بالمتحكمات الي عرفتهن اول الكلاس تبع الشاشة
    //////////////**************
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          ////////////////////////****
          controller: controller, //مشان الربط تبع المتحكمات
          /////////*************
          // 1. تحديد نوع لوحة المفاتيح (أرقام فقط إذا كان حقل هاتف)
          keyboardType: isPhone
              ? TextInputType.number
              : (isEmail ? TextInputType.emailAddress : TextInputType.text),

          // 2. منع الحروف وتحديد الطول بـ 10 أرقام
          inputFormatters: isPhone
              ? [
                  FilteringTextInputFormatter
                      .digitsOnly, // بيسمح بس بالأرقام وبيمنع أي حرف أو رمز
                  LengthLimitingTextInputFormatter(
                    10,
                  ), // بيوقف الكتابة فوراً بعد الرقم العاشر
                ]
              : null,

          textDirection: alignLeft ? TextDirection.ltr : TextDirection.rtl,
          textAlign: alignLeft ? TextAlign.left : TextAlign.right,
          //---عشان الكيبورد يطلّع زر "التالي" وينقلني للحقل اللي بعده تلقائياً
          textInputAction: TextInputAction.next,

          validator: (value) {
            if (value == null || value.isEmpty) return 'يرجى ملء هذا الحقل';

            // 1. تحقق الاسم (جديد): يمنع الرموز والإيميلات في حقل الاسم
            // هاد الشرط بيتأكد إن الحقل لا هو هاتف ولا هو إيميل (يعني حقل الاسم)
            if (!isPhone && !isEmail) {
              // التعبير النمطي أدناه يسمح بالحروف العربية والإنجليزية والمسافات فقط
              if (!RegExp(r'^[\p{L} ]+$', unicode: true).hasMatch(value)) {
                return 'يرجى إدخال اسم صحيح (حروف فقط بدون رموز)';
              }
              if (value.length < 3) return 'الاسم قصير جداً';
            }

            // 2. تحقق الهاتف (مثل ما هو)
            if (isPhone) {
              if (!value.startsWith('09')) return 'يجب أن يبدأ الرقم بـ 09';
              if (value.length < 10)
                return 'رقم الهاتف ناقص يجب أن يكون 10 أرقام';
              return null;
            }

            // 3. تحقق الإيميل (مثل ما هو)
            if (isEmail) {
              if (!RegExp(r'^[a-zA-Z0-9.]+@gmail\.com$').hasMatch(value)) {
                return 'عذرا. بريدك الإلكتروني غير صحيح';
              }
            }

            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            //هون بقدر اتحكم بحجم النص الي داخل الحقل الي اني كاتبو
            hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
            hintText: hint,
            suffixIcon: Icon(icon, color: Colors.grey),
            //الحدود العادية///
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),

            ///

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
        ),
      ],
    );
  }

  // ويدجت بناء حقول كلمة السر (مع العين الذكية والمؤشر لليسار)
  Widget _buildPasswordField({
    required String label,
    /////////////**************
    required TextEditingController
    controller, //هاد السطر بخزن كلشي بدخلو المستخدم بالحقول بوخذها وبخزنها بالمتحكمات الي عرفتهن اول الكلاس تبع الشاشة
    ///////////////*************
    required bool isObscure,
    required String hint, // أضفنا هاد المتغير عشان نغير النص التوضيحي
    required bool showIcon,
    required VoidCallback onToggle,
    bool isConfirm = false, // لتمييز حقل التأكيد
    // .  (بياخد قيمة افتراضية "التالي" في الحقول في لوحة المفاتيح)
    TextInputAction action = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          //////////***************
          controller: controller, //مشان الربط تبع المتحكمات
          ///////////***********
          textAlign: TextAlign
              .left, // مؤشر كلمة السر دائماً من اليسار لأغراض أمنية وتنظيمية
          //
          // السطر هاد هو الأهم، مشان اتحكم بزر التالي او تم في لوحة المفاتيح
          textInputAction: action,
          //
          obscureText: isObscure,

          validator: (value) {
            if (value == null || value.isEmpty) return 'يرجى ملء هذا الحقل';
            if (value.length < 6) return 'يجب أن تكون 6 خانات على الأقل';
            // التحقق من تطابق كلمة السر في حقل التأكيد
            if (isConfirm && value != _passController.text)
              return 'كلمات السر غير متطابقة';
            return null;
          },
          decoration: InputDecoration(
            hintStyle: TextStyle(
              color: Colors
                  .grey, //هون بقدر اتحكم بحجم النص الي داخل الحقل الي اني كاتبو
              fontSize: 15,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            hintText: hint,

            // أيقونة العين تظهر فقط عند الكتابة (PrefixIcon لأن الحقل يساري)
            prefixIcon: showIcon
                ? IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onToggle,
                  )
                : null,
            suffixIcon: const Icon(Icons.lock, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            // الحدود في الحالة العادية (شفافة عشان نحافظ على تصميمك)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            // الحدود عند الضغط (شفافة أيضاً)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.transparent),
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose(); // ضيفه هون كمان ضروري
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
}
