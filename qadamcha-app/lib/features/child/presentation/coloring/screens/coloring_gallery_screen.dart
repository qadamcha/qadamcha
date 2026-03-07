import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/coloring_image_data.dart';
import '../data/coloring_storage.dart';
import '../data/coloring_utils.dart';
import '../engine/sound_service.dart';
import 'coloring_screen.dart';

/// Bo'yash uchun rasm tanlash galereyasi — Nana Banana uslubi
class ColoringGalleryScreen extends StatefulWidget {
  final String? category;

  const ColoringGalleryScreen({super.key, this.category});

  @override
  State<ColoringGalleryScreen> createState() => _ColoringGalleryScreenState();
}

class _ColoringGalleryScreenState extends State<ColoringGalleryScreen> {
  Set<String> _completedIds = {};

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    final ids = await ColoringStorage.getCompletedImageIds();
    if (mounted) setState(() => _completedIds = ids);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.category != null
        ? ColoringImages.byCategory(widget.category!)
        : ColoringImages.all();

    final title = widget.category ?? 'Barcha rasmlar';
    final headerColor = _categoryColor(widget.category ?? '');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFFBCFE8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ═══ Header ═══
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        SoundService().playPop();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: headerColor, size: 22.sp),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              headerColor,
                              headerColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: headerColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_categoryEmoji(widget.category ?? ''),
                                style: TextStyle(fontSize: 22.sp)),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      offset: const Offset(1, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),

              // ═══ Grid ═══
              Expanded(
                child: images.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('😔', style: TextStyle(fontSize: 48.sp)),
                            SizedBox(height: 8.h),
                            Text(
                              'Rasmlar topilmadi',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // Ekranning kengligidan kelib chiqib qatorlar sonini hisoblash
                          final screenWidth = MediaQuery.of(context).size.width;
                          final int crossAxisCount = screenWidth > 800 ? 5 : (screenWidth > 600 ? 4 : (screenWidth > 400 ? 3 : 2));
                          
                          return GridView.builder(
                            padding: EdgeInsets.all(16.w),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14.w,
                              mainAxisSpacing: 14.h,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: images.length,
                        itemBuilder: (ctx, index) {
                          final img = images[index];
                          return _GalleryCard3D(
                            imageInfo: img,
                            isCompleted: _completedIds.contains(img.id),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              SoundService().playPop();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      ColoringScreen(imageInfo: img),
                                  transitionsBuilder:
                                      (_, anim, __, child) {
                                    return FadeTransition(
                                      opacity: anim,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                                begin: 0.9, end: 1.0)
                                            .animate(CurvedAnimation(
                                                parent: anim,
                                                curve:
                                                    Curves.easeOutCubic)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) =>
      ColoringUtils.categoryColor(category);

  String _categoryEmoji(String category) =>
      ColoringUtils.categoryEmoji(category);
}

/// 3D Glossy Gallery Card
class _GalleryCard3D extends StatelessWidget {
  final ColoringImageInfo imageInfo;
  final VoidCallback onTap;
  final bool isCompleted;

  const _GalleryCard3D({
    required this.imageInfo,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _catColor(imageInfo.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Bubble
            Positioned(
              right: -5.w,
              top: -5.w,
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 80.h,
                  width: 80.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      imageInfo.assetPath,
                      fit: BoxFit.contain,
                      cacheWidth: 300, // Memory optimizatsiyasi 
                      errorBuilder: (_, __, ___) => Text(
                        imageInfo.emoji,
                        style: TextStyle(fontSize: 48.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  imageInfo.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF374151),
                  ),
                ),
                SizedBox(height: 2.h),
                // Category badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    imageInfo.category,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      isCompleted
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18.sp,
                      color: isCompleted
                          ? const Color(0xFFFFA726)
                          : const Color(0xFFE0E0E0),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _catColor(String category) =>
      ColoringUtils.categoryColor(category);
}
