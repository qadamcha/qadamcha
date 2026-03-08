import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/local_monitoring_service.dart';

/// Ertak tafsilotlari sahifasi
/// Tepada orqaga qaytish tugmasi + ertak nomi
/// Pastda ertak matni (scrollable)
class StoryDetailPage extends StatefulWidget {
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

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  @override
  void initState() {
    super.initState();
    // Ertak ochilganda — counterni oshirish va activity log qo'shish
    LocalMonitoringService.instance.addStoryRead();
    LocalMonitoringService.instance.addActivityLog(
      activityType: 'story_read',
      contentTitle: widget.title,
      durationMinutes: 1,
    );
  }

  // Delegated getters from widget
  String get title => widget.title;
  String get storyText => widget.storyText;
  String get type => widget.type;
  String get language => widget.language;

  IconData get _typeIcon {
    switch (type) {
      case 'jahon':
        return Icons.public_rounded;
      case 'ozbek':
        return Icons.flag_rounded;
      case 'islomiy':
        return Icons.auto_stories_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color get _typeColor {
    switch (type) {
      case 'jahon':
        return AppColors.primary;
      case 'ozbek':
        return AppColors.primaryDark;
      case 'islomiy':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.primary;
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
        return "O'zbek";
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return "O'zbek";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
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
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
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
                        Row(
                          children: [
                            Icon(_typeIcon, size: 20.sp, color: _typeColor),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          ],
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
                                color: _typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                _typeLabel,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _typeColor,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.translate_rounded, size: 12.sp, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
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
                      color: AppColors.primary.withOpacity(0.08),
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
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _typeIcon,
                              size: 28.sp,
                              color: Colors.white,
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
                            fontSize: 24.sp,
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
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Ertak matni
                      Text(
                        storyText,
                        style: TextStyle(
                          fontSize: 18.sp,
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
                            color: AppColors.primary.withOpacity(0.3),
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
