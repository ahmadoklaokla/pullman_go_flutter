import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'company_selection_screen.dart';
import 'my_trips_screen.dart';
import 'notification_service.dart'; // لتشغيل الرادار
import 'notifications_screen.dart';
import 'offers_screen.dart';
import 'profile_screen.dart';

// --- موديل المدينة (City Model) ---
class City {
  final int id;
  final String name;
  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(id: json['id'], name: json['name']);
  }
}

class PullmanMainScreen extends StatefulWidget {
  const PullmanMainScreen({super.key});

  @override
  _PullmanMainScreenState createState() => _PullmanMainScreenState();
}

class _PullmanMainScreenState extends State<PullmanMainScreen> {
  int _pageIndex = 3;
  String userName =
      "جاري التحميل..."; // المتغير المخصص لحفظ الاسم وعرضه في الـ AppBar
  String userToken = "";

  @override
  void initState() {
    super.initState();
    _loadUserName(); // تشغيل دالة القراءة فوراً عند فتح الشاشة
    String userToken = ""; // ضعه هنا في الأعلى خارج الدوال
    // تشغيل رادار الإشعارات بمجرد فتح الصفحة الرئيسية
    NotificationService.instance.initializeFCM();
  }

  // الدالة التي تذهب لذاكرة الهاتف وتجلب الاسم الحقيقي
  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "المسافر";
      userToken = prefs.getString('user_token') ?? "";
    });
  }

  // 🎨 فلسفة تدرج الكحلي المنساب (Monochromatic Navy Gradient Core) - تم تغميقها درجة واحدة بدقة
  final Color primaryNavy = const Color(
    0xFF050E1A,
  ); // الكحلي الغامق جداً (بداية التدرج من الأعلى)
  final Color accentIceBlue = const Color(
    0xFF162D4A,
  ); // 👈 آخر درجة في التدرج (لون الأزرار والرموز النشطة متطابق تماماً)
  final Color lightGreyBackground = const Color(
    0xFFF4F6F9,
  ); // خلفية التطبيق رمادي ناعم

  final Color darkGrey = Colors.grey[600]!;

  String _getAppBarTitle() {
    switch (_pageIndex) {
      case 0:
        return "ملفي الشخصي";
      case 1:
        return "رحلاتي";
      case 2:
        return "أفضل العروض الحصرية";
      case 3:
        return "إلى أين ستسافر اليوم؟";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGreyBackground,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                //لرفع البرداية
                expandedHeight: 180.0,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leadingWidth: 200,
                leading: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 👤 الصورة الشخصية مع النقطة الخضراء (متصل)
                      InkWell(
                        onTap: () => setState(() => _pageIndex = 0),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.6),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: primaryNavy.withOpacity(0.6),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            // 🟢 النقطة الخضراء الذكية (بإضاءة وحواف بيضاء)
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ), // اللون الأخضر الحيوي
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryNavy,
                                    width: 2,
                                  ), // حواف تفصل النقطة عن الخلفية
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 💬 نصوص الترحيب والاسم بترتيب أرقى
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "مرحباً بعودتك",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.waving_hand,
                                color: Colors.amber[400],
                                size: 12,
                              ), // حركة ترحيبية لطيفة
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            //   هون اسم المستخدم
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900, // خط عريض وفخم
                              fontSize: 15,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: ValueListenableBuilder<int>(
                      valueListenable: NotificationService.instance.unreadCount,
                      builder: (context, count, child) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                              size: 28,
                            ),
                            if (count > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  //  لرفع جملة الى اين ستسافر اليوم
                  titlePadding: const EdgeInsets.only(bottom: 40),
                  title: Text(
                    _getAppBarTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      // تطبيق التدرج الكحلي الذكي المعدل من الأغمق للأفتح عند الحافة السفلية
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryNavy, // اغمق شي فوق
                          accentIceBlue, // الدرجة المعدلة تحت (وهي نفس لون زر البحث تماماً)
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(80.0),
                        bottomRight: Radius.circular(80.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryNavy.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: _buildBody(),
        ),
        bottomNavigationBar: _buildCorrectedBottomNav(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_pageIndex) {
      case 0:
        //  نمرر الدالة عشان لما ينحفظ الاسم بالبروفايل، تتحدث الرئيسية فوراً
        return ProfileScreen(
          onNameUpdated: (newName) {
            setState(() {
              userName = newName;
            });
          },
        );
      case 1:
        return const MyTripsScreen();
      case 2:
        return OffersScreen(
          token: userToken,
        ); // 👈 عدلها لـ userToken وبيروح الخطأ فوراً
      case 3:
        return _buildHomeScreenContent();
      default:
        return _buildHomeScreenContent();
    }
  }

  Widget _buildHomeScreenContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          BusSearchForm(
            primaryColor: primaryNavy,
            accentColor: accentIceBlue,
            token: userToken,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCorrectedBottomNav() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CurvedNavigationBar(
          index: _pageIndex == 3
              ? 0
              : (_pageIndex == 2 ? 1 : (_pageIndex == 1 ? 2 : 3)),
          height: 70.0,
          items: [
            Icon(
              Icons.home,
              size: 30,
              color: _pageIndex == 3 ? accentIceBlue : darkGrey,
            ),
            Icon(
              Icons.local_offer,
              size: 30,
              color: _pageIndex == 2 ? accentIceBlue : darkGrey,
            ),
            Icon(
              Icons.directions_bus,
              size: 30,
              color: _pageIndex == 1 ? accentIceBlue : darkGrey,
            ),
            Icon(
              Icons.person,
              size: 30,
              color: _pageIndex == 0 ? accentIceBlue : darkGrey,
            ),
          ],
          color: const Color(0xFFEAEDF2),
          buttonBackgroundColor:
              primaryNavy, // الدائرة تندمج باللون الكحلي العلوي المعدل
          backgroundColor: Colors.transparent,
          onTap: (index) {
            setState(() {
              if (index == 0) _pageIndex = 3;
              if (index == 1) _pageIndex = 2;
              if (index == 2) _pageIndex = 1;
              if (index == 3) _pageIndex = 0;
            });
          },
        ),
        Positioned(
          bottom: 5,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLabel("الرئيسية", 3),
              _buildLabel("العروض", 2),
              _buildLabel("رحلاتي", 1),
              _buildLabel("حسابي", 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, int index) => Container(
    width: 80,
    alignment: Alignment.center,
    child: Text(
      text,
      style: TextStyle(
        color: _pageIndex == index ? accentIceBlue : darkGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class BusSearchForm extends StatefulWidget {
  final bool isMini;
  final Color? primaryColor;
  final Color? accentColor;
  final String token;

  const BusSearchForm({
    super.key,
    this.isMini = false,
    this.primaryColor,
    this.accentColor,
    required this.token,
  });
  @override
  State<BusSearchForm> createState() => _BusSearchFormState();
}

class _BusSearchFormState extends State<BusSearchForm> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  List<City> _allCities = [];
  bool _isFetching = true;
  int? _selectedFromId;
  int? _selectedToId;

  DateTime? _selectedDate;
  String? _fromError, _toError, _dateError;
  bool _isLoading = false;

  late Color localPrimary;
  late Color localAccent;

  @override
  void initState() {
    super.initState();
    localPrimary = widget.primaryColor ?? const Color(0xFF050E1A);
    localAccent = widget.accentColor ?? const Color(0xFF162D4A);
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    try {
      final response = await Dio().get('${ApiService.baseUrl}/cities');
      if (response.statusCode == 200) {
        List data = response.data['data'];
        setState(() {
          _allCities = data.map((json) => City.fromJson(json)).toList();
          _isFetching = false;
        });
      }
    } catch (e) {
      print("خطأ في جلب المدن: $e");
      setState(() => _isFetching = false);
    }
  }

  String _getDayName(DateTime date) {
    List<String> days = [
      "الأحد",
      "الاثنين",
      "الثلاثاء",
      "الأربعاء",
      "الخميس",
      "الجمعة",
      "السبت",
    ];
    return days[date.weekday % 7];
  }

  void _validateAndSearch() async {
    setState(() {
      _fromError = (_fromController.text.isEmpty || _selectedFromId == null)
          ? "الرجاء تحديد مدينة الانطلاق"
          : null;
      _toError = (_toController.text.isEmpty || _selectedToId == null)
          ? "الرجاء تحديد مدينة الوصول"
          : null;
      if (!widget.isMini)
        _dateError = _selectedDate == null ? "الرجاء تحديد التاريخ" : null;
    });

    if (_fromError == null &&
        _toError == null &&
        (_dateError == null || widget.isMini)) {
      setState(() => _isLoading = true);

      if (mounted) {
        String formattedDate = _selectedDate != null
            ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
            : "لم يحدد";
        int dayIndex = _selectedDate != null
            ? (_selectedDate!.weekday % 7)
            : -1;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompanySelectionScreen(
              fromCity: _fromController.text,
              fromCityId: _selectedFromId!,
              toCity: _toController.text,
              toCityId: _selectedToId!,

              selectedDate: formattedDate,
              dayIndex: dayIndex,
              token: widget.token,
            ),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: localPrimary),
        ),
      );
    }

    return Container(
      padding: widget.isMini ? EdgeInsets.zero : const EdgeInsets.all(20),
      decoration: widget.isMini
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: localPrimary.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            "من مدينة",
            "بحث عن مدينة الانطلاق",
            _fromController,
            _fromError,
            _selectedToId,
            (id) => _selectedFromId = id,
          ),
          const SizedBox(height: 15),
          _buildField(
            "إلى مدينة",
            "بحث عن مدينة الوصول",
            _toController,
            _toError,
            _selectedFromId,
            (id) => _selectedToId = id,
          ),
          const SizedBox(height: 15),
          if (!widget.isMini) _buildDatePicker(),
          const SizedBox(height: 20),
          _buildSearchBtn(),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController mainCtrl,
    String? error,
    int? excludedId,
    Function(int) onSelected,
  ) {
    List<City> filtered = _allCities.where((c) => c.id != excludedId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Autocomplete<City>(
          displayStringForOption: (City c) => c.name,
          optionsBuilder: (val) => val.text.isEmpty
              ? filtered
              : filtered.where((c) => c.name.contains(val.text)),
          onSelected: (City c) {
            setState(() {
              mainCtrl.text = c.name;
              onSelected(c.id);
              _fromError = null;
              _toError = null;
            });
          },
          fieldViewBuilder: (ctx, ctrl, focus, onSub) {
            if (mainCtrl.text != ctrl.text) ctrl.text = mainCtrl.text;
            return TextField(
              controller: ctrl,
              focusNode: focus,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                errorText: error,
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Colors.grey,
                  size: 20,
                ),
                suffixIcon: PopupMenuButton<City>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (City c) {
                    ctrl.text = c.name;
                    setState(() {
                      mainCtrl.text = c.name;
                      onSelected(c.id);
                      _fromError = null;
                      _toError = null;
                    });
                  },
                  itemBuilder: (ctx) => filtered
                      .map(
                        (c) => PopupMenuItem(
                          value: c,
                          child: Text(c.name, textDirection: TextDirection.rtl),
                        ),
                      )
                      .toList(),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: localPrimary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "التاريخ",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            DateTime? p = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2027),
            );
            if (p != null)
              setState(() {
                _selectedDate = p;
                _dateError = null;
              });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _dateError != null
                    ? Colors.red
                    : (_selectedDate != null
                          ? localPrimary
                          : Colors.grey[300]!),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? "اختر التاريخ"
                      : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                ),
                Icon(
                  Icons.calendar_month,
                  color: _selectedDate != null ? localPrimary : Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_selectedDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: Row(
              children: [
                Icon(Icons.event_available, size: 16, color: localAccent),
                const SizedBox(width: 5),
                Text(
                  "يصادف يوم: ${_getDayName(_selectedDate!)}",
                  style: TextStyle(
                    color: localAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (_dateError != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              _dateError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? () {} : _validateAndSearch,
        // تلوين الزر ليتطابق بالكامل مع آخر درجة بالتدرج العلوي (accentIceBlue)
        style: ElevatedButton.styleFrom(
          backgroundColor: localAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "بحث",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
