import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart'; // استدعاء ملف الساعي للاتصال باللارافيل والداتابيز
import 'login_screen.dart'; // استدعاء صفحة تسجيل الدخول ليعود إليها المسافر

class ProfileScreen extends StatefulWidget {
  final Function(String)? onNameUpdated; //  هاد السطر الجديد

  //  وهون ضفت الدالة جوا الكونستراكتور
  const ProfileScreen({super.key, this.onNameUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryGreen = const Color(0xFF162D4A);
  //
  //
  //**************
  //**************
  Uint8List? _imageBytes; // متغير لحفظ الصورة كبايتات
  final ImagePicker _picker = ImagePicker(); // كائن التقاط الصورة
  String? _imageUrl;
  //
  //
  //**************
  //**************

  bool isEditingName = false;
  bool isEditingPhone = false;
  //مشان زر الحفظ تبع الصورة بالبروفايل الشخصي
  bool isImageChanged = false;
  bool isLoading = true; // لعرض دائرة التحميل لحين قراءة الذاكرة

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    // جلب البيانات فور فتح الشاشة
    _loadProfileData();
  }

  // دالة قراءة البيانات المخزنة من الـ LoginScreen
  Future<void> _loadProfileData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('user_name') ?? "لا يوجد اسم";
      emailController.text = prefs.getString('user_email') ?? "لا يوجد بريد";
      phoneController.text = prefs.getString('user_phone') ?? "لا يوجد رقم";
      //عشان الصورة تبين اول ما افتح الشاشة او لما اعدلها
      _imageUrl = prefs.getString('user_image');
      isLoading = false;
    });
  }

  //دالة فتح المعرض والتقاط الصورة
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        isImageChanged = true; //مشان يظهر زر الحفظ تحت للصورة هي
      });
    }
  }

  // دالة إظهار صندوق تأكيد تسجيل الخروج وتفريغ التوكن والبيانات بأمان
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  "تسجيل الخروج",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              "هل أنت متأكد أنك تريد الخروج والعودة لصفحة تسجيل الدخول؟",
            ),
            actions: [
              TextButton(
                child: const Text(
                  "إلغاء",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text(
                  "خروج",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () async {
                  // تفريغ بيانات الجلسة المخزنة في جهاز المسافر لأمان أعلى
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // الدالة المحدثة للاتصال باللارافيل وحفظ التعديلات في قاعدة البيانات
  Future<void> saveEditing() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token'); // جلب التوكن لإرساله للسيرفر

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "عذراً، التوكن غير موجود. أعد تسجيل الدخول",

              textAlign: TextAlign.center,
            ),

            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // إظهار مؤشر التحميل أثناء الاتصال بالسيرفر
      setState(() {
        isLoading = true;
      });

      // 1. استدعاء الساعي وإرسال البيانات الجديدة للسيرفر
      ApiService api = ApiService();
      var response = await api.updateProfile(
        name: nameController.text,
        phone: phoneController.text,
        token: token,
        imageBytes: isImageChanged
            ? _imageBytes
            : null, //  3. بعثت الصورة للساعي
      );

      setState(() {
        isLoading = false;
      });

      // 2. فحص رد السيرفر
      if (response.statusCode == 200) {
        // إذا تم الحفظ بنجاح في الداتابيز، نقوم بتحديث الذاكرة المحلية للجهاز
        await prefs.setString('user_name', nameController.text);
        await prefs.setString('user_phone', phoneController.text);
        // هون بيحفظ الرابط تبع الصورة الي رجه من اللارافيل
        await prefs.setString(
          'user_image',
          response.data['user']['passenger_image'] ?? "",
        );

        setState(() {
          isEditingName = false;
          isEditingPhone = false;
          isImageChanged = false; //  4. رجعناها false بعد ما انحفظت بنجاح
          _imageUrl = response.data['user']['passenger_image'];
          _imageBytes = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "تم حفظ التغييرات في قاعدة البيانات بنجاح",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
        //  بيبعث الاسم الجديد للشاشة الرئيسية فوراً
        if (widget.onNameUpdated != null) {
          widget.onNameUpdated!(nameController.text);
        }
      } else {
        // في حال حدوث خطأ من السيرفر (مثل رقم الهاتف مستخدم من قبل مسافر آخر)
        String errorMsg =
            response.data['message'] ?? "فشل تحديث البيانات في السيرفر";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, textAlign: TextAlign.center),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF162D4A)),
      );
    }

    // شرط ذكي: يظهر الزر فقط إذا كان أحد الحقلين (الاسم أو الهاتف او الصورة) قيد التعديل حالياً
    bool shouldShowButton = isEditingName || isEditingPhone || isImageChanged;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage, // عند الضغط يفتح المعرض فوراً
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? NetworkImage(
                              _imageUrl!.startsWith('http')
                                  ? _imageUrl!
                                  : "${ApiService.baseAssetUrl}/$_imageUrl",
                            ) // اقرأ من الرابط الثاني بالapi لانو مخصص للصور من storageا
                          : null,
                      child:
                          (_imageBytes == null &&
                              (_imageUrl == null || _imageUrl!.isEmpty))
                          ? Icon(Icons.person, size: 70, color: primaryGreen)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // حقل الاسم
            _buildCustomField(
              label: "الاسم الكامل",
              controller: nameController,
              icon: Icons.person_outline,
              isEditable: true,
              isCurrentlyEditing: isEditingName,
              focusNode: _nameFocusNode,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'يرجى ملء حقل الاسم'
                  : null,
              onEditPressed: () {
                setState(() {
                  isEditingName = !isEditingName;
                });
                if (isEditingName) {
                  Future.delayed(
                    Duration.zero,
                    () => _nameFocusNode.requestFocus(),
                  );
                }
              },
            ),
            const SizedBox(height: 15),

            // حقل الإيميل (مغلق ومحمي تماماً)
            _buildCustomField(
              label: "البريد الإلكتروني",
              controller: emailController,
              icon: Icons.email_outlined,
              isEditable: false,
              isCurrentlyEditing: false,
            ),
            const SizedBox(height: 15),

            // حقل الهاتف
            _buildCustomField(
              label: "رقم الهاتف",
              controller: phoneController,
              icon: Icons.phone_android_outlined,
              isEditable: true,
              isCurrentlyEditing: isEditingPhone,
              focusNode: _phoneFocusNode,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'يرجى ملء حقل رقم الهاتف';
                if (!RegExp(r'^09[0-9]{8}$').hasMatch(value))
                  return 'أدخل رقم هاتف صحيح يبدأ بـ 09 وعشرة أرقام';
                return null;
              },
              onEditPressed: () {
                setState(() {
                  isEditingPhone = !isEditingPhone;
                });
                if (isEditingPhone) {
                  Future.delayed(
                    Duration.zero,
                    () => _phoneFocusNode.requestFocus(),
                  );
                }
              },
            ),

            const SizedBox(height: 30),

            // زر حفظ التغييرات (يظهر ديناميكياً عند تعديل أي حقل)
            if (shouldShowButton) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saveEditing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "حفظ التغييرات",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ), // مسافة تفصل الزرين في حال ظهور زر الحفظ
            ],

            // 🛑 زر تسجيل الخروج المنسق (ثابت في أسفل القائمة دائماً)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                    label: const Text(
                      "تسجيل الخروج",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: Colors.red.withOpacity(0.4),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.red.withOpacity(0.02),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditable,
    required bool isCurrentlyEditing,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    VoidCallback? onEditPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: isEditable ? !isCurrentlyEditing : true,
          textAlign: TextAlign.right,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: !isEditable
                ? Colors.grey[200]
                : (isCurrentlyEditing ? Colors.white : Colors.grey[50]),
            prefixIcon: Icon(icon, color: primaryGreen),
            suffixIcon: isEditable
                ? IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: isCurrentlyEditing ? primaryGreen : Colors.grey,
                      size: 20,
                    ),
                    onPressed: onEditPressed,
                  )
                : null,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isCurrentlyEditing ? primaryGreen : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryGreen, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }
}
