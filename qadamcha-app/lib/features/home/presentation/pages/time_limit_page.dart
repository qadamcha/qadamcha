import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/role_selection_page.dart';

/// Vaqt limiti tugadi sahifasi
/// Bola menuda vaqt limiti o'tganda ko'rsatiladi
class TimeLimitPage extends StatelessWidget {
  const TimeLimitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.sunsetGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Icon
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('⏰', style: TextStyle(fontSize: 52.sp)),
                  ),
                ),
                SizedBox(height: 28.h),

                // Title
                Text(
                  'Bugungi vaqt limiti tugadi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 12.h),

                // Subtitle
                Text(
                  'Bugun uchun ajratilgan vaqt tugadi.\nErtaga yana o\'ynashingiz mumkin! 🌟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'Nunito',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 36.h),

                // Info card
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(emoji: '📚', text: 'Kitob o\'qishingiz mumkin'),
                      SizedBox(height: 12.h),
                      _InfoRow(emoji: '🎨', text: 'Rasm chizishingiz mumkin'),
                      SizedBox(height: 12.h),
                      _InfoRow(emoji: '🏃', text: 'Tashqarida o\'ynashingiz mumkin'),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                    (route) => false,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Orqaga qaytish',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _InfoRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 18.sp)),
        SizedBox(width: 12.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
