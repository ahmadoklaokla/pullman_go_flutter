import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'passenger_details_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int? tripId;
  final String fromCity;
  final String toCity;
  final String selectedDate;
  final String token;
  final String tripTime;
  final String? companyName;
  final String? tripRoute;
  final String? fromStation;
  final String? toStation;
  final int? totalSeats;
  final String? busNumber;
  final int? tripPrice;

  const SeatSelectionScreen({
    super.key,
    this.tripId,
    required this.fromCity,
    required this.toCity,
    required this.selectedDate,
    required this.tripTime,
    this.companyName,
    this.tripRoute,
    this.fromStation,
    this.toStation,
    this.totalSeats,
    this.busNumber,
    this.tripPrice,
    required this.token,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // 🎨 تحديث الألوان الفخمة الموحدة للتطبيق دون المساس بأي منطق برمي
  final Color primaryNavy = const Color(
    0xFF050E1A,
  ); // الكحلي الغامق الفخم للـ AppBar والنصوص الأساسية
  final Color accentIceBlue = const Color(
    0xFF162D4A,
  ); // لون الأزرار والمقاعد المحددة النشطة
  final Color iceAvailableSeat = const Color(
    0xFFD4E6F1,
  ); // لون جليدي ناعم ومريح للمقاعد المتاحة

  List<int> selectedSeats = [];
  List<String> reservedSeats = [];
  bool isSeatsLoading = true;

  late String currentSelectedDate;

  @override
  void initState() {
    super.initState();
    currentSelectedDate = widget.selectedDate;
    fetchReservedSeats();
  }

  Future<void> fetchReservedSeats() async {
    if (widget.tripId == null) {
      setState(() => isSeatsLoading = false);
      return;
    }

    String travelDateParam = widget.selectedDate.trim();

    // 🛠️ معالجة التاريخ وإصلاح الصيغة المائلة (مثال: من 29/5/2026 إلى 2026-05-29) ليتوافق مع لارافيل
    try {
      if (travelDateParam.contains('/')) {
        List<String> parts = travelDateParam.split('/');
        if (parts.length == 3) {
          String day = parts[0].padLeft(2, '0');
          String month = parts[1].padLeft(2, '0');
          String year = parts[2];
          travelDateParam = "$year-$month-$day";
        }
      }
    } catch (e) {
      print("⚠️ فشل في إعادة صياغة التاريخ: $e");
    }

    if (travelDateParam.isEmpty || travelDateParam == "null") {
      DateTime now = DateTime.now();
      travelDateParam =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }

    try {
      final response = await Dio().get(
        '${ApiService.baseUrl}/get-reserved-seats',
        queryParameters: {
          'trip_id': widget.tripId,
          'travel_date': currentSelectedDate,
        },
      );

      if (response.data['status'] == true) {
        setState(() {
          // استقبال السجلات كـ String لضمان عدم حدوث الانهيار عند التحويل
          reservedSeats = List<String>.from(
            (response.data['reserved_seats'] ?? []).map(
              (seat) => seat.toString().trim(),
            ),
          );
          isSeatsLoading = false;
        });
      } else {
        setState(() => isSeatsLoading = false);
      }
    } catch (e) {
      print("Error fetching reserved seats: $e");
      setState(() => isSeatsLoading = false);
    }
  }

  String _formatTo12Hour(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length < 2) return timeString;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = "ص";
      if (hour >= 12) {
        period = "م";
        if (hour > 12) hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }

      final minuteStr = minute.toString().padLeft(2, '0');
      final hourStr = hour.toString().padLeft(2, '0');

      return "$hourStr:$minuteStr $period";
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    int activeTotalSeats = widget.totalSeats ?? 0;
    String activeBusNumber =
        (widget.busNumber != null &&
            widget.busNumber!.isNotEmpty &&
            widget.busNumber != "null")
        ? widget.busNumber!
        : "غير محدد";

    //   كود السعر القديم والشروط بهذا السطر فقط لاستقبال سعر العرض الفعلي
    int activeTripPrice = widget.tripPrice ?? 0;

    String displayFromStation =
        (widget.fromStation != null && widget.fromStation!.isNotEmpty)
        ? widget.fromStation!
        : "غير محدد";

    String displayToStation =
        (widget.toStation != null && widget.toStation!.isNotEmpty)
        ? widget.toStation!
        : "غير محدد";

    String formattedTime = _formatTo12Hour(widget.tripTime);

    int rowCount = (activeTotalSeats / 4).ceil();
    int gridItemCount = rowCount * 5;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9), // خلفية ناعمة فخمة ومتناسقة
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            "تحديد المقاعد",
            style: TextStyle(
              color: primaryNavy,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: primaryNavy, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryNavy.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFEAEDF2)),
                  ),
                  child: Column(
                    children: [
                      //
                      //
                      //
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. التايم لاين بلمسة الـ "Glowing Effect" الفخمة
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              children: [
                                // نقطة الانطلاق (دائرة مضيئة)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: accentIceBlue.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: accentIceBlue,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentIceBlue.withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // الخط المتدرج بانسيابية
                                Container(
                                  width: 2.5,
                                  height: 52,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        accentIceBlue,
                                        accentIceBlue.withOpacity(0.2),
                                        Colors.redAccent.withOpacity(0.2),
                                        Colors.redAccent,
                                      ],
                                    ),
                                  ),
                                ),
                                // نقطة الوصول (دائرة مضيئة حمراء)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.redAccent.withOpacity(
                                            0.6,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 2. تفاصيل المدن والمحطات (تأثير البطاقات العائمة الملونة)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ---- الانطلاق ----
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.fromCity,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: primaryNavy,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Badge الانطلاق باللون الأزرق الناعم
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentIceBlue.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: accentIceBlue.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.departure_board_rounded,
                                            size: 14,
                                            color: accentIceBlue,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            displayFromStation,
                                            style: TextStyle(
                                              color: primaryNavy.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // ---- الوصول ----
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔴 اسم مدينة الوصول باللون الأحمر الفخم ليتناسق مع الوجهة
                                    Text(
                                      widget.toCity,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.redAccent,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // 🔴 البادج بخلفية حمراء ناعمة وإطار أحمر مريح ومحطة باللون الأحمر
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(
                                          0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.redAccent.withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            size: 14,
                                            color: Colors.redAccent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            displayToStation,
                                            style: TextStyle(
                                              color: Colors.redAccent.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF5F5F5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactInfoField(
                              "تاريخ الرحلة",
                              currentSelectedDate,
                              Icons.calendar_month,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactInfoField(
                              "وقت الانطلاق",
                              formattedTime,
                              Icons.watch_later,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  "حدد عدد المقاعد التي تريد حجزها لهذه الرحلة",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width > 450
                        ? 360
                        : double.infinity,
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom: 24,
                      left: 24,
                      right: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: accentIceBlue.withOpacity(0.15),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryNavy.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tag,
                                    color: Colors.grey.shade400,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "باص رقم: $activeBusNumber",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(
                                    Icons.airline_seat_recline_normal_rounded,
                                    color: primaryNavy,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "السائق",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: primaryNavy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          thickness: 1,
                          color: Colors.grey.shade100,
                          height: 10,
                        ),
                        const SizedBox(height: 12),

                        isSeatsLoading
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: CircularProgressIndicator(
                                  color: accentIceBlue,
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: gridItemCount,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.85,
                                    ),
                                itemBuilder: (context, index) {
                                  if (index % 5 == 2) {
                                    return const SizedBox();
                                  }

                                  int currentSeat = seatCounter(index);

                                  if (currentSeat > activeTotalSeats) {
                                    return const SizedBox();
                                  }

                                  return _buildIndependentSeatItem(currentSeat);
                                },
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                if (!isSeatsLoading) _buildSeatStats(activeTotalSeats),

                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selectedSeats.isEmpty
                          ? []
                          : [
                              BoxShadow(
                                color: accentIceBlue.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: selectedSeats.isEmpty
                          ? null
                          : () async {
                              // 👈 حولنا الدالة لـ async عشان تقرأ الكاش تلقائياً

                              // 1. جلب الـ ID تلقائياً من ذاكرة الجهاز (SharedPreferences)

                              final prefs =
                                  await SharedPreferences.getInstance();

                              // الانتقال للشاشة التالية
                              int currentUserId =
                                  prefs.getInt('user_id') ??
                                  0; // 👈 سحبنا الـ ID الديناميكي

                              // الانتقال للشاشة التالية بالـ ID ا
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PassengerDetailsScreen(
                                    selectedSeats: selectedSeats,
                                    pricePerSeat: activeTripPrice,
                                    fromCity: widget.fromCity,
                                    toCity: widget.toCity,
                                    travelDate:
                                        currentSelectedDate.isEmpty ||
                                            currentSelectedDate == "null"
                                        ? "2026-05-23"
                                        : currentSelectedDate,
                                    busNumber: activeBusNumber,
                                    tripId: widget.tripId,
                                    userId: currentUserId,
                                    token: widget.token,
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentIceBlue,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedSeats.isEmpty
                                ? "التالي"
                                : "التالي (${selectedSeats.length} مقاعد)",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
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

  int seatCounter(int index) {
    int row = index ~/ 5;
    int col = index % 5;
    return row * 4 + (col > 2 ? col : col + 1);
  }

  Widget _buildCompactInfoField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: primaryNavy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndependentSeatItem(int seatNum) {
    bool isReserved = reservedSeats.contains(seatNum.toString());
    bool isSelected = selectedSeats.contains(seatNum);

    return GestureDetector(
      onTap: isReserved
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatNum);
                } else {
                  if (selectedSeats.length < 10) {
                    selectedSeats.add(seatNum);
                  }
                }
              });
            },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: isSelected ? 1.08 : 1.0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              height: 74, // إعطاء مساحة عمودية مريحة لتنفس الطبقات الفاخرة
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _buildRealisticLaravelSeat(
                seatNum: seatNum,
                isReserved: isReserved,
                isSelected: isSelected,
              ),
            ),
          );
        },
      ),
    );
  }

  // 🛠️ الويجت السحرية لرسم المقعد الفاخر بتفاصيله الكاملة (سندة، ظهر، قاعدة، جوانب)

  Widget _buildSeatStats(int totalActualSeats) {
    // 💡 التعديل هنا: فلترة المقاعد المحجوزة بعد تحويلها لأرقام مؤقتاً
    int reservedCount = reservedSeats.where((s) {
      int? num = int.tryParse(s);
      return num != null && num <= totalActualSeats;
    }).length;

    int availableCount = totalActualSeats - reservedCount;

    return Container(
      width: MediaQuery.of(context).size.width > 450 ? 360 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statBox("متاح", availableCount.toString(), Colors.green),
          _statBox("محجوز", reservedCount.toString(), Colors.red),
          _statBox("محدد", selectedSeats.length.toString(), accentIceBlue),
        ],
      ),
    );
  }

  Widget _statBox(String label, String count, Color color) {
    return Row(
      children: [
        Icon(Icons.event_seat_rounded, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: primaryNavy,
          ),
        ),
      ],
    );
  }
}

Widget _buildRealisticLaravelSeat({
  required int seatNum,
  required bool isReserved,
  required bool isSelected,
}) {
  // 🎨 درجات الألوان الفخمة المحدثة بالكامل لزيادة التباين مع النص الأبيض
  // 1. المتاح: أخضر زمردي داكن ومريح للعين
  final List<Color> greenBackrest = [
    const Color(0xFF16A34A),
    const Color(0xFF14532D),
  ];
  final List<Color> greenCushion = [
    const Color(0xFF22C55E),
    const Color(0xFF166534),
  ];

  // 2. المحجوز: أحمر ناري غامق فاخر
  final List<Color> redBackrest = [
    const Color(0xFFDC2626),
    const Color(0xFF7F1D1D),
  ];
  final List<Color> redCushion = [
    const Color(0xFFEF4444),
    const Color(0xFF991B1B),
  ];

  // 3. المحدد: أسود جرافيت ملكي
  final List<Color> blackBackrest = [
    const Color(0xFF4B5563),
    const Color(0xFF111827),
  ];
  final List<Color> blackCushion = [
    const Color(0xFF1F2937),
    const Color(0xFF000000),
  ];

  List<Color> currentBackrest = isReserved
      ? redBackrest
      : (isSelected ? blackBackrest : greenBackrest);

  List<Color> currentCushion = isReserved
      ? redCushion
      : (isSelected ? blackCushion : greenCushion);

  return Directionality(
    textDirection: TextDirection.ltr, // لضمان ثبات الأرقام وتناسقها
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // 🪟 [الطبقة 1: مسند الظهر الخلفي]
        Positioned(
          top: 0,
          child: Container(
            width: 44,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: currentBackrest,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(
                color: Colors.black.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 3,
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // خط لمعة الرأس
                Positioned(
                  top: 3,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🧤 [الطبقة 2: مساند اليدين الجانبية باللون الأسود الملكي]
        Positioned(
          bottom: 8,
          left: -3,
          child: Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF374151), Color(0xFF000000)],
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF4A5568), width: 0.5),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: -3,
          child: Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF374151), Color(0xFF000000)],
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF4A5568), width: 0.5),
            ),
          ),
        ),

        // 🛋️ [الطبقة 3: وسادة الجلوس الأمامية البارزة]
        Positioned(
          bottom: 0,
          child: Container(
            width: 46,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: currentCushion,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2)),
                left: BorderSide(color: Colors.black.withOpacity(0.25)),
                right: BorderSide(color: Colors.black.withOpacity(0.25)),
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.5),
                  width: 5,
                ), // سماكة الـ 3D السفلي
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),

        // 🎯 [الطبقة 4 والأهم: الرقم معزول فوق الـ Stack ومحمي من الاختفاء للأبد]
        Positioned(
          bottom:
              4, // متموضع بدقة فوق وسادة الجلوس تماماً ومرفوع عن الحافة السفلية للكرسي
          child: Container(
            alignment: Alignment.center,
            width: 46,
            height: 24,
            child: Text(
              seatNum.toString().padLeft(
                2,
                '0',
              ), // مظهر احترافي بخانتين (مثال: 07)
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900, // خط عريض صريح وقوي جداً
                fontFamily: 'sans-serif', // خط نظام قياسي لضمان التصيير الفوري
                // إذا محدد (أسود) يشع أخضر فوسفوري نيون روعة، وإذا متاح أو محجوز أبيض ناصع
                color: isSelected ? const Color(0xFF10B981) : Colors.white,
                shadows: [
                  Shadow(
                    color: Colors
                        .black, // ظل حاد وكثيف خلف الرقم ليفصله عن لون الكرسي قسراً
                    offset: const Offset(0, 1.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
