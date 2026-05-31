import 'package:flutter/material.dart';

import 'api_service.dart';
import 'custom_button.dart'; // استدعاء الزر اللي فيه ميزة الاهتزاز والتحميل
import 'success_screen.dart'; // استدعاء صفحة الدخول عشان نرجع لها بعد النجاح

class ResetPasswordScreen extends StatefulWidget {
  // 1.  هاد  عشان تستقبل الإيميل أو الرقم
  final String? emailOrPhone;

  // 2. ضيف this.emailOrPhone داخل الأقواس هون
  const ResetPasswordScreen({super.key, this.emailOrPhone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // تعريف "الجواسيس" (المتحكمات) اللي بتمسك النص اللي بيكتبه المستخدم
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // مفتاح النموذج: ضروري عشان نشغل الـ Validator ونعرف إذا الحقول مليانة صح
  final _formKey = GlobalKey<FormState>();

  // متغيرات بوليانية (صح/خطأ) للتحكم بظهور أو إخفاء كلمة السر لكل حقل
  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool _isLoading = false; // متغير بيحدد إذا الزر عم "يفتل" (تحميل) ولا لاء

  @override
  Widget build(BuildContext context) {
    //////////////////*****************
    ////////////////*********************
    ////////////////////********************
    //  هون اني غلفت ال Scaffold  ب PopScope مشان الرجوع واخفاء السهم
    return PopScope(
      canPop: false, //  بيحكي للموبايل "ممنوع ترجع لورا"
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // إظهار رسالة تنبيه للمستخدم
        //هذا هو "المسؤول" عن إظهار أي رسائل تنبيهية على الشاشة ScaffoldMessenger.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              ' عذراً، عليك وضع كلمة سر جديدة اولاً للرجوع',
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
      //////////////////*****************
      ////////////////*********************
      ////////////////////********************
      child: Scaffold(
        backgroundColor: Colors.white, // خلفية الصفحة بيضاء سادة
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0, //الي من فوق اول الشاشة إلغاء الظل تحت الـ AppBar
          automaticallyImplyLeading:
              false, // إلغاء سهم الرجوع التلقائي (عشان نحط سهمنا الخاص)
          actions: [
            // سهم الرجوع جهة اليمين (Arrow Forward يستخدم للرجوع في الـ RTL)
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
          ), // مسافة من اليمين واليسار 25
          child: Form(
            key: _formKey, // ربط الفورم بالمفتاح اللي عرفناه فوق
            child: Column(
              children: [
                const SizedBox(height: 20),
                // الدائرة اللي فيها أيقونة الأمان (شكل جمالي)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF2E7D32,
                    ).withOpacity(0.1), // لون أخضر شفاف 10%
                    shape: BoxShape.circle, // شكل دائري
                  ),
                  child: const Icon(
                    Icons.security_update_good_rounded,
                    size: 80,
                    color: Color(0xFF2E7D32), // لون الأيقونة أخضر غامق
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "تعيين كلمة سر جديدة",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "يرجى إنشاء كلمة مرور قوية لحماية حسابك، يجب أن تتكون من 6 خانات على الأقل",
                  textAlign: TextAlign.center, // توسيط النص
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // نداء دالة بناء الحقل (الحقل الأول: كلمة السر الجديدة)
                _buildPasswordField(
                  label: 'كلمة السر الجديدة',
                  controller: _newPasswordController, //الجاسوس لهاد الحقل
                  hint: "أدخل كلمة السر الجديدة",
                  isObscure:
                      _isObscure1, // نمرر حالة الإخفاء الخاصة بالحقل الأول
                  onToggle: () => setState(
                    () => _isObscure1 = !_isObscure1,
                  ), // تم تصحيح اسم المتغير هنا
                  action: TextInputAction
                      .next, // عشان ينقلك للحقل اللي بعده بالكيبورد
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'يرجى ملء هذا الحقل';
                    if (value.length < 6)
                      return 'يجب أن تكون 6 خانات على الأقل'; // تعديل ليتوافق مع النص التوضيحي
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // نداء دالة بناء الحقل (الحقل الثاني: تأكيد كلمة السر)
                _buildPasswordField(
                  label: 'تأكيد كلمة السر',
                  controller: _confirmPasswordController, //الجاسوس لهاد الحقل
                  hint: "أعد كتابة كلمة السر",
                  isObscure:
                      _isObscure2, // نمرر حالة الإخفاء الخاصة بالحقل الثاني
                  onToggle: () => setState(
                    () => _isObscure2 = !_isObscure2,
                  ), // وظيفة كبسة العين
                  action: TextInputAction.done, // عشان يقفل الكيبورد بس تخلص
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'يرجى تأكيد كلمة السر';
                    // فحص التطابق مع الحقل الأول باستخدام الكنترولر الصحيح
                    if (value != _newPasswordController.text)
                      return "كلمات السر غير متطابقة";
                    return null;
                  },
                ),

                const SizedBox(height: 60),

                // زر التحديث المشترك
                MyMainButton(
                  text: "تحديث كلمة السر",
                  isLoading: _isLoading,
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);

                      // 1. استدعاء الساعي
                      ApiService api = ApiService();

                      // 2. إرسال الطلب (منستخدم widget.emailOrPhone اللي استقبلناه من الواجهة السابقة)
                      var response = await api.resetPassword(
                        loginField: widget.emailOrPhone ?? "",
                        newPassword: _newPasswordController.text,
                      );

                      if (mounted) {
                        setState(() => _isLoading = false);

                        if (response.statusCode == 200) {
                          // نجاح! بنوديه لصفحة النجاح SuccessScreen
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SuccessScreen(),
                            ),
                            (route) => false,
                          );
                        } else {
                          // فشل (مثلاً الحساب انحذف فجأة أو مشكلة سيرفر)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                response.data['message'] ?? 'حدث خطأ ما',
                              ),
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
      ),
    );
  }

  // دالة ذكية بتبني الحقول عشان ما نكرر الكود مرتين
  Widget _buildPasswordField({
    required String label,
    required String hint,
    ///////////**************
    required TextEditingController
    controller, //هاد السطر بخزن كلشي بدخلو المستخدم بالحقول بوخذها وبخزنها بالمتحكمات الي عرفتهن اول الكلاس تبع الشاشة
    //////////////**************
    required bool isObscure,
    required VoidCallback onToggle,
    required TextInputAction action, // أضفنا هاد السطر عشان نحدد حركة الكيبورد
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.end, // العنوان يكون عاليمين فوق الحقل
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100], // لون رمادي فاتح للخلفية
            borderRadius: BorderRadius.circular(15), // حواف دائرية 15
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03), // ظل خفيف جداً (3%)
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller, // ربط الحقل بالجاسوس (المتحكم)
            textAlign:
                TextAlign.left, // الكتابة تبدأ من اليسار (للكيبورد الإنجليزي)
            textDirection: TextDirection.ltr, // اتجاه الحقل من اليسار لليمين
            obscureText: isObscure, // إخفاء النص (النجوم) حسب الحالة
            validator: validator, // شروط التحقق
            textInputAction: action, // تحديد زر "التالي" أو "تم" في الكيبورد
            decoration: InputDecoration(
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
              hintText: hint, // النص الباهت
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ), // تنسيق النص الباهت
              hintTextDirection:
                  TextDirection.rtl, // النص الباهت يظهر جهة اليمين قبل الكتابة
              suffixIcon: const Icon(
                Icons.lock,
                color: Colors.grey,
              ), // قفل جهة اليمين
              prefixIcon: IconButton(
                // أيقونة العين جهة اليسار للتبديل بين إظهار وإخفاء النص
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: onToggle, // تشغيل الوظيفة اللي بتبدل الحالة
              ),
              border: InputBorder
                  .none, // إخفاء الحدود الأصلية لأننا مستخدمين Container
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ), // مسافات داخلية للنص
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // تنظيف الذاكرة: لازم نكب المتغيرات لما نطلع من الصفحة عشان الجهاز ما يعلق
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
