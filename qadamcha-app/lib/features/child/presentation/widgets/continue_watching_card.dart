import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../content/domain/entities/content_entity.dart';

/// "Davom etish" kartochkasi — oxirgi ko'rilgan video
class ContinueWatchingCard extends StatelessWidget {
  final ContentEntity content;
  final VoidCallback onTap;

  const ContinueWatchingCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(children: [
            Icon(Icons.history_rounded, size: 16.sp, color: const Color(0xFF606060)),
            SizedBox(width: 4.w),
            Text(
              'Davom etish',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF606060),
              ),
            ),
          ]),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(width: 16.w),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 140.w,
                  height: 80.h,
                  child: content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          content.thumbnailUrl!,
                          fit: BoxFit.cover,
                          headers: const {'Referer': 'https://qadamcha.uz/'},
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFFE5E5E5)),
                        )
                      : Container(color: const Color(0xFFE5E5E5)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F0F0F),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      content.category.isNotEmpty ? content.category : 'Multfilm',
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF606060)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Divider(height: 24.h, color: const Color(0xFFE8E8E8)),
        ),
      ],
    );
  }
}
