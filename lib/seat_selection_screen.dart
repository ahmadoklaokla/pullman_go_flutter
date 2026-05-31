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
  List<int> reservedSeats = [];
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

    // 💡 حماية برمجية: فحص التاريخ والتأكد من أنه ليس فارغاً أو نص "null" لتفادي خطأ الـ Dio
    String travelDateParam = widget.selectedDate.trim();
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
          'travel_date': travelDateParam, // 👈 إرسال القيمة المحمية والمفحوصة
        },
      );

      if (response.data['status'] == true) {
        setState(() {
          //الباك ايند عم تبعث المقاعد نصوص وهون لازم نحولهم من نصوص لارقام صحيحة
          reservedSeats = (response.data['reserved_seats'] as List? ?? [])
              .map((seat) => int.tryParse(seat.toString()) ?? 0)
              .toList();
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
    int activeTotalSeats = widget.totalSeats ?? 35;
    String activeBusNumber =
        (widget.busNumber != null &&
            widget.busNumber!.isNotEmpty &&
            widget.busNumber != "null")
        ? widget.busNumber!
        : "غير محدد";

    int activeTripPrice = widget.tripPrice ?? 0;
    if (activeTripPrice == 0) {
      if (widget.fromCity.contains("حمص") &&
          widget.toCity.contains("اللاذقية")) {
        activeTripPrice = 250;
      } else if (widget.fromCity.contains("دمشق") &&
          widget.toCity.contains("حلب")) {
        activeTripPrice = 600;
      } else {
        activeTripPrice = 400;
      }
    }

    String displayFromStation =
        (widget.fromStation != null && widget.fromStation!.isNotEmpty)
        ? widget.fromStation!
        : "كراجات شرقي_غربي";

    String displayToStation =
        (widget.toStation != null && widget.toStation!.isNotEmpty)
        ? widget.toStation!
        : "نهر عيشة";

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
                      Row(
                        children: [
                          Column(
                            children: [
                              Icon(Icons.circle, size: 9, color: accentIceBlue),
                              Container(
                                width: 1.5,
                                height: 26,
                                color: Colors.grey.shade300,
                              ),
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.fromCity,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "($displayFromStation)",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      widget.toCity,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "($displayToStation)",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
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
                              currentSelectedDate.isEmpty ||
                                      currentSelectedDate == "null"
                                  ? "2026-05-23"
                                  : currentSelectedDate,
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
    bool isReserved = reservedSeats.contains(seatNum);
    bool isSelected = selectedSeats.contains(seatNum);

    Color iconColor = isReserved
        ? Colors.grey.shade300
        : (isSelected ? accentIceBlue : iceAvailableSeat);

    Color textColor = isReserved
        ? Colors.grey.shade400
        : (isSelected ? accentIceBlue : primaryNavy);

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeIn,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat_rounded, color: iconColor, size: 26),
            const SizedBox(height: 3),
            Text(
              seatNum.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatStats(int totalActualSeats) {
    int reservedCount = reservedSeats
        .where((s) => s <= totalActualSeats)
        .length;
    int availableCount = totalActualSeats - reservedCount;

    return Container(
      width: MediaQuery.of(context).size.width > 450 ? 360 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statBox("متاح", availableCount.toString(), iceAvailableSeat),
          _statBox(
            "محجوز",
            reservedCount.toString(),
            Colors.grey.shade300,
          ), // 👈 تم إصلاح تمرير المتغير هنا ليظهر العدد بشكل صحيح
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
