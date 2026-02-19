import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qadamcha_app/core/theme/app_colors.dart';
import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';

/// YouTube-style Video Card
/// Full-width thumbnail (16:9) + duration badge + title/meta info
class VideoCard extends StatelessWidget {
  final ContentEntity content;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== THUMBNAIL (16:9) =====
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            content.thumbnailUrl!,
                            fit: BoxFit.cover,
                            headers: const {'Referer': 'https://qadamcha.uz/'},
                            errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
                          )
                        : _thumbnailPlaceholder(),
                  ),
                  // Duration badge — pastki o'ngda
                  if (content.duration > 0)
                    Positioned(
                      right: 8.w,
                      bottom: 8.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          _formatDuration(content.duration),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ===== INFO SECTION =====
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel-like avatar (category icon)
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      gradient: _getCategoryGradient(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryEmoji(),
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          content.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        // Meta qator: category · views · duration
                        Text(
                          _buildMetaText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: _getCategoryGradient(),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: Colors.white.withOpacity(0.7),
          size: 48.sp,
        ),
      ),
    );
  }

  String _buildMetaText() {
    final parts = <String>[];
    if (content.category.isNotEmpty) {
      parts.add(content.category);
    }
    if (content.views > 0) {
      parts.add(_formatViews(content.views));
    }
    if (content.duration > 0) {
      parts.add(_formatDuration(content.duration));
    }
    return parts.join(' · ');
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M ko\'rish';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K ko\'rish';
    }
    return '$views ko\'rish';
  }

  LinearGradient _getCategoryGradient() {
    switch (content.type.toLowerCase()) {
      case 'talimiy':
        return AppColors.oceanGradient;
      case 'ozbek':
        return AppColors.cartoonGradient;
      case 'jahon':
        return AppColors.storiesGradient;
      default:
        return AppColors.primaryGradient;
    }
  }

  String _getCategoryEmoji() {
    switch (content.type.toLowerCase()) {
      case 'talimiy':
        return '📚';
      case 'ozbek':
        return '🇺🇿';
      case 'jahon':
        return '🌍';
      default:
        return '🎬';
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
