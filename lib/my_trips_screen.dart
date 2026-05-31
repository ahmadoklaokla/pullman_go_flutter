import 'package:dio/dio.dart'; // 💡 تم استيراد مكتبة Dio للتعامل مع استثناءات الشبكة والـ Validation الراجعة من لارافيل
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart'; // 🌟 استدعاء ملف الساعي المشترك لتمرير التوكن بأمان
import 'ticket_details_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  bool isUpcoming = true;
  List<dynamic> upcomingTrips = [];
  List<dynamic> pastTrips = [];
  bool isLoading = true; // مؤشر التحميل مثل شاشة البروفايل تماماً

  // 🌟 الألوان الجديدة المتناسقة مع واجهة التطبيق الفخمة
  final Color primaryDarkBlue = const Color(
    0xFF1C2E4A,
  ); // الكحلي الغامق الفخم (لون زر بحث والخطوط والعناوين)
  final Color inactiveBox = const Color(
    0xFFF1F3F4,
  ); // الرمادي الفاتح جداً للخلفيات والأزرار غير المفعّلة
  final Color inactiveText = Colors.grey.shade700; // لون النصوص غير المفعّلة
  // 🌟 استبدلنا كائن الـ Dio المباشر بـ ApiService المشترك
  final ApiService _apiService = ApiService();
  String? token; // الاحتفاظ بالتوكن هنا بعد قراءته من الذاكرة بدلاً من الآيدي

  @override
  void initState() {
    super.initState();
    // جلب البيانات فور فتح الشاشة تماماً مثل البروفايل
    _loadDataAndFetchTrips();
  }

  // دالة مطابقة لأسلوب البروفايل: تقرأ من الذاكرة أولاً ثم تتصل بالسيرفر
  Future<void> _loadDataAndFetchTrips() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      // 🌟 جلب التوكن الحامي والتعريفي للمسافر من الذاكرة تماماً مثل البروفايل
      token = prefs.getString('token');
    });

    print("DEBUG: Final Checked Token in Memory is: $token");

    // استدعاء السيرفر
    await _fetchUserTrips();
  }

  Future<void> _fetchUserTrips() async {
    // إذا لم يتم العثور على التوكن نهائياً، نوقف التحميل ونظهر تنبيه
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "لم يتم العثور على بيانات المستخدم، أعد تسجيل الدخول",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      print("DEBUG: Fetching trips using Security Token...");

      // 🌟 استدعاء السيرفر من خلال الدالة المحمية الجديدة بالتوكن لمنع انهيار الويب
      final response = await _apiService.getUserTrips(token: token!);

      if (response.statusCode == 200 && response.data['status'] == true) {
        setState(() {
          upcomingTrips = response.data['data']['upcoming'];
          pastTrips = response.data['data']['past'];
          isLoading = false; // إيقاف دائرة التحميل بعد نجاح جلب البيانات
        });
      } else {
        setState(() => isLoading = false);
        String errorMsg = response.data['message'] ?? "فشل جلب بيانات الرحلات";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, textAlign: TextAlign.center),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ في جلب بيانات الرحلات: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelDialog(BuildContext context, int bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Center(
              child: Text(
                "هل انت متأكد من الغاء رحلتك؟؟",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                // 🌟 تم تعديل لون زر "لا" ليصبح كحلي بدلاً من الأخضر القديم
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDarkBlue,
                ),
                child: const Text("لا", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelBookingOnServer(bookingId);
                },
                style: ElevatedButton.styleFrom(backgroundColor: inactiveBox),
                child: const Text("نعم", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelBookingOnServer(int bookingId) async {
    // التحقق المبدئي من وجود التوكن
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("انتهت الجلسة، يرجى إعادة تسجيل الدخول"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // الاتصال الفعلي بالباك أند عبر الساعي المشترك
      final response = await _apiService.cancelUserBooking(
        token: token!,
        bookingId: bookingId,
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        // إذا نجح الحذف في السيرفر، نقوم بحذفه من القائمة المحلية لتحديث الشاشة فوراً
        setState(() {
          upcomingTrips.removeWhere((trip) => trip['booking_id'] == bookingId);
          isLoading = false;
        });

        // 👈 تم تعديل الرسالة لتوجيه المسافر لمقر الشركة مع زيادة وقت الظهور لتصبح مقروءة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "تم إلغاء حجزك بنجاح. يرجى زيارة أقرب مقر للشركة في أقرب وقت ممكن لاستعادة المبلغ المالي الخاص بك.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 8), // خمس ثوانٍ لتكون مريحة بالقراءة
          ),
        );
      } else {
        setState(() => isLoading = false);
        String errorMsg =
            response.data['message'] ?? "فشل إلغاء الحجز من السيرفر";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, textAlign: TextAlign.center),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      // معالجة وتفكيك أخطاء الـ Dio الراجعة من لارافيل لحماية التطبيق من الانهيار
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("رفض السيرفر: ${responseData['message']}"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ في الاتصال بالشبكة: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا كانت الشاشة تقرأ الذاكرة أو السيرفر، تظهر دائرة التحميل الخضراء مثل البروفايل تماماً
    if (isLoading) {
      // 🌟 تم تعديل لون دائرة التحميل لتصبح كحلي متناسق مع هوية واجهتك الفخمة بدلاً من الأخضر
      return Center(child: CircularProgressIndicator(color: primaryDarkBlue));
    }

    return Column(
      children: [
        _buildTabsSection(),
        Expanded(
          child: isUpcoming ? _buildUpcomingContent() : _buildPastContent(),
        ),
      ],
    );
  }

  Widget _buildTabsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => isUpcoming = true),
              child: _buildTabButton("الرحلات القادمة", isUpcoming),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => isUpcoming = false),
              child: _buildTabButton("الرحلات السابقة", !isUpcoming),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        // 🌟 تعديل هنا: اللون بصير كحلي لما يكون فعال بدلاً من الأخضر
        color: isActive ? primaryDarkBlue : inactiveBox,
        borderRadius: BorderRadius.circular(12),
        // 🌟 تعديل هنا: الشادو بصير متناسق مع الكحلي
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primaryDarkBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : inactiveText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingContent() {
    if (upcomingTrips.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد رحلات قادمة حالياً",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: upcomingTrips.length,
      itemBuilder: (context, index) {
        final trip = upcomingTrips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trip['company_name'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const CircleAvatar(
                    backgroundColor: Color(0xFF1C2E4A),
                    child: Icon(
                      Icons.bus_alert,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        trip['from_city'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        trip['scheduled_time'].toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  // 🌟 تم تعديل لون سهم الاتجاه ليصبح كحلي متناسق مع الهوية بدلاً من الأخضر القديم
                  Icon(Icons.arrow_forward, color: primaryDarkBlue),
                  Column(
                    children: [
                      Text(
                        trip['to_city'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        trip['travel_date'].toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  // 🌟 تم تعديل لون زر "عرض التذكرة" ليكون كحلي فخم بدلاً من الأخضر القديم
                  Expanded(
                    child: _buildActionButton(
                      "عرض التذكرة",
                      primaryDarkBlue,
                      Colors.white,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketDetailsScreen(
                              bookingData: trip,
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      "إلغاء الحجز",
                      inactiveBox,
                      inactiveText,
                      () => _showCancelDialog(context, trip['booking_id']),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    String label,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPastContent() {
    if (pastTrips.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد رحلات سابقة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: pastTrips.length,
      itemBuilder: (context, index) {
        final trip = pastTrips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        "الانطلاق",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        trip['from_city'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_back, color: Colors.grey),
                  Column(
                    children: [
                      const Text(
                        "الوصول",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        trip['to_city'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "التاريخ: ${trip['travel_date']}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicketDetailsScreen(
                            bookingData: trip,
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      // 🌟 تم تعديل خلفية زر "عرض تفاصيل الرحلة" السابقة لتصبح كحلي فخم بدلاً من الأخضر القديم
                      decoration: BoxDecoration(
                        color: primaryDarkBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "عرض تفاصيل الرحلة",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
