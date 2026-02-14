import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';

/// Video qo'llanmalar sahifasi — full_architecture.html dizaynida
/// Featured video + video ro'yxat
class VideoGuidesPage extends StatelessWidget {
  const VideoGuidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  BackButtonBox(onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 16.w),
                  Text(
                    '🎥 Video qo\'llanmalar',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Video
                    _buildFeaturedVideo(),
                    SizedBox(height: 24.h),

                    Text(
                      'Barcha videolar',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Video list
                    ..._buildVideoList(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedVideo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            Container(
              height: 200.h,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 36.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Ota-ona va farzand munosabatlari',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '🔥 Mashhur  •  25:30',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.85),
                        fontFamily: 'Nunito',
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

  List<Widget> _buildVideoList() {
    final videos = [
      _VideoItem(
        title: 'Bolani ertalab uyg\'otish usullari',
        views: '7,800',
        duration: '15:45',
        color: AppColors.kidBlue,
      ),
      _VideoItem(
        title: 'Bola bilan o\'yin orqali o\'rganish',
        views: '12,400',
        duration: '20:10',
        color: AppColors.kidGreen,
      ),
      _VideoItem(
        title: 'Yaxshi uyqu uchun tavsiyalar',
        views: '5,200',
        duration: '12:30',
        color: AppColors.kidPurple,
      ),
      _VideoItem(
        title: 'Bolada kreativlikni rivojlantirish',
        views: '9,100',
        duration: '18:20',
        color: AppColors.kidYellow,
      ),
      _VideoItem(
        title: 'Sog\'lom ovqatlanish asoslari',
        views: '6,300',
        duration: '14:55',
        color: AppColors.kidPink,
      ),
    ];

    return videos.map((v) => Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: _VideoListCard(video: v),
    )).toList();
  }
}

class _VideoItem {
  final String title;
  final String views;
  final String duration;
  final Color color;

  const _VideoItem({
    required this.title,
    required this.views,
    required this.duration,
    required this.color,
  });
}

class _VideoListCard extends StatelessWidget {
  final _VideoItem video;

  const _VideoListCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 100.w,
            height: 70.h,
            decoration: BoxDecoration(
              color: video.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    size: 32.sp,
                    color: video.color,
                  ),
                ),
                Positioned(
                  bottom: 4.h,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      video.duration,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '${video.views} ko\'rilgan',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
