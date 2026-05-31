import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'company_info_screen.dart';

// موديل الرحلة لجلب البيانات من جدول routes وشركته
class TravelRoute {
  final int id;
  final String companyName;

  final String? companyLogo;
  final String price;
  final String startTime;
  final Map<String, dynamic> fullCompanyData;

  TravelRoute({
    required this.id,
    required this.companyName,
    this.companyLogo,
    required this.price,
    required this.startTime,
    required this.fullCompanyData,
  });

  //رابط جلب لوغو الشركات
  factory TravelRoute.fromJson(Map<String, dynamic> json) {
    var companyJson = json['company'] ?? {};
    String? logoPath = companyJson['logo_url'];

    String? fullLogoUrl;
    if (logoPath != null && logoPath.isNotEmpty) {
      String fileName = logoPath.split(RegExp(r'[\\/]')).last;
      // شلنا الـ /api لأن مجلد الصور ببروجكت اللارافيل بكون برا الـ api
      String domain = ApiService.baseUrl.replaceAll('/api', '');
      fullLogoUrl = "$domain/companies-logos/$fileName";
    }

    // معالجة السعر للتخلص من الفواصل العشرية والأصفار الزائدة .00 بشكل آمن
    String formattedPrice = "0";
    if (json['base_price'] != null) {
      var rawPrice = json['base_price'];
      if (rawPrice is num) {
        formattedPrice = rawPrice.toInt().toString();
      } else {
        // في حال كان السعر قادم كنص يحتوي على فواصل مثل "250.00"
        double? parsedDouble = double.tryParse(rawPrice.toString());
        formattedPrice = parsedDouble != null
            ? parsedDouble.toInt().toString()
            : rawPrice.toString();
      }
    }

    return TravelRoute(
      id: json['id'],
      companyName: companyJson['name'] ?? "شركة غير معروفة",
      companyLogo: fullLogoUrl,
      price: formattedPrice, // السعر المعدل الخالي من الفواصل
      startTime: json['estimated_time'] ?? "غير محدد",
      fullCompanyData: companyJson,
    );
  }
}

class CompanySelectionScreen extends StatefulWidget {
  final String fromCity;
  final int fromCityId;
  final String toCity;
  final int toCityId;
  final String token;
  final String selectedDate;
  final int dayIndex; // --- التعديل: إضافة استقبال رقم اليوم ---

  const CompanySelectionScreen({
    super.key,
    required this.fromCity,
    required this.fromCityId,
    required this.toCity,
    required this.toCityId,
    required this.selectedDate,
    required this.token,
    required this.dayIndex, // --- التعديل: إضافة اليوم للمشيد ---
  });

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  bool showAll = true;

  // 🎨 الألوان المعتمدة الفخمة والمتناسقة مع الواجهة الرئيسية
  final Color primaryNavy = const Color(
    0xFF050E1A,
  ); // الكحلي الغامق الفخم (الأعلى)
  final Color accentIceBlue = const Color(
    0xFF162D4A,
  ); // كحلي الأزرار والـ Tabs النشطة (نفس لغة زر البحث)
  final Color lightGreyBackground = const Color(
    0xFFF4F6F9,
  ); // خلفية التطبيق الرمادية الناعمة الموحدة

  List<TravelRoute> _allRoutes = [];
  bool _isLoading = true;
  List<TravelRoute> favoriteRoutes = [];

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  //رابط جلب الرحلات (البحث)
  //رابط جلب الرحلات (البحث)
  Future<void> _fetchRoutes() async {
    // 1. استلام التاريخ من الشاشة السابقة
    String searchDate = widget.selectedDate.trim();

    // 2. سحر الأمان: تحويل التاريخ لصيغة الداتابيز القياسية
    try {
      if (searchDate.contains('/')) {
        List<String> dateParts = searchDate.split('/');
        if (dateParts.length == 3) {
          String day = dateParts[0].padLeft(2, '0');
          String month = dateParts[1].padLeft(2, '0');
          String year = dateParts[2];
          searchDate = "$year-$month-$day"; // النتيجة: 2026-05-28
        }
      }
    } catch (e) {
      print("Date parsing error: $e");
    }

    try {
      final response = await Dio().get(
        '${ApiService.baseUrl}/search-trips',
        queryParameters: {
          'from_id': widget.fromCityId,
          'to_id': widget.toCityId,
          'day_index': widget.dayIndex,
          'date': searchDate, // 👈  ضفنا التاريخ النظيف والمحمي للسيرفر
        },
      );

      if (response.statusCode == 200) {
        List data = response.data['data'] ?? [];
        setState(() {
          _allRoutes = data.map((json) => TravelRoute.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("خطأ في جلب الشركات: $e");
      setState(() => _isLoading = false);
    }
  }

  void toggleFavorite(TravelRoute route) {
    setState(() {
      if (favoriteRoutes.any((e) => e.id == route.id)) {
        favoriteRoutes.removeWhere((e) => e.id == route.id);
      } else {
        favoriteRoutes.add(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = showAll ? _allRoutes : favoriteRoutes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGreyBackground, // تطبيق الخلفية الناعمة المعتمدة
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: Text(
            "اختيار الشركة",
            style: TextStyle(
              color: primaryNavy,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: primaryNavy, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: primaryNavy),
              ) // مؤشر التحميل باللون الكحلي الفخم
            : Column(
                children: [
                  _buildPromoCard(),
                  _buildTabs(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: displayedList.isEmpty
                        ? Center(
                            child: Text(
                              showAll
                                  ? "لا يوجد رحلات متاحة لهذا المسار في هذا اليوم"
                                  : "قائمة المفضلة فارغة",
                              style: TextStyle(color: darkGrey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: displayedList.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) =>
                                _buildCompanyCard(displayedList[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // تدرج كحلي انسيابي ناعم يتوافق مع الهوية الجديدة
        gradient: LinearGradient(
          colors: [accentIceBlue.withOpacity(0.08), Colors.white],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentIceBlue.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          const Text(
            "انطلق في رحلتك القادمة الآن!",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "قارن بين أفضل شركات النقل واختر الأنسب لرحلتك من ${widget.fromCity} إلى ${widget.toCity}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "تاريخ الرحلة: ${widget.selectedDate}",
            style: TextStyle(color: accentIceBlue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEDF2),
        borderRadius: BorderRadius.circular(15),
      ), // متناسق مع لون خلفية القائمة السفلية
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showAll = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: showAll ? accentIceBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ), // متناسق مع زر البحث
                child: Center(
                  child: Text(
                    "جميع الشركات",
                    style: TextStyle(
                      color: showAll ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showAll = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !showAll ? accentIceBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "المفضلة",
                    style: TextStyle(
                      color: !showAll ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(TravelRoute route) {
    bool isFav = favoriteRoutes.any((e) => e.id == route.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Map<String, dynamic> companyToPass = Map.from(route.fullCompanyData);
          companyToPass['logo_url_full'] = route.companyLogo;
          companyToPass['route_id'] = route.id;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompanyInfoScreen(
                company: companyToPass,
                fromCity: widget.fromCity,
                toCity: widget.toCity,
                token: widget.token,
                selectedDate: widget.selectedDate,
                isInitiallyFavorite: isFav,
                onFavoriteToggle: () => toggleFavorite(route),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (route.companyLogo != null)
                    ? Image.network(
                        route.companyLogo!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.directions_bus_filled,
                          color: accentIceBlue,
                          size: 30,
                        ),
                      )
                    : Icon(
                        Icons.directions_bus_filled,
                        color: accentIceBlue,
                        size: 30,
                      ), // استبدال اللون الأخضر بـ accentIceBlue لتوحيد الهوية
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.companyName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryNavy,
                      ),
                    ),
                    Text(
                      "السعر: ${route.price} ل.س",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      "وقت الرحلة: ${route.startTime}",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تعريف لون الرموز غير النشطة بشكل جانبي لتفادي الأخطاء البنائية
  Color get darkGrey => Colors.grey[600]!;
}
