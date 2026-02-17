import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

/// Ertak tafsilotlari sahifasi
/// Tepada orqaga qaytish tugmasi + ertak nomi
/// Pastda ertak matni (scrollable)
class StoryDetailPage extends StatelessWidget {
  final String title;
  final String storyText;
  final String type;
  final String language;

  const StoryDetailPage({
    super.key,
    required this.title,
    required this.storyText,
    required this.type,
    required this.language,
  });

  String get _typeEmoji {
    switch (type) {
      case 'jahon':
        return '🌍';
      case 'ozbek':
        return '🇺🇿';
      case 'islomiy':
        return '☪️';
      default:
        return '📖';
    }
  }

  String get _typeLabel {
    switch (type) {
      case 'jahon':
        return 'Jahon';
      case 'ozbek':
        return "O'zbek";
      case 'islomiy':
        return 'Islomiy';
      default:
        return 'Ertak';
    }
  }

  String get _languageLabel {
    switch (language) {
      case 'uz':
        return "🇺🇿 O'zbek";
      case 'ru':
        return '🇷🇺 Русский';
      case 'en':
        return '🇬🇧 English';
      default:
        return "🇺🇿 O'zbek";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Orqaga qaytish tugmasi
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        gradient: AppColors.storiesGradient,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  // Ertak nomi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_typeEmoji $title',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                _typeLabel,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _languageLabel,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Story text ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(20.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.purple.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dekorativ bosh qismi
                      Center(
                        child: Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: BoxDecoration(
                            gradient: AppColors.storiesGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _typeEmoji,
                              style: TextStyle(fontSize: 28.sp),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Ertak nomi
                      Center(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Nunito',
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),

                      // Separator
                      Center(
                        child: Container(
                          width: 60.w,
                          height: 3.h,
                          decoration: BoxDecoration(
                            gradient: AppColors.storiesGradient,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Ertak matni
                      Text(
                        storyText,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textPrimary,
                          fontFamily: 'Nunito',
                          height: 1.8,
                          letterSpacing: 0.2,
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Tugash belgisi
                      Center(
                        child: Text(
                          '— ✦ —',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: AppColors.purple.withOpacity(0.3),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
