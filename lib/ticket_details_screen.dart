import 'package:flutter/material.dart';

class TicketDetailsScreen extends StatefulWidget {
  // 👈 إضافة المتغير لاستقبال بيانات الحجز الحقيقية من واجهة رحلاتي
  final dynamic bookingData;
  final VoidCallback onBack;

  // 👈 تحديث الباني ليتضمن المتغير الجديد
  const TicketDetailsScreen({
    super.key,
    this.bookingData,
    required this.onBack,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  // 🌟 تعريف اللون الكحلي الفخم لتوحيد الهوية البصرية عبر التطبيق
  final Color primaryDarkBlue = const Color(0xFF1C2E4A);

  @override
  Widget build(BuildContext context) {
    // استخراج مصفوفة الحجز لتسهيل قراءة البيانات الحقيقية داخل الـ Widgets
    final data = widget.bookingData;

    // استخراج قائمة الركاب الحقيقية القادمة من جدول booking_seats
    final List<dynamic> passengers = data != null && data['passengers'] != null
        ? data['passengers']
        : [];

    // 🌟 دالة لتنظيف نص الوقت من حرف "أ" أو "م" والمسافات الزائدة ليعود أرقاماً صافية فقط
    String getCleanTime() {
      if (data == null || data['scheduled_time'] == null) return "08:00";
      return data['scheduled_time']
          .toString()
          .replaceAll('أ', '')
          .replaceAll('م', '')
          .trim();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "عرض التذكرة",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: widget.onBack, // تعديل للوصول للـ Callback من الـ State
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // كرت الشركة
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // عرض اسم الشركة الحقيقي المجلوب من داتابيز اللارافيل ديناميكياً
                    Text(
                      data != null
                          ? data['company_name'].toString()
                          : "السراج للسياحة والسفر",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
              ),
              const SizedBox(height: 15),
              // تفاصيل التذكرة
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // تمرير بيانات المدن الحقيقية للدالة الفرعية للراوت
                    _buildRouteSection(
                      data != null ? data['from_city'].toString() : "درعا",
                      data != null ? data['to_city'].toString() : "دمشق",
                    ),
                    const Divider(height: 30),

                    // توليد وعرض ركاب التذكرة بشكل ديناميكي (Loop) بناءً على جدول booking_seats الحقيقي
                    if (passengers.isNotEmpty)
                      ...passengers.asMap().entries.map((entry) {
                        int index = entry.key;
                        var passenger = entry.value;
                        return _buildPassengerInfo(
                          "اسم الراكب رقم ${index + 1}",
                          passenger['passenger_name'].toString(),
                          passenger['seat_number'].toString(),
                          // توليد رقم تذكرة فرعي احترافي بناءً على الرقم المرجعي وآيدي المقعد
                          "${data['reference_number']}_${passenger['seat_number']}",
                        );
                      })
                    else
                      // في حال عدم وجود ركاب (حالة احتياطية افتراضية)
                      _buildPassengerInfo(
                        "اسم الراكب",
                        "لا يوجد ركاب مسجلين",
                        "0",
                        "0000",
                      ),

                    const Divider(),
                    // ربط التاريخ والوقت والتكلفة والرقم المرجعي الفعلي بالبيانات القادمة من السيرفر
                    _buildInfoRow(
                      "التاريخ",
                      data != null
                          ? data['travel_date'].toString()
                          : "mm/dd/yyyy",
                    ),
                    _buildInfoRow(
                      "الوقت",
                      getCleanTime(),
                    ), // 🌟 تم تمرير الوقت النظيف هنا لحل مشكلة حرف أ
                    const Divider(),
                    _buildInfoRow(
                      "تكلفة الحجز كاملة",
                      data != null ? "${data['total_price']} ل.س" : "0 ل.س",
                      isPrice: true,
                    ),
                    _buildInfoRow(
                      "رقم الحجز المرجعي",
                      data != null
                          ? data['reference_number'].toString()
                          : "REF_8776764",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // الـ Widgets المساعدة (نفس اللي كانت عندك مع جعل خط السير يستقبل بارامترات ديناميكية)
  Widget _buildRouteSection(String fromCity, String toCity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Text(fromCity, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          // 🌟 تم تعديل لون خلفية مدة الرحلة لتصبح كحلي بدلاً من الأخضر القديم ليتناسب مع الواجهة
          decoration: BoxDecoration(
            color: primaryDarkBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            "مدة الرحلة: 2 ساعات",
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        Column(
          children: [
            Text(toCity, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildPassengerInfo(
    String label,
    String name,
    String seat,
    String ticket,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              // 🌟 تم تعديل لون نص رقم المقعد ليصبح كحلي فخم بدلاً من الأخضر القديم
              Text(
                "رقم المقعد: $seat",
                style: TextStyle(
                  color: primaryDarkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            "رقم التذكرة: $ticket",
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          // 🌟 تم تعديل لون عرض السعر ليصبح كحلي متناسق مع التطبيق بدلاً من الأخضر القديم
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPrice ? primaryDarkBlue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
