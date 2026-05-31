import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'seat_selection_screen.dart';

class OfferModel {
  final String company, from, to, oldPrice, newPrice, duration;
  final String token;

  OfferModel({
    required this.company,
    required this.from,
    required this.to,
    required this.oldPrice,
    required this.newPrice,
    required this.duration,
    required this.token,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    // جلب السعر القديم والجديد بناءً على الرد الجديد من الـ Controller
    var originalPrice = json['old_price'] ?? '0';
    var discountedPrice = json['offer_price'] ?? '0';

    // التعديل: التخلص من الفاصلة العشرية والأصفار الزائدة إن وجدت (.00)
    String formattedOldPrice = originalPrice.toString().split('.')[0];
    String formattedNewPrice = discountedPrice.toString().split('.')[0];

    return OfferModel(
      company: json['company']?['name'] ?? 'شركة السراج',
      from: json['route']?['departure_city']?['name'] ?? 'غير محدد',
      to: json['route']?['arrival_city']?['name'] ?? 'غير محدد',
      oldPrice: "$formattedOldPrice ل.س",
      newPrice: "$formattedNewPrice ل.س",
      duration: "من ${json['start_date']} إلى ${json['end_date']}",
      token: json['token'] ?? '',
    );
  }
}

class OffersScreen extends StatefulWidget {
  final String token; // 👈 هاد السطر يلي انضاف هون

  // 👈 وعدلنا الـ Constructor ليصير يطلب الـ token بشكل إجباري
  const OffersScreen({super.key, required this.token});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  Future<List<OfferModel>> fetchOffers() async {
    // ملاحظة: localhost للتشغيل على المتصفح
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
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.redAccent, size: 14),
                          SizedBox(width: 2),
                          Text(
                            "عرض خاص",
                            style: TextStyle(
                              color: Colors.redAccent,
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
                            color: Colors.black87,
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeatSelectionScreen(
                          fromCity: offer.from,
                          toCity: offer.to,
                          selectedDate: "اختر يوم العرض",
                          tripTime: "حسب التوفر",
                          companyName: offer.company,
                          tripRoute: "${offer.from} ← ${offer.to}",
                          token: widget.token,
                        ),
                      ),
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
