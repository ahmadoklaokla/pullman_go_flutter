import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'seat_selection_screen.dart';

class OfferModel {
  final String company, from, to, oldPrice, newPrice, duration;
  final String token;
  final DateTime startDate;
  final DateTime endDate;
  final int? companyId;
  final int? routeId;
  final int rawOfferPrice;
  final String? fromStation; // 🟢 إضافة متغير محطة الانطلاق
  final String? toStation; // 🟢 إضافة متغير محطة الوصول
  final int? tripId; // 🟢 إضافة معرف الرحلة الخاص بالعرض

  OfferModel({
    this.companyId,
    this.routeId,

    required this.company,
    required this.from,
    required this.to,
    required this.oldPrice,
    required this.newPrice,
    required this.duration,
    required this.token,

    required this.startDate,
    required this.endDate,

    required this.rawOfferPrice,
    this.fromStation, // 🟢 استقبال محطة الانطلاق
    this.toStation, // 🟢 استقبال محطة الوصول
    //مشان يقدر يستقبل عرض على رحلة محددة من مسار
    this.tripId,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    String formattedOldPrice = (json['old_price'] ?? '0').toString().split(
      '.',
    )[0];
    String formattedNewPrice = (json['offer_price'] ?? '0').toString().split(
      '.',
    )[0];

    DateTime parsedStart =
        DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now();
    DateTime parsedEnd =
        DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now();

    // بيتحط هون جوات الـ factory ليعالج الرقم ويجهزه
    int parsedOfferPrice = json['offer_price'] is int
        ? json['offer_price']
        : (int.tryParse(json['offer_price']?.toString().split('.')[0] ?? '0') ??
              0);

    return OfferModel(
      companyId: json['company']?['id'],
      routeId: json['route_id'] ?? json['route']?['id'],
      company: json['company']?['name'] ?? ' غير محدد',
      from: json['route']?['departure_city']?['name'] ?? 'غير محدد',
      to: json['route']?['arrival_city']?['name'] ?? 'غير محدد',
      oldPrice: "$formattedOldPrice ل.س",
      newPrice: "$formattedNewPrice ل.س",
      duration: "من ${json['start_date']} إلى ${json['end_date']}",
      token: json['token'] ?? '',
      //  ومرر هذا هون
      startDate: parsedStart,
      endDate: parsedEnd,

      rawOfferPrice: parsedOfferPrice,

      tripId: json['trip_id'],
    );
  }
}

class OffersScreen extends StatefulWidget {
  final String token; //  هاد السطر يلي انضاف هون

  //  وعدلنا الـ Constructor ليصير يطلب الـ token بشكل إجباري
  const OffersScreen({super.key, required this.token});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  Future<List<OfferModel>> fetchOffers() async {
    final String apiUrl = '${ApiService.baseUrl}/offers';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => OfferModel.fromJson(data)).toList();
      } else {
        throw Exception('فشل في تحميل العروض');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // مشان يجيبلي الرحلات يلى حسب التاريخ تبع العرض الي اختاره المستخدم
  // 👈 دالة جلب الرحلات المحدثة للفحص وكشف الأخطاء
  Future<List<dynamic>> fetchTripsByDate(
    String tripDate,
    int? companyId,
    int? routeId,
  ) async {
    final String apiUrl =
        '${ApiService.baseUrl}/get-company-trips?trip_date=$tripDate&company_id=$companyId&route_id=$routeId';

    print("🔗 الرابط الجديد والمكتمل: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("🚦 الحالة: ${response.statusCode}");
      print("📄 الرد: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        return decodedData['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("❌ خطأ فلاتر: $e");
      return [];
    }
  }

  // دالة تحويل الوقت من 24 إلى 12 ساعة بالعربي
  String formatTime12Hour(String time24) {
    if (time24.isEmpty) return 'غير محدد';
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      String minute = parts[1]; // الدقائق بتضل مثل ما هي

      String period = hour >= 12 ? "م" : "ص";
      int hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return "$hour12:$minute $period";
    } catch (e) {
      return time24; // إذا صار أي خطأ بالتحويل بنرجع الوقت مثل ما إجا
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F9FC,
      ), // خلفية ناعمة جداً تبرز البطاقات البيضاء
      body: FutureBuilder<List<OfferModel>>(
        future: fetchOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF162D4A)),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد عروض حالياً"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var offer = snapshot.data![index];
              return _buildOfferCard(context, offer);
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferModel offer) {
    final Color primaryGreen = const Color(0xFF162D4A);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // انحناءات فخمة وعصرية
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF1E293B,
            ).withOpacity(0.04), // ظلال هادئة واحترافية
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // القسم العلوي للبطاقة
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الترويسة: اسم الشركة + شارة العرض المميز
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          offer.company,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt, color: Color(0xFF047857), size: 14),
                          SizedBox(width: 2),
                          Text(
                            "عرض خاص",
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // اتجاه الرحلة: السهم يتجه من اليسار إلى اليمين
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // مدينة الانطلاق
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "من",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer.from,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // أيقونة الحافلة + السهم المتجه من اليسار إلى اليمين
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_bus_rounded,
                              color: Color(0xFF162D4A),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ), // السهم يتجه لليمين
                          ],
                        ),
                      ),

                      // مدينة الوصول
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "إلى",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer.to,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // قسم الأسعار: السعر الحالي باللون الأسود وبحجم خط مصغّر ومتناسق (16)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "السعر الحالي",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.newPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "السعر القديم",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.oldPrice,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors
                                .redAccent, // خط التشطيب باللون الأحمر بطلبكِ
                            decorationThickness:
                                1.5, // سماكة ناعمة ومناسبة لخط الشطب
                            color: Color(
                              0xFF94A3B8,
                            ), // بقاء لون أرقام النص رمادي كما هو
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // الشريط السفلي للبطاقة (مدة العرض وزر احجز الآن)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر احجز الآن العصري
                ElevatedButton(
                  //عن الضغط على زر احجز الان يفتحلي واجهة منبثقة لتحديد التاريخ ومواعيد الرحلات
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        DateTime? selectedDate;
                        List<dynamic> availableTrips = [];
                        dynamic selectedTrip;
                        bool isLoadingTrips = false;

                        // StatefulBuilder لتحديث الحقول داخل النافذة فوراً
                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors
                                  .white, // منع تأثيرات الألوان الافتراضية
                              titlePadding: const EdgeInsets.only(
                                top: 24,
                                left: 24,
                                right: 24,
                                bottom: 10,
                              ),
                              title: Column(
                                children: [
                                  // 👈 الأيقونة الجديدة المحدثة بأعلى مستوى تصميم
                                  Container(
                                    padding: const EdgeInsets.all(
                                      16,
                                    ), // زيادة المساحة الداخلية
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF162D4A,
                                      ), // لون البراند الأساسي صار بالخلفية
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF162D4A)
                                              .withOpacity(
                                                0.25,
                                              ), // ظلال بلون البراند ليعطي تأثير توهج ناعم
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons
                                          .airline_seat_recline_normal_rounded, // أيقونة مقعد حقيقي وواقعي أكثر وبحجم ممتاز
                                      color: Colors
                                          .white, // الأيقونة باللون الأبيض لتبرز فوق الخلفية الغامقة
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "تحديد موعد الحجز",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // --- الحقل الأول: اختيار التاريخ ---
                                  InkWell(
                                    onTap: () async {
                                      // فتح الرزنامة محددة بفترة العرض فقط
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: offer.startDate,
                                        firstDate:
                                            offer.startDate, // بداية العرض
                                        lastDate: offer.endDate, // نهاية العرض
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary: Color(
                                                      0xFF162D4A,
                                                    ), // لون الرزنامة
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );

                                      if (picked != null) {
                                        setDialogState(() {
                                          selectedDate = picked;
                                          isLoadingTrips = true;
                                          selectedTrip =
                                              null; // تصفير الرحلة القديمة
                                        });

                                        // تحويل التاريخ لنص لإرساله للباك آند
                                        String formattedDate =
                                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

                                        // استدعاء الدالة المربوطة بالباك آند
                                        // 1. جلب الرحلات من السيرفر بدون تكرار
                                        List<dynamic> rawTrips =
                                            await fetchTripsByDate(
                                              formattedDate,
                                              offer.companyId,
                                              offer.routeId,
                                            );

                                        // 2. فلترة التكرار بناءً على وقت الرحلة
                                        // 2. فلترة التاريخ (لأن الباك آند برجع كل التواريخ) + فلترة التكرار بناءً على وقت الرحلة
                                        var seenTimes =
                                            <
                                              String
                                            >{}; // سلة نحفظ فيها الأوقات اللي شفناها
                                        List<dynamic> uniqueTrips =
                                            []; // القائمة النهائية الصافية

                                        for (var trip in rawTrips) {
                                          // جلب التاريخ من الـ JSON (بيكون بصيغة: 2026-05-24T00:00:00.000000Z)
                                          String tripDateFromJson =
                                              trip['trip_date'] ?? '';

                                          //  : التأكد أولاً إن الرحلة بتطابق التاريخ المختار فعلياً
                                          if (tripDateFromJson.startsWith(
                                            formattedDate,
                                          )) {
                                            // 🟢 الفحص الجديد: لو العرض لرحلة محددة، تخطى أي رحلة تانية ما بتطابق الـ ID
                                            if (offer.tripId != null &&
                                                trip['id'] != offer.tripId) {
                                              continue;
                                            }
                                            String time =
                                                trip['scheduled_time'] ?? '';

                                            // فلترة التكرار للوقت
                                            if (!seenTimes.contains(time)) {
                                              seenTimes.add(time);
                                              uniqueTrips.add(trip);
                                            }
                                          }
                                        }

                                        // 3. تحديث الواجهة بالقائمة الصافية فقط
                                        setDialogState(() {
                                          availableTrips = uniqueTrips;
                                          isLoadingTrips = false;
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            selectedDate == null
                                                ? "اختر تاريخ الرحلة"
                                                : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: selectedDate == null
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                              color: selectedDate == null
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.calendar_month_rounded,
                                            color: Color(0xFF162D4A),
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- الحقل الثاني: قائمة الرحلات المنسدلة ---
                                  isLoadingTrips
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF162D4A),
                                          ),
                                        )
                                      : DropdownButtonFormField<dynamic>(
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF64748B),
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            hintText: "اختر الرحلة المتاحة",
                                            hintStyle: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF162D4A),
                                                width: 1.5,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                          value: selectedTrip,
                                          items: availableTrips.map((trip) {
                                            return DropdownMenuItem<dynamic>(
                                              value: trip,
                                              child: Text(
                                                "موعد انطلاق الرحلة: ${formatTime12Hour(trip['scheduled_time'] ?? '')}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: selectedDate == null
                                              ? null
                                              : (value) {
                                                  setDialogState(() {
                                                    selectedTrip = value;
                                                  });
                                                },
                                        ),
                                ],
                              ),
                              actionsPadding: const EdgeInsets.only(
                                bottom: 24,
                                left: 24,
                                right: 24,
                              ),
                              actions: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "إلغاء",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2, // زر التأكيد بياخد مساحة أكبر
                                      child: ElevatedButton(
                                        onPressed:
                                            (selectedDate == null ||
                                                selectedTrip == null)
                                            ? null
                                            : () {
                                                // إغلاق النافذة المنبثقة
                                                Navigator.pop(context);

                                                int? dynamicTripId =
                                                    selectedTrip['id'] is int
                                                    ? selectedTrip['id']
                                                    : int.tryParse(
                                                        selectedTrip['id']
                                                                ?.toString() ??
                                                            '',
                                                      );
                                                // 💡 استخراج البيانات الديناميكية من الرحلة اللي اختارها المستخدم من القائمة المنسدلة
                                                // 1. تحويل الباص إلى Map صريح لتفادي أخطاء الـ dynamic
                                                final busData =
                                                    selectedTrip['bus']
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >?;

                                                // 3. 🎯 التعديل السحري: استخراج حقل total_seats الإجمالي بأمان تام
                                                int dynamicTotalSeats = 0;
                                                if (busData != null &&
                                                    busData['total_seats']
                                                        is int) {
                                                  dynamicTotalSeats =
                                                      busData['total_seats'];
                                                } else {
                                                  // هنا بنحاول نجيبه من كائن الباص، وإذا ما لقاه بنجيبه من كائن الرحلة مباشرة، وإذا كلو null بيعطي 0
                                                  dynamicTotalSeats =
                                                      int.tryParse(
                                                        busData?['total_seats']
                                                                ?.toString() ??
                                                            '',
                                                      ) ??
                                                      int.tryParse(
                                                        selectedTrip['total_seats']
                                                                ?.toString() ??
                                                            '',
                                                      ) ??
                                                      0;
                                                }

                                                int dynamicSeatCount = 0;
                                                if (busData != null &&
                                                    busData['seat_count']
                                                        is int) {
                                                  dynamicSeatCount =
                                                      busData['seat_count'];
                                                } else {
                                                  dynamicSeatCount =
                                                      int.tryParse(
                                                        busData?['seat_count']
                                                                ?.toString() ??
                                                            '',
                                                      ) ??
                                                      int.tryParse(
                                                        selectedTrip['seat_count']
                                                                ?.toString() ??
                                                            '',
                                                      ) ??
                                                      0;
                                                }

                                                // 4. استخراج رقم الباص
                                                String dynamicBusNumber =
                                                    busData?['bus_numbernnn']
                                                        ?.toString() ??
                                                    selectedTrip['bus_numbernnn']
                                                        ?.toString() ??
                                                    "غير محدد";

                                                // 5. استخراج محطات الانطلاق والوصول
                                                // 5. 🎯 الحل النهائي الشامل: جلب المدينة والعنوان مع فحص الـ route بأمان
                                                String fromCityName =
                                                    selectedTrip['from_station']
                                                        ?.toString() ??
                                                    "";
                                                String fromAddress =
                                                    selectedTrip['departure_address']
                                                        ?.toString() ??
                                                    selectedTrip['route']?['departure_address']
                                                        ?.toString() ??
                                                    "";
                                                String dynamicFromStation =
                                                    fromAddress.isNotEmpty
                                                    ? "$fromCityName ($fromAddress)"
                                                    : fromCityName;

                                                String toCityName =
                                                    selectedTrip['to_station']
                                                        ?.toString() ??
                                                    "";
                                                String toAddress =
                                                    selectedTrip['arrival_address']
                                                        ?.toString() ??
                                                    selectedTrip['route']?['arrival_address']
                                                        ?.toString() ??
                                                    "";
                                                String dynamicToStation =
                                                    toAddress.isNotEmpty
                                                    ? "$toCityName ($toAddress)"
                                                    : toCityName;

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => SeatSelectionScreen(
                                                      tripId: dynamicTripId,
                                                      fromCity: offer.from,
                                                      toCity: offer.to,
                                                      selectedDate:
                                                          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                                                      tripTime: formatTime12Hour(
                                                        selectedTrip['scheduled_time'] ??
                                                            "",
                                                      ),
                                                      companyName:
                                                          offer.company,
                                                      tripRoute:
                                                          "${offer.from} ← ${offer.to}",
                                                      totalSeats:
                                                          dynamicTotalSeats, // 🟢 مررنا عدد مقاعد الباص الديناميكي
                                                      busNumber:
                                                          dynamicBusNumber, // 🟢 مررنا رقم الباص الديناميكي

                                                      fromStation:
                                                          dynamicFromStation, // محطة الانطلاق من السيرفر
                                                      toStation:
                                                          dynamicToStation,

                                                      tripPrice: offer
                                                          .rawOfferPrice, // 🟢 السعر الصح والمضمون 100% بيتوجه من هون

                                                      token: widget.token,
                                                    ),
                                                  ),
                                                );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF162D4A,
                                          ),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(
                                            0xFFCBD5E1,
                                          ), // لون الزر وهو معطل
                                          disabledForegroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "تأكيد واختيار المقاعد",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "احجز الآن",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),

                // مدة صلاحية العرض
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF64748B),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offer.duration,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
