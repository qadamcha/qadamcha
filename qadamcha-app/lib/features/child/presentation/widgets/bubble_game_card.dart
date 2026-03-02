import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// YouTube Kids 1:1 — O'yin kartochkasi (Explore tab stili)
/// Flat pastel fon, katta ikonka, toza matn
class BubbleGameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const BubbleGameCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Katta emoji
            Text(emoji, style: TextStyle(fontSize: 40.sp)),
            SizedBox(height: 10.h),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F0F0F),
              ),
            ),
            SizedBox(height: 2.h),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF606060),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
