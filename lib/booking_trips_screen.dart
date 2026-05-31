import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'seat_selection_screen.dart';

class BookingTripsScreen extends StatefulWidget {
  final int? companyId;
  final int? routeId;
  final String companyName;
  final String logo;
  final String fromCity;
  final String toCity;
  final String selectedDate;
  final int dayIndex;
  final String token;

  const BookingTripsScreen({
    super.key,
    this.companyId,
    this.routeId,
    required this.companyName,
    required this.logo,
    required this.fromCity,
    required this.toCity,
    required this.selectedDate,
    required this.dayIndex,
    required this.token,
  });

  @override
  State<BookingTripsScreen> createState() => _BookingTripsScreenState();
}

class _BookingTripsScreenState extends State<BookingTripsScreen> {
  int activeTab = 0;

  // 🎨 الألوان الفخمة المعتمدة والموحدة للتطبيق
  final Color primaryNavy = const Color(0xFF050E1A); // الكحلي الغامق الفخم
  final Color accentIceBlue = const Color(
    0xFF162D4A,
  ); // لغة الأزرار والتفاصيل النشطة (زر البحث)
  final Color lightGreyBackground = const Color(
    0xFFF4F6F9,
  ); // الخلفية المريحة الموحدة

  List<dynamic> serverTrips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrips();
  }

  Future<void> fetchTrips() async {
    if (widget.companyId == null || widget.routeId == null) {
      setState(() => isLoading = false);
      return;
    }

    // 💡 حماية إضافية: تنظيف التاريخ وتحويله قبل إرساله لدالة جلب مواعيد الشركة
    String optimizedDate = widget.selectedDate.trim();
    try {
      if (optimizedDate.contains('/')) {
        List<String> dateParts = optimizedDate.split('/');
        if (dateParts.length == 3) {
          String day = dateParts[0].padLeft(2, '0');
          String month = dateParts[1].padLeft(2, '0');
          String year = dateParts[2];
          optimizedDate = "$year-$month-$day";
        }
      }
    } catch (e) {
      print("Error optimizedDate parsing: $e");
    }

    try {
      final response = await Dio().get(
        '${ApiService.baseUrl}/get-company-trips',
        queryParameters: {
          'company_id': widget.companyId,
          'route_id': widget.routeId,
          'date':
              optimizedDate, // 👈  بنرسل التاريخ النظيف والجاهز باسم 'date' تماماً مثل ما بدو الباك إند
        },
      );

      if (response.data['status'] == true) {
        setState(() {
          serverTrips = response.data['data'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _formatTo12Hour(String time24) {
    try {
      List<String> parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = "ص";
      if (hour >= 12) {
        period = "م";
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;

      String strHour = hour.toString().padLeft(2, '0');
      String strMinute = minute.toString().padLeft(2, '0');

      return "$strHour:$strMinute $period";
    } catch (e) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGreyBackground, // تطبيق الخلفية الموحدة
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: primaryNavy, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "اختيار موعد الرحلة",
            style: TextStyle(
              color: primaryNavy,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryNavy.withOpacity(0.06),
                        blurRadius: 15,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: widget.logo.startsWith('http')
                        ? Image.network(widget.logo, fit: BoxFit.cover)
                        : Image.asset(widget.logo, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.companyName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: primaryNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHeaderCard(),
            const SizedBox(height: 25),
            _buildFilterTabs(),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: accentIceBlue),
                    ) // تحديث لون مؤشر التحميل
                  : serverTrips.isEmpty
                  ? Center(
                      child: Text(
                        "لا توجد رحلات متاحة لهذا اليوم",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      children: _getFilteredTrips(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _headerInfo(
              "من",
              widget.fromCity,
              Icons.location_on_outlined,
            ),
          ),
          Icon(
            Icons.arrow_forward,
            color: accentIceBlue.withOpacity(0.4),
            size: 20,
          ), // تحديث لون السهم المنساب
          Expanded(child: _headerInfo("إلى", widget.toCity, Icons.location_on)),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Expanded(
            child: _headerInfo(
              "التاريخ",
              widget.selectedDate,
              Icons.calendar_today_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: accentIceBlue), // تحديث ألوان رموز الهيدر
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _tabItem("الكل", 0)),
          Expanded(child: _tabItem("صباحاً", 1)),
          Expanded(child: _tabItem("مساءً", 2)),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    bool isSelected = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentIceBlue
              : Colors.transparent, // تحديث الخلفية النشطة للتاب
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getFilteredTrips() {
    return serverTrips
        .where((t) {
          String timeStr = (t['scheduled_time'] ?? "").toString();
          if (activeTab == 0) return true;
          try {
            int hour = int.parse(timeStr.split(':')[0]);
            if (activeTab == 1) return hour < 12;
            if (activeTab == 2) return hour >= 12;
          } catch (e) {
            print(e);
          }
          return true;
        })
        .map((t) => _buildTripCard(t))
        .toList();
  }

  Widget _buildTripCard(Map<String, dynamic> tripData) {
    String time = tripData['scheduled_time']?.toString() ?? "00:00";

    DateTime now = DateTime.now();
    bool isPast = false;

    try {
      DateTime selectedDate;
      List<String> dateParts = widget.selectedDate.split(RegExp(r'[/-]'));
      if (dateParts[0].length < 4) {
        selectedDate = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
      } else {
        selectedDate = DateTime.parse(widget.selectedDate);
      }

      List<String> timeParts = time.split(':');
      DateTime tripDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      if (tripDateTime.isBefore(now)) {
        isPast = true;
      }
    } catch (e) {
      print("Error parsing date/time: $e");
    }

    String displayTime = _formatTo12Hour(
      time.length >= 5 ? time.substring(0, 5) : time,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!isPast)
            BoxShadow(color: primaryNavy.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isPast
              ? null
              : () {
                  var routeData = tripData['route'] ?? {};
                  String? fromStation =
                      tripData['departure_address'] ??
                      routeData['departure_address'];
                  String? toStation =
                      tripData['arrival_address'] ??
                      routeData['arrival_address'];

                  var busData = tripData['bus'] ?? {};
                  int dynamicTotalSeats = busData['total_seats'] ?? 35;

                  // 💡 التقاط رقم الباص بالاعتماد على الحقل الصحيح في جدول الـ buses المكتوب بـ 3 n
                  String dynamicBusNumber =
                      (busData['bus_numbernnn'] ??
                              tripData['bus_numbernnn'] ??
                              "غير محدد")
                          .toString();

                  // 💡 الفحص الشامل والمستقر لاستخراج السعر base_price بدقة ومنع الـ null أو الـ 0
                  int realPrice = 0;
                  var rawPrice =
                      routeData['base_price'] ??
                      tripData['base_price'] ??
                      tripData['price'];
                  if (rawPrice != null) {
                    if (rawPrice is num) {
                      realPrice = rawPrice.toInt();
                    } else {
                      realPrice =
                          double.tryParse(rawPrice.toString())?.toInt() ?? 0;
                    }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeatSelectionScreen(
                        tripId: tripData['id'],
                        fromCity: widget.fromCity,
                        toCity: widget.toCity,
                        selectedDate: widget.selectedDate,
                        tripTime: time,
                        fromStation: fromStation?.toString(),
                        toStation: toStation?.toString(),
                        companyName: widget.companyName,
                        totalSeats: dynamicTotalSeats,
                        busNumber: dynamicBusNumber,
                        tripPrice:
                            realPrice, // 👈 تمرير السعر الملتقط بشكل دقيق
                        token: widget.token,
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey[300]
                        : accentIceBlue.withOpacity(
                            0.1,
                          ), // تحديث لون خلفية أيقونة الوقت النشط
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPast
                        ? Icons.timer_off_outlined
                        : Icons.access_time_filled,
                    color: isPast
                        ? Colors.grey[500]
                        : accentIceBlue, // تحديث لون الأيقونة النشطة
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPast
                            ? "انتهى وقت الرحلة ($displayTime)"
                            : "انطلاق الرحلة: $displayTime",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isPast
                              ? Colors.grey[400]
                              : primaryNavy, // ربط نصوص الرحلة باللون الكحلي الرئيسي الفخم
                          decoration: isPast
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_bus_filled_outlined,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPast ? "الحجز مغلق" : "رحلة مباشرة",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isPast)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[300],
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
