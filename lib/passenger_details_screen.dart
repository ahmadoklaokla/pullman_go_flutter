import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'payment_gateway_screen.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final List<int> selectedSeats;
  final String? busNumber;
  final String? fromCity;
  final String? toCity;
  final int? tripId;
  final int? userId;
  final String? travelDate;
  final int pricePerSeat;
  final String token;

  const PassengerDetailsScreen({
    super.key,
    required this.selectedSeats,
    required this.pricePerSeat,
    this.tripId,
    this.userId,
    this.travelDate,
    this.busNumber,
    required this.token,
    this.fromCity,
    this.toCity,
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  // 🎨 تحويل الألوان إلى static const لمنع مشكلة undefined (withOpacity) في الويب تماماً
  static const Color primaryNavy = Color(0xFF050E1A);
  static const Color accentIceBlue = Color(0xFF162D4A);
  static const Color backgroundColor = Color(0xFFF4F6F9);

  final TextEditingController phoneController = TextEditingController();
  final List<TextEditingController> nameControllers = [];
  final ScrollController _scrollController = ScrollController();

  bool _isScrolled = false;

  String get safeBusNumber =>
      (widget.busNumber != null && widget.busNumber!.isNotEmpty)
      ? widget.busNumber!
      : "غير محدد";
  String get safeFromCity => widget.fromCity ?? "غير متوفر";
  String get safeToCity => widget.toCity ?? "غير متوفر";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 20 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 20 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    for (int i = 0; i < widget.selectedSeats.length; i++) {
      nameControllers.add(TextEditingController());
    }
  }

  bool _isAllDataEntered() {
    bool areNamesEntered = nameControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
    return areNamesEntered;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    phoneController.dispose();
    for (var controller in nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateToPaymentScreen(BuildContext modalContext) {
    Navigator.pop(modalContext);

    List<Map<String, dynamic>> passengerList = [];
    for (int i = 0; i < widget.selectedSeats.length; i++) {
      passengerList.add({
        "seat_number": widget.selectedSeats[i],
        "passenger_name": nameControllers[i].text.trim(),
      });
    }

    int seatCount = widget.selectedSeats.length;
    int totalPrice = seatCount * widget.pricePerSeat;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewayScreen(
          totalAmount: totalPrice,
          passengerList: passengerList,
          tripId: widget.tripId ?? 0,
          userId: widget.userId ?? 0,
          travelDate: widget.travelDate ?? "",
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 110.0,
                floating: false,
                pinned: true,
                elevation: _isScrolled ? 0.5 : 0,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: primaryNavy,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                centerTitle: true,
                title: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: const TextStyle(
                    color: primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  child: const Text("بيانات المسافرين"),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(
                      top: 80,
                      right: 20,
                      left: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_bus_outlined,
                              color: accentIceBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "من $safeFromCity إلى $safeToCity",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: primaryNavy,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "باص رقم: $safeBusNumber  •  ${widget.selectedSeats.length} مقاعد",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  Icons.contact_phone_outlined,
                  "معلومات الاتصال (لصاحب الحساب)",
                ),
                const SizedBox(height: 15),
                _buildNewPhoneField(),
                const SizedBox(height: 35),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        endIndent: 10,
                        thickness: 1,
                        color: Color(0xFFEAEDF2),
                      ),
                    ),
                    Text(
                      "تفاصيل الركاب والمقاعد",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryNavy.withOpacity(0.7),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        indent: 10,
                        thickness: 1,
                        color: Color(0xFFEAEDF2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                ...widget.selectedSeats.asMap().entries.map((entry) {
                  int index = entry.key;
                  int seatNum = entry.value;
                  return _buildPassengerCard(index, seatNum);
                }).toList(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildConfirmButton(),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: accentIceBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: primaryNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildNewPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: phoneController,
                onChanged: (val) => setState(() {}),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                  FilteringTextInputFormatter.deny(RegExp(r'^0')),
                ],
                style: const TextStyle(
                  fontSize: 15,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                  color: primaryNavy,
                ),
                decoration: const InputDecoration(
                  hintText: "9xxxxxxxxx",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 22, color: Colors.grey.withOpacity(0.3)),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "+963",
                  style: TextStyle(
                    color: primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.phone_android_rounded,
                  color: accentIceBlue.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(int index, int seatNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: accentIceBlue,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "الراكب ${index + 1}",
                          style: const TextStyle(
                            color: primaryNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        _buildSeatBadge(seatNumber),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameControllers[index],
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(fontSize: 14, color: primaryNavy),
                      decoration: InputDecoration(
                        hintText: "الاسم الثلاثي المكتوب في الهوية",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: accentIceBlue.withOpacity(0.7),
                          size: 18,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatBadge(int seatNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentIceBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.airline_seat_recline_normal_outlined,
            size: 14,
            color: accentIceBlue,
          ),
          const SizedBox(width: 4),
          Text(
            "مقعد ${seatNumber.toString().padLeft(2, '0')}",
            style: const TextStyle(
              color: accentIceBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _isAllDataEntered()
            ? () => _showBookingSummary(context)
            : null,
        icon: Icon(
          Icons.check_circle_outline,
          color: _isAllDataEntered() ? Colors.white : Colors.grey[500],
          size: 18,
        ),
        label: Text(
          "تأكيد وحفظ البيانات",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isAllDataEntered() ? Colors.white : Colors.grey[500],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentIceBlue,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: _isAllDataEntered() ? 2 : 0,
        ),
      ),
    );
  }

  void _showBookingSummary(BuildContext context) {
    int seatCount = widget.selectedSeats.length;
    int totalPrice = seatCount * widget.pricePerSeat;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 35,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ملخص وتأكيد الحجز",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAEDF2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_activity_outlined,
                      color: accentIceBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "من $safeFromCity إلى $safeToCity",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryNavy,
                        ),
                      ),
                    ),
                    Text(
                      "باص $safeBusNumber",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _row("سعر التذكرة الواحدة", "${widget.pricePerSeat} ل.س", false),
              _row("عدد المقاعد المحجوزة", "$seatCount", false),
              const Divider(height: 25, thickness: 1, color: Color(0xFFEAEDF2)),
              _row("إجمالي تكلفة الحجز", "$totalPrice ل.س", true),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _navigateToPaymentScreen(modalContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentIceBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                        elevation: 0,
                      ),
                      child: const Text(
                        "متابعة للدفع",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(modalContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Text(
                        "مراجعة",
                        style: TextStyle(
                          color: primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? accentIceBlue : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? accentIceBlue : primaryNavy,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
