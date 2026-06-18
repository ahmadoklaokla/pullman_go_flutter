import 'dart:typed_data'; // مشان هي Uint8List

import 'package:dio/dio.dart';

//هاد الكلاس هو اللي رح يحكي مع اللارافيل بالنيابة عن أغلب الصفحات الصفحات
//مكتبة Dio: ليش Dio مش http العادية؟ لأن Dio "وحش" بالمميزات، بتدعم الـ Interceptors، والـ BaseOptions، وبتفهم JSON تلقائياً.
//**************************
//************************
class ApiService {
  // ملاحظة: إذا بتجرب على محاكي أندرويد (Emulator) استخدم 10.0.2.2 بدل localhost
  // إذا بتجرب على جهاز حقيقي، حط IP جهازك الكمبيوتر
  //عنوان ال  APIs
  static const String baseUrl = "http://10.21.159.109:8000/api";
  //هاد رابط ثاني لعرض الصور من الSTORAGE
  //لان اللارافيل مابتقرأ صور ومابتعرضها بالمسار الي فيو api
  static const String baseAssetUrl = "http://10.21.159.109:8000";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  //
  //
  //
  // 1. دالة التسجيل

  //هون ببعث بيانات التسجيل للرابط/register
  Future<Response> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      return await _dio.post(
        "/register",
        data: {
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
        },
      );
      // مشان اذا النت انقطع او ايميل مكرر نعرضلو رسالة من السيرفر
    } on DioException catch (e) {
      return e.response!; // رجع الرد حتى لو فيه خطأ (عشان نعرض رسالة السيرفر)
    }
  }
  //
  //
  //
  // 2. دالة التحقق من الرمز

  //بتبعت "باكيت" فيه الإيميل والرمز لعنوان /verify-otp
  Future<Response> verifyOtp({
    //هون بترجع الايميل والرمز للسيرفر على ملف الكونترولر بدالة التحقق من الرمز على هاد الكود
    // 2. البحث عن المستخدم اللي عنده هاد الإيميل وهاد الرمز تحديداً
    // $user = User::where('email', $request->email)
    //    ->where('otp_code', $request->otp_code)
    //    ->first();
    required String email,
    required String code,
  }) async {
    try {
      return await _dio.post(
        "/verify-otp",
        data: {"email": email, "otp_code": code},
      );
    } on DioException catch (e) {
      return e.response!;
    }
  }

  //  دالة ارسال بيانات تسجيل الدخول كمتغيرات للرابط "/login",
  //
  // 3. دالة تسجيل الدخول (Login)
  Future<Response> loginUser({
    required String loginField, // يمكن أن يكون إيميل أو رقم هاتف
    required String password,
  }) async {
    try {
      return await _dio.post(
        "/login", //هاد رابط تسجيل الدخول بالسيرفر
        data: {
          "login_field":
              loginField, // سنسميه login_field في السيرفر ليعرف أنه قد يكون هذا أو ذاك
          "password": password,
        },
      );
    } on DioException catch (e) {
      // نرجع الـ response حتى لو كان هناك خطأ (مثل 401: كلمة سر خاطئة)
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            statusMessage: "خطأ في الاتصال بالسيرفر",
          );
    }
  }

  //
  //
  //
  //4. دالة ارسال حقل الايميل (نسيت كلمة المرور)

  // دالة طلب إرسال رمز إعادة تعيين كلمة المرو
  Future<Response> requestPasswordReset({required String loginField}) async {
    try {
      return await _dio.post(
        "/forgot-password", // الرابط اللي رح نعمله باللارافيل لاحقاً
        data: {
          "login_field": loginField, // الإيميل أو رقم الهاتف
        },
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            statusMessage: "خطأ في الاتصال بالسيرفر",
          );
    }
  }

  //
  //
  //
  // 5. هي دالة ارسال الايميل ورمز التحقق على السيرفر لنسيت كلمة المرور

  Future<Response> verifyResetOtp({
    required String loginField,
    required String otpCode,
  }) async {
    try {
      return await _dio.post(
        "/verify-reset-otp", //هاد الرابط ه
        data: {"login_field": loginField, "otp_code": otpCode},
      );
    } on DioException catch (e) {
      return e.response ??
          Response(requestOptions: RequestOptions(path: ''), statusCode: 500);
    }
  }

  //
  //
  //
  // 6. دالة تحديث كلمة المرور الجديدة
  Future<Response> resetPassword({
    required String loginField,
    required String newPassword,
  }) async {
    try {
      return await _dio.post(
        "/reset-password", // هاد الرابط
        data: {"login_field": loginField, "password": newPassword},
      );
    } on DioException catch (e) {
      return e.response ??
          Response(requestOptions: RequestOptions(path: ''), statusCode: 500);
    }
  }

  //
  //
  //
  //
  // 7. دالة تحديث بيانات الملف الشخصي (Profile)
  Future<Response> updateProfile({
    required String name,
    required String phone,
    required String token,
    Uint8List? imageBytes, //  1.  متغير اختياري لاستقبال الصورة كبايتات
  }) async {
    try {
      //حولت طريقة تجميع البيانات وارسالها للسيرفر
      FormData formData = FormData.fromMap({
        "name": name,
        "phone": phone,
        //  3. شرط : إذا المستخدم اختار صورة، ارفقها كملف مع الطلب باسم "image"
        if (imageBytes != null)
          "image": MultipartFile.fromBytes(
            imageBytes,
            filename: "profile_image.jpg",
          ),
      });

      return await _dio.post(
        "/update-profile", // الرابط لتحديث البروفايل في اللارافيل
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token", // إرسال التوكن لحماية البيانات
          },
        ),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            statusMessage: "خطأ في الاتصال بالسيرفر",
          );
    }
  }

  //
  //
  //
  //
  //8
  // 8. دالة جلب رحلات المستخدم القادمة والسابقة باستخدام التوكن)
  Future<Response> getUserTrips({required String token}) async {
    try {
      return await _dio.get(
        "/user-trips", // الرابط الجديد المحمي داخل الجروب
        options: Options(
          headers: {
            'Authorization':
                'Bearer $token', // تمرير التوكن ليعرف السيرفر تلقائياً من هو المستخدم
          },
        ),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(requestOptions: RequestOptions(path: ''), statusCode: 500);
    }
  }

  //
  //
  //
  //
  //9
  //دالة حذف رحلة
  Future<Response> cancelUserBooking({
    required String token,
    required int bookingId,
  }) async {
    return await _dio.post(
      '/cancel-booking',
      data: {'booking_id': bookingId},
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // تمرير التوكن ليتعرف لارافيل على صاحب الحجز
        },
      ),
    );
  }
}
