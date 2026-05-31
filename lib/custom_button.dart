import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

//  هاد الملف مشان حركة كل الازرار الي بالتطبيق وبقدر اتحكم بلونها كمان بشكل موحد وكمان متغير الحالة يعني ايقونة بحث في اي زر يتطلب البحث والتحقق
class MyMainButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool
  isLoading; //مشان تختفي جملة انشاء حساب جديد ويصير بدالها ايقونة بحث1.

  const MyMainButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false, // 2. خليناه "خطأ" كقيمة افتراضية
  });

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      // إذا كان في حالة تحميل، بنوقف الضغط على الزر3.
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          ////////////////*****************
          color: const Color(0xFF162D4A), // لونك الأخضر الموحد
          ///////////////////*****************
          borderRadius: BorderRadius.circular(35),
        ),
        child: Center(
          // 4. هون السحر:   إذا isLoading  صح، بنعرض أيقونة بتفتل، وإلا بنعرض النص
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
