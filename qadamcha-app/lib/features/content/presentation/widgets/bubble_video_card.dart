import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/content_entity.dart';

/// KidsTube — Video Card (3D soya + ozgina chekka masofa)
class BubbleVideoCard extends StatelessWidget {
  final ContentEntity content;
  final VoidCallback onTap;

  const BubbleVideoCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== THUMBNAIL =====
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              content.thumbnailUrl!,
                              fit: BoxFit.cover,
                              headers: const {'Referer': 'https://qadamcha.uz/'},
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),

                      // Duration badge
                      if (content.duration > 0)
                        Positioned(
                          right: 8.w,
                          bottom: 8.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            child: Text(
                              _formatDuration(content.duration),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ===== TITLE =====
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
                child: Text(
                  content.series.isNotEmpty
                      ? '${content.series} \u2014 ${content.title}'
                      : content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F0F0F),
                    height: 1.3,
                  ),
                ),
              ),

              // ===== CHANNEL NAME =====
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                child: Text(
                  _buildChannelText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF606060),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE5E5E5),
      child: Center(
        child: Icon(Icons.play_circle_outline, color: const Color(0xFFBBBBBB), size: 48.sp),
      ),
    );
  }

  String _buildChannelText() {
    final parts = <String>[];
    if (content.series.isNotEmpty) {
      parts.add(content.series);
    } else if (content.category.isNotEmpty) {
      parts.add(content.category);
    } else {
      parts.add('Qadamcha Kids');
    }
    if (content.views > 0) parts.add(_formatViews(content.views));
    return parts.join(' · ');
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M ko\'rish';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K ko\'rish';
    return '$views ko\'rish';
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
