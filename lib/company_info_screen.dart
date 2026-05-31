import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'booking_trips_screen.dart';

class CompanyInfoScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final String fromCity;
  final String toCity;
  final String token;
  final String selectedDate;
  final bool isInitiallyFavorite;
  final VoidCallback onFavoriteToggle;

  const CompanyInfoScreen({
    super.key,
    required this.company,
    required this.fromCity,
    required this.toCity,
    required this.selectedDate,
    required this.isInitiallyFavorite,
    required this.onFavoriteToggle,
    required this.token,
  });

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  late bool isFavorite;

  // 🎨 الهوية اللونية الفخمة المعتمدة والموحدة للتطبيق
  final Color primaryNavy = const Color(0xFF050E1A); // الكحلي الغامق الفخم
  final Color accentIceBlue = const Color(
    0xFF162D4A,
  ); // لون الأزرار والبادجات الموحد (زر البحث)
  final Color lightGreyBackground = const Color(
    0xFFF4F6F9,
  ); // الخلفية المريحة للتطبيق

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isInitiallyFavorite;
  }

  // دالة فتح الروابط الخارجية (تصميمك الأصلي)
  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty || urlString == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("عذراً، الرابط غير متوفر لهذه الشركة")),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تعذر فتح الرابط، تأكد من صحة التنسيق")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> featuresList = [];
    var rawFeatures = widget.company['features'];

    if (rawFeatures != null) {
      if (rawFeatures is String) {
        try {
          featuresList = jsonDecode(rawFeatures);
        } catch (e) {
          featuresList = [rawFeatures];
        }
      } else if (rawFeatures is List) {
        featuresList = rawFeatures;
      }
    }

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
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? accentIceBlue
                      : Colors.black54, // تحديث لون المفضلة النشطة
                  size: 22,
                ),
                onPressed: () {
                  setState(() => isFavorite = !isFavorite);
                  widget.onFavoriteToggle();
                },
              ),
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentIceBlue.withOpacity(0.12),
                          Colors.white,
                        ], // التدرج العلوي الكحلي الانسيابي
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(80),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 90,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryNavy.withOpacity(0.08),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            (widget.company['logo_url'] != null &&
                                widget.company['logo_url']
                                    .toString()
                                    .isNotEmpty)
                            ? NetworkImage(
                                // شلنا الـ /api لأن مجلد الـ storage ببروجكت اللارافيل بكون برا الـ api
                                "${ApiService.baseUrl.replaceAll('/api', '')}/storage/${widget.company['logo_url']}",
                              )
                            : const AssetImage('assets/images/logo.png')
                                  as ImageProvider,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                widget.company['name'] ?? "اسم الشركة غير متوفر",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: primaryNavy,
                ), // ربط الاسم باللون الرئيسي للفخامة
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.company['slogan'] != null
                      ? "\"${widget.company['slogan']}\""
                      : "لا يوجد شعار متاح لهذه الشركة",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              if (featuresList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: featuresList
                        .map((feature) => _buildBadge(feature.toString()))
                        .toList(),
                  ),
                )
              else
                const Text(
                  "لا توجد ميزات إضافية مسجلة حالياً",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildModernTile(
                      icon: Icons.phone_android_rounded,
                      title: "رقم التواصل",
                      value: widget.company['phone'] ?? 'غير متوفر',
                    ),
                    const SizedBox(height: 12),
                    _buildModernTile(
                      icon: Icons.location_on_rounded,
                      title: "الموقع الرئيسي",
                      value: widget.company['address'] ?? 'غير محدد',
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _launchURL(widget.company['location_url']),
                      child: _buildModernTile(
                        icon: Icons.language_rounded,
                        title: "الموقع الإلكتروني",
                        value:
                            (widget.company['location_url'] != null &&
                                widget.company['location_url'] != 'null')
                            ? widget.company['location_url']
                            : 'غير متوفر',
                        isLink: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        accentIceBlue, // تلوين زر الحجز ليتطابق مع زر البحث تماماً
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 6,
                    shadowColor: accentIceBlue.withOpacity(0.3),
                  ),
                  onPressed: () {
                    try {
                      // 1. تنظيف وتأمين التاريخ بشكل قياسي
                      String searchDate = widget.selectedDate.trim();
                      try {
                        if (searchDate.contains('/')) {
                          List<String> dateParts = searchDate.split('/');
                          if (dateParts.length == 3) {
                            String day = dateParts[0].padLeft(2, '0');
                            String month = dateParts[1].padLeft(2, '0');
                            String year = dateParts[2];
                            searchDate = "$year-$month-$day";
                          }
                        }
                      } catch (e) {
                        print("Date optimization error: $e");
                      }

                      // 2. حساب الـ dayIndex للأمان
                      DateTime date;
                      if (searchDate.contains('-')) {
                        date = DateTime.parse(searchDate);
                      } else {
                        List<String> parts = searchDate.split(RegExp(r'[/-]'));
                        date = DateTime(
                          int.parse(parts[2]),
                          int.parse(parts[1]),
                          int.parse(parts[0]),
                        );
                      }
                      int dayIndex = date.weekday % 7;

                      // 3. الحل الجوهري: استخراج المعرفات بشكل آمن تماماً سواء جاءت int أو String
                      final int? companyId = widget.company['id'] is int
                          ? widget.company['id']
                          : int.tryParse(
                              widget.company['id']?.toString() ?? '',
                            );

                      final int? routeId = widget.company['route_id'] is int
                          ? widget.company['route_id']
                          : int.tryParse(
                              widget.company['route_id']?.toString() ?? '',
                            );

                      // 4. الانتقال للشاشة التالية باللوغو الكامل والمحمي
                      String finalLogo = 'assets/images/logo.png';
                      if (widget.company['logo_url'] != null &&
                          widget.company['logo_url'].toString().isNotEmpty) {
                        finalLogo =
                            "${ApiService.baseUrl.replaceAll('/api', '')}/storage/${widget.company['logo_url']}";
                      }

                      // 4. الانتقال للشاشة التالية بالتاريخ الجاهز والمحمي
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingTripsScreen(
                            companyId: companyId,
                            routeId: routeId,
                            companyName: widget.company['name'] ?? 'اسم الشركة',
                            logo: finalLogo,
                            fromCity: widget.fromCity,
                            toCity: widget.toCity,
                            selectedDate:
                                searchDate, // 👈 تمرير التاريخ النظيف الموحد
                            dayIndex: dayIndex,
                            token: widget.token,
                          ),
                        ),
                      );
                    } catch (e) {
                      print("Error during navigation: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("حدث خطأ في معالجة البيانات: $e"),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "احجز رحلتك الآن",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- ويدجت الميزات بالتناسق الكحلي الجديد ---
  Widget _buildBadge(String label) {
    Map<String, String> translation = {
      'comfortable_seats': 'مقاعد مريحة',
      'comfortable seats': 'مقاعد مريحة',
      'water': 'توزيع مياه',
      'snacks': 'ضيافة خفيفة',
      'wifi': 'واي فاي مجاني',
      'air_conditioning': 'تكييف مركزي',
      'screen': 'شاشات عرض',
      'gps': 'تتبع الرحلة',
      'insurance': 'تأمين سفر',
    };

    String translatedText = translation[label.toLowerCase()] ?? label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentIceBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: accentIceBlue.withOpacity(0.03), blurRadius: 5),
        ],
      ),
      child: Text(
        translatedText,
        style: TextStyle(
          color: accentIceBlue,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- ويدجت المعلومات بالتناسق الكحلي الجديد ---
  Widget _buildModernTile({
    required IconData icon,
    required String title,
    required String value,
    bool isLink = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentIceBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentIceBlue, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isLink ? Colors.blue : const Color(0xFF2D3436),
                    decoration: isLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
