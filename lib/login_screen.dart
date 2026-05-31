import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //هي المكتبة مشان تمنع الكتابة بالعربي داخل حقل البريد الالكرتوني(FilteringTextInputFormatter)
//هي مكتبة لحفظ التوكن واسم المستخدم
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'custom_button.dart'; //مشان استدعي ملف الاهتزاز تبع الازرار عند الضغط عليهن
import 'forgot_password_screen.dart'; //الانتقال الى صفحة ادخال البريد الالكتروني بعد الضغط على كملة نسيت كلمة المرور
import 'hom.dart'; // استدعاء ملف الشاشة الرئيسية الجديد
//استدعاء ملف انشاء حساب جديد
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //مفتاح النموذج: ضروري لتفعيل عملية التحقق (Validation) عند الضغط على الزر
  //مفتاح النموذج تبع المتحكمات
  final _formKey = GlobalKey<FormState>();

  //   .تعريف المتحكمات في بداية كلاس الشاشة مشان الربط/////////*********
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  //////////////////////////////////////////////////////*********
  bool _isObscure = true;
  bool _isLoggingIn =
      false; //  (// هاد المتغير بحدد إذا الدائرة عم تفتل أو لا)متغير لحالة التحميل

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  const RepaintBoundary(child: ImageSection()),
                  Positioned(
                    //للانحناءات الي تحت الصورة
                    bottom: -1,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 130,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(90),
                          topRight: Radius.circular(90),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'مرحباً بك مجدداً',
                            style: TextStyle(
                              fontSize: 33,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'سجل الدخول لحجز رحلتك القادمة',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                //تقليص الشاشة
                padding: const EdgeInsets.symmetric(horizontal: 27),
                child: Column(
                  children: [
                    _buildEmailField(
                      label: 'رقم الهاتف أو البريد الإلكتروني',

                      hint: 'أدخل رقمك أو بريدك الإلكتروني',
                      icon: Icons.email,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'يرجى ملء هذا الحقل '
                          : null,
                      isEmail: true, // هون بنادي الحقل تبع الايميل

                      controller: _emailController, //الجاسوس لهاد الحقل
                      labelFontSize: 15,
                    ),
                    const SizedBox(height: 20),

                    // استبدل سطر 92 في كودك بهذا السطر بالضبط:
                    _buildPasswordField(
                      controller: _passController,
                      labelFontSize: 15,
                    ), // تم الربط مع المتحكم

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // الانتقال لصفحة ادخال البريد الالكتروني
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'نسيت كلمة السر؟',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ///***************************************************
                    //
                    // استدعاء حقيقي لل  APIs
                    ///****************************************************
                    /////
                    //
                    MyMainButton(
                      text: 'تسجيل الدخول',
                      isLoading: _isLoggingIn,
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoggingIn = true; // بدء التحميل
                          });

                          // 1. استدعاء الساعي (ApiService)
                          ApiService api = ApiService();

                          // 2. إرسال البيانات للسيرفر
                          var response = await api.loginUser(
                            loginField: _emailController.text,
                            password: _passController.text,
                          );

                          if (mounted) {
                            setState(() {
                              _isLoggingIn = false; // إيقاف التحميل
                            });

                            // 3. فحص رد السيرفر
                            //هي مدموجة مع حفظ بيانات المستخدم في ملفه الشخصي (الاسم والايميل والرقم )
                            if (response.statusCode == 200) {
                              // نجاح! (البيانات صحيحة)
                              //
                              //
                              //
                              // فك تشفير واستخراج البيانات القادمة من الـ API
                              var userData = response.data['user'];
                              // 1. استخراج التوكن من الرد
                              String token = response.data['token'];

                              // 2. حفظ التوكن وحالة الدخول في ذاكرة الموبايل
                              final SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'token',
                                token,
                              ); // تفعيل حالة تسجيل الدخول
                              await prefs.setBool('is_logged_in', true);

                              //هاد مشان يحفظ id المستخدم في ذاكرة الجهاز
                              await prefs.setInt(
                                'user_id',
                                userData['id'] ?? 0,
                              );
                              await prefs.setString(
                                'user_name',
                                userData['name'] ?? "لا يوجد اسم",
                              );
                              await prefs.setString(
                                'user_email',
                                userData['email'] ?? "لا يوجد بريد",
                              );
                              await prefs.setString(
                                'user_phone',
                                userData['phone'] ?? "لا يوجد رقم",
                              );
                              //
                              //
                              //

                              // الانتقال للصفحة الرئيسية
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PullmanMainScreen(),
                                ),
                              );

                              // لحد هون مشان حفظ بيانات المستخدم بالملف الشخصي
                            } else {
                              // فشل! (كلمة السر خطأ، الحساب غير مفعل، إلخ)
                              // استخراج رسالة الخطأ من السيرفر
                              String errorMsg =
                                  response.data['message'] ??
                                  "حدث خطأ في تسجيل الدخول";

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

                    //
                    //
                    //
                    const SizedBox(height: 30),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('أو'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'أنشاء حساب جديد',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text('ليس لديك حساب بالفعل؟'),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- حقل الإدخال: مؤشر يسار والـ Hint يمين ---
  Widget _buildEmailField({
    required String label,
    required String hint,
    required IconData icon,

    bool isEmail = false,
    double labelFontSize = 14, // قيمة افتراضية للحجم
    ///////////**************
    required TextEditingController
    controller, //هاد السطر بخزن كلشي بدخلو المستخدم بالحقول بوخذها وبخزنها بالمتحكمات الي عرفتهن اول الكلاس تبع الشاشة
    //////////////**************
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label, //هون التعديل على حجم البريد الالكتروني الي فوق الحقل تبعو
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],

            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,

                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: TextFormField(
            ////////////////////////****
            controller: controller, //مشان الربط تبع المتحكمات
            /////////*************
            // تحديد نوع الكيبورد للإيميل (عشان تظهر علامة @)
            // 1. تحديد نوع الكيبورد: خليه دائماً emailAddress لأنه بيشمل الأرقام والأحرف
            keyboardType: isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,

            // 2. تحديد المحاذاة والاتجاه (ذكاء اصطناعي بسيط):
            // إذا النص بيبدأ بـ "09" خليه يمين (لأنه رقم)، غير هيك خليه يسار (لأنه إيميل)
            textAlign: controller.text.startsWith('09')
                ? TextAlign.right
                : TextAlign.left,
            textDirection: controller.text.startsWith('09')
                ? TextDirection.rtl
                : TextDirection.ltr, // الاتجاه إنجليزي
            onChanged: (value) {
              setState(
                () {},
              ); // هاد السطر بخلي الـ textAlign والـ textDirection يتحدثوا مع كل حرف بتكتبه
            },
            textInputAction: TextInputAction
                .next, //---عشان الكيبورد يطلّع زر "التالي" وينقلني للحقل اللي بعده تلقائياً
            ///////////////*****************
            // --- منع العربي تماماً من الحقل ---
            inputFormatters: [
              FilteringTextInputFormatter.deny(
                RegExp(r'[أ-ي]'),
              ), // منع أي حرف عربي فوراً
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى ملء هذا الحقل';
              }

              // التحقق من صيغة البريد الالكرتوني
              final bool isEmail = RegExp(
                r'^[a-zA-Z0-9.]+@gmail\.com$',
              ).hasMatch(value);

              // التحقق إذا كان المدخل "رقم هاتف" (يبدأ بـ 09 وطوله 10 وأرقام فقط)
              final bool isPhone = RegExp(r'^09[0-9]{8}$').hasMatch(value);
              if (isEmail) {
                return null; // الإيميل صح
              } else if (isPhone) {
                return null; // الرقم صح (يبدأ بـ 09 وطوله 10)
              } else {
                // إذا لم يكن إيميل صحيح ولا رقم هاتف يبدأ بـ 09
                return 'أدخل إيميل صحيح أو رقم هاتف يبدأ بـ 09 (10 أرقام)';
              }
            },

            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              hintText: hint,
              //هون بقدر اتحكم بحجم النص الي داخل الحقل الي اني كاتبو
              hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
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
              errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
              // ----------------------------------------------
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- حقل كلمة السر
  Widget _buildPasswordField({
    double labelFontSize = 14,
    required TextEditingController controller,
  }) {
    // ضيف الكنترول هون
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'كلمة السر',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100], //هون بقدر اغمق الحقل
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03), // نفس الظل الخفيف
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.left, // كلمة السر تبدأ يسار
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction
                .done, // مشان يقلب زر التالي الي بلوحة المفاتيح الى تم في اخر حقل
            obscureText: _isObscure,
            ///////////////*****************
            // --- منع العربي تماماً من الحقل ---
            inputFormatters: [
              FilteringTextInputFormatter.deny(
                RegExp(r'[أ-ي]'),
              ), // منع أي حرف عربي فوراً
            ],
            validator: (value) => (value == null || value.length < 6)
                ? 'يرجى ملء هذا الحقل'
                : null,
            decoration: InputDecoration(
              hintText: 'أدخل كلمة السر',
              hintStyle: TextStyle(
                color: Colors
                    .grey, //هون بقدر اتحكم بحجم النص الي داخل الحقل الي اني كاتبو
                fontSize: 15,
              ),
              hintTextDirection:
                  TextDirection.rtl, // كلمة السر يمين قبل الكتابة
              suffixIcon: const Icon(Icons.lock, color: Colors.grey),
              prefixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
              border: InputBorder.none,

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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // هاد المكان الصح لأن المتحكمات معرفة داخل هاد الكلاس
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }
} // <--- هاد قوس إغلاق كلاس _LoginScreenState

class ImageSection extends StatelessWidget {
  const ImageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.44,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bus_Login_image.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
