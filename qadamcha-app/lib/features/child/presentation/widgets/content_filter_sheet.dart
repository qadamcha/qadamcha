import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Kontent filtrlash bottom sheet
class ContentFilterSheet extends StatefulWidget {
  final String? selectedLanguage;
  final int? selectedAge;
  final void Function(String? language, int? age) onApply;

  const ContentFilterSheet({
    super.key,
    this.selectedLanguage,
    this.selectedAge,
    required this.onApply,
  });

  @override
  State<ContentFilterSheet> createState() => _ContentFilterSheetState();
}

class _ContentFilterSheetState extends State<ContentFilterSheet> {
  late String? _tmpLanguage;
  late int? _tmpAge;

  static const _languages = ["O'zbek tili", 'Rus tili', 'Ingliz tili'];
  static const _languageEmojis = {
    "O'zbek tili": '🇺🇿',
    'Rus tili': '🇷🇺',
    'Ingliz tili': '🇬🇧',
  };
  static const _ageGroups = ['3-5', '6-8', '9-12', '13+'];

  @override
  void initState() {
    super.initState();
    _tmpLanguage = widget.selectedLanguage;
    _tmpAge = widget.selectedAge;
  }

  static int parseAge(String g) {
    switch (g) {
      case '3-5': return 4;
      case '6-8': return 7;
      case '9-12': return 10;
      case '13+': return 13;
      default: return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(children: [
            Text(
              'Filtr',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F0F0F),
              ),
            ),
            const Spacer(),
            if (_tmpLanguage != null || _tmpAge != null)
              GestureDetector(
                onTap: () => setState(() {
                  _tmpLanguage = null;
                  _tmpAge = null;
                }),
                child: Text(
                  'Tozalash',
                  style: TextStyle(fontSize: 13.sp, color: const Color(0xFF43A047)),
                ),
              ),
          ]),
          SizedBox(height: 16.h),
          Text('Til', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _languages.map((l) {
              final s = _tmpLanguage == l;
              return GestureDetector(
                onTap: () => setState(() => _tmpLanguage = s ? null : l),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: s ? const Color(0xFF43A047) : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${_languageEmojis[l] ?? ''} $l',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: s ? Colors.white : const Color(0xFF0F0F0F),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
          Text('Yosh', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _ageGroups.map((g) {
              final v = parseAge(g);
              final s = _tmpAge == v;
              return GestureDetector(
                onTap: () => setState(() => _tmpAge = s ? null : v),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: s ? const Color(0xFF43A047) : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$g yosh',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: s ? Colors.white : const Color(0xFF0F0F0F),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_tmpLanguage, _tmpAge);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                elevation: 0,
              ),
              child: Text(
                'Qo\'llash',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
