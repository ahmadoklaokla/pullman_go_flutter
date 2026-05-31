import 'package:dio/dio.dart'; // ستحتاجين لاستيراد مكتبة Dio للاتصال بالباك أند
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final int totalAmount;
  final List<Map<String, dynamic>> passengerList;
  final int tripId; // مضاف حديثاً لربط الرحلة
  final int userId; // مضاف حديثاً لمعرفة المستخدم
  final String travelDate; // مضاف حديثاً لتحديد تاريخ السفر
  //عم امرر التوكن
  final String token;

  const PaymentGatewayScreen({
    super.key,
    required this.totalAmount,
    required this.passengerList,
    required this.tripId,
    required this.userId,
    required this.travelDate,
    required this.token,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  // 🎨 الألوان الموحدة والفخمة للتطبيق كـ static const حمايةً لبيئة الويب
  static const Color primaryNavy = Color(0xFF050E1A); // الكحلي الغامق الفخم
  static const Color accentIceBlue = Color(
    0xFF162D4A,
  ); // لغة الأزرار والتفاصيل النشطة
  static const Color backgroundColor = Color(
    0xFFF4F6F9,
  ); // الخلفية المريحة الموحدة

  int _currentStep = 1;
  String _selectedMethod = '';

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isProcessing = false;

  final Dio _dio = Dio(); // تعريف كائن مكتبة الـ Dio

  String get _formattedAmount {
    return widget.totalAmount.toString().replaceAllMatches(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      ',',
    );
  }

  // دالة إرسال الطلب الفعلي لقاعدة البيانات عبر الباك أند المحصنة والذكية تماماً
  //ما بتشتغل ولا بترسل البيانات للباك آند إلا جوا مرحلة الدفع
  Future<void> _sendBookingToBackend() async {
    setState(() => _isProcessing = true);

    // تجهيز مصفوفة الركاب لتطابق شكل الجداول المكتشفة بالـ phpMyAdmin والـ Controller الجديد
    List<Map<String, dynamic>> formattedPassengers = widget.passengerList.map((
      passenger,
    ) {
      return {
        'seat_number': passenger['seat_number']
            .toString(), // تم المزامنة مع مفاتيح الشاشة السابقة لضمان صحة البيانات
        'passenger_name': passenger['passenger_name'].toString(),
      };
    }).toList();

    // معالجة وتحويل التاريخ من الصيغة العادية (25/5/2026) إلى الصيغة القياسية (2026-05-25) لحل مشكلة السيرفر نهائياً
    String synchronizedDate = widget.travelDate.toString();
    try {
      if (synchronizedDate.contains('/')) {
        List<String> dateParts = synchronizedDate.split('/');
        if (dateParts.length == 3) {
          String day = dateParts[0].padLeft(2, '0');
          String month = dateParts[1].padLeft(2, '0');
          String year = dateParts[2];
          synchronizedDate =
              "$year-$month-$day"; // إعادة التشكيل القياسي المتوافق مع قواعد البيانات
        }
      }
    } catch (dateError) {
      // الحفاظ على القيمة الأصلية في حال حدوث أي استثناء غير متوقع أثناء المعالجة
      synchronizedDate = widget.travelDate.toString();
    }

    // بناء وتجميع الـ Map بالكامل باسم requestData لحل مشكلة الخط الأحمر المتعرج 👍
    Map<String, dynamic> requestData = {
      'user_id': widget.userId,
      'trip_id': widget.tripId,
      'seats_count': widget.passengerList.length,
      'travel_date':
          synchronizedDate, // تم التمرير هنا بالصيغة السليمة والمطابقة 100%
      'total_price': widget.totalAmount,
      'payment_method':
          _selectedMethod, // أرسل الكود مباشرة (sham, syriatel, mtn) ليتوافق مع اللارافيل ويجتاز الـ Validation
      'notes': '',
      'passengers': formattedPassengers,
    };

    try {
      //ارسال الطلب عبر عنوان ال api الموجود في ملف api_service.dart
      final response = await _dio.post(
        '${ApiService.baseUrl}/store-booking',
        data: requestData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${widget.token}', // 👈 فك التعليق عن هذا السطر ومرر الـ token للشاشة
          },
        ),
      );

      setState(() => _isProcessing = true); // تعديل بسيط لضمان التزامن المريح

      if (response.statusCode == 201 && response.data['status'] == true) {
        // إذا نجح الحفظ بالباك أند، أظهري دالة النجاح التي قمتِ ببنائها
        _showSuccessStageDialog(
          response.data['data']['reference_number'] ?? 'تلقائي',
        );
      } else {
        _showErrorSnackBar(
          "فشل تأكيد الحجز: ${response.data['message']?.toString() ?? 'بيانات غير مطابقة'}",
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (e is DioException && e.response != null) {
        // 👈 هذا السطر سيطبع لك الخطأ القادم من داتابيز اللارافيل حرفياً في الكونسول أو الرسالة
        _showErrorSnackBar("خطأ السيرفر: ${e.response?.data}");
      } else {
        _showErrorSnackBar("حدث خطأ في الاتصال: $e");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(
          seconds: 7,
        ), // وقت كافٍ لقراءة الحقل المسبب للرفض
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: primaryNavy,
              size: 18,
            ),
            onPressed: () {
              if (_currentStep == 2) {
                setState(() {
                  _currentStep = 1;
                  _isOtpSent = false;
                  _otpController.clear();
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _currentStep == 1
                ? "بوابة الدفع الإلكتروني"
                : "تأكيد الحساب المالي",
            style: const TextStyle(
              color: primaryNavy,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        body: _isProcessing
            ? const Center(
                child: CircularProgressIndicator(color: accentIceBlue),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    _buildHeaderSummary(),
                    const SizedBox(height: 30),
                    if (_currentStep == 1) _buildStageOneSelection(),
                    if (_currentStep == 2) _buildStageTwoForm(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: primaryNavy.withOpacity(0.02), blurRadius: 10),
        ],
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Column(
        children: [
          Text(
            "إجمالي قيمة حجز الرحلة",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formattedAmount,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                "ل.س",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: accentIceBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageOneSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "اختر طريقة الدفع المفضلة لديك:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: primaryNavy,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodCard(
          'sham',
          "شام كاش الإلكترونية",
          Icons.account_balance_wallet_rounded,
        ),
        _buildPaymentMethodCard(
          'syriatel',
          "سيريتل كاش (Syriatel Cash)",
          Icons.phone_android_rounded,
        ),
        _buildPaymentMethodCard(
          'mtn',
          "كاش موبايل (MTN Cash)",
          Icons.phonelink_setup_rounded,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedMethod.isNotEmpty
                ? () => setState(() => _currentStep = 2)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentIceBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _selectedMethod.isNotEmpty ? 2 : 0,
            ),
            child: const Text(
              "متابعة الدفع بالطريقة المختارة",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String id, String title, IconData icon) {
    bool isSelected = _selectedMethod == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? accentIceBlue : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: primaryNavy.withOpacity(0.01), blurRadius: 8),
        ],
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedMethod = id),
        leading: Icon(
          icon,
          color: isSelected ? accentIceBlue : primaryNavy.withOpacity(0.6),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: primaryNavy,
          ),
        ),
        trailing: Radio<String>(
          value: id,
          groupValue: _selectedMethod,
          activeColor: accentIceBlue,
          onChanged: (val) => setState(() => _selectedMethod = val!),
        ),
      ),
    );
  }

  Widget _buildStageTwoForm() {
    String methodNameStr = _selectedMethod == 'sham'
        ? "شام كاش"
        : _selectedMethod == 'syriatel'
        ? "سيريتل كاش"
        : "كاش موبايل";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: accentIceBlue,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              "حساب الدفع عبر: $methodNameStr",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: primaryNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!_isOtpSent) ...[
          Text(
            "أدخل رقم الهاتف المرتبط بمحفظتك:",
            style: TextStyle(fontSize: 13, color: primaryNavy.withOpacity(0.8)),
          ),
          const SizedBox(height: 10),
          _buildPhoneField(),
          const SizedBox(height: 35),
          _buildFormButton(
            label: "طلب رمز التحقق المرئي",
            icon: Icons.send_rounded,
            onPressed: _phoneController.text.length == 9
                ? _simulateOtpSending
                : null,
          ),
        ],
        if (_isOtpSent) ...[
          Text(
            "أدخل رمز التحقق (OTP) السري المستلم برسالة:",
            style: TextStyle(fontSize: 13, color: primaryNavy.withOpacity(0.8)),
          ),
          const SizedBox(height: 10),
          _buildOtpField(),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _isOtpSent = false),
              child: const Text(
                "تغيير رقم الهاتف",
                style: TextStyle(
                  color: accentIceBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          _buildFormButton(
            label: "تأكيد وإتمام المعاملة بأمان",
            icon: Icons.verified_user_rounded,
            onPressed: _otpController.text.length == 4
                ? _sendBookingToBackend
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: primaryNavy.withOpacity(0.01), blurRadius: 5),
        ],
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _phoneController,
                onChanged: (val) => setState(() {}),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                  FilteringTextInputFormatter.deny(RegExp(r'^0')),
                ],
                style: const TextStyle(
                  fontSize: 16,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "9xxxxxxxxx",
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "+963",
              style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: TextField(
        controller: _otpController,
        onChanged: (val) => setState(() {}),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        style: const TextStyle(
          fontSize: 22,
          letterSpacing: 12.0,
          fontWeight: FontWeight.bold,
          color: primaryNavy,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "••••",
          hintStyle: TextStyle(color: Colors.grey.shade300),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFormButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentIceBlue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: onPressed != null ? 2 : 0,
        ),
      ),
    );
  }

  void _simulateOtpSending() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isOtpSent = true;
        });
      }
    });
  }

  void _showSuccessStageDialog(String referenceNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentIceBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: accentIceBlue,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "تمت العملية بنجاح!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "تم سداد مبلغ $_formattedAmount ل.س بنجاح وتأكيد حجز مقاعدك في الحافلة.\nرقم الحجز المرجعي: $referenceNumber\nرحلة سعيدة!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "الانتقال إلى الرئيسية",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

extension StringExtension on String {
  String replaceAllMatches(RegExp regex, String replacement) {
    return regex
        .allMatches(this)
        .fold(
          this,
          (String result, Match match) =>
              result.replaceFirst(match.pattern, replacement),
        );
  }
}
