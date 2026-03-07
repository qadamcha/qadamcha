import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/coloring_image_data.dart';
import '../data/coloring_storage.dart';
import '../data/coloring_utils.dart';
import '../engine/sound_service.dart';
import 'coloring_gallery_screen.dart';
import 'my_artworks_screen.dart';

/// Coloring Home — Nana Banana / Cocomelon uslubidagi asosiy sahifa
class ColoringHomeScreen extends StatefulWidget {
  const ColoringHomeScreen({super.key});

  @override
  State<ColoringHomeScreen> createState() => _ColoringHomeScreenState();
}

class _ColoringHomeScreenState extends State<ColoringHomeScreen>
    with TickerProviderStateMixin {
  int _completedCount = 0;
  List<SavedArtwork> _recentArtworks = [];
  Set<String> _completedIds = {};
  bool _isLoading = true;

  /// Orqa fon rasmi
  static const _currentBg = 'assets/images/coloring_bg.png';

  late AnimationController _floatController;
  late AnimationController _bounceController;
  late PageController _featuredPageController;
  late PageController _categoryPageController;
  int _currentCategoryPage = 0;

  @override
  void initState() {
    super.initState();
    SoundService().init();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _featuredPageController = PageController(viewportFraction: 0.88);
    _categoryPageController = PageController(viewportFraction: 0.90); // Kengaytirildi: 0.75 -> 0.90

    _loadData();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    _featuredPageController.dispose();
    _categoryPageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final artworks = await ColoringStorage.getSavedArtworks();
    final completed = await ColoringStorage.getCompletedImageIds();
    if (mounted) {
      setState(() {
        _completedCount = artworks.length;
        _recentArtworks = artworks.take(4).toList();
        _completedIds = completed;
        _isLoading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final allImages = ColoringImages.all();
    final categories = ColoringImages.categories();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Orqa fon rasmi
          Positioned.fill(
            child: Image.asset(
              _currentBg,
              fit: BoxFit.cover,
              errorBuilder: (ctx, error, stack) {
                debugPrint('⚠️ BG IMAGE ERROR: $error');
                return Container(color: const Color(0xFFE8F4FD));
              },
            ),
          ),
          // Overlay olib tashlandi — fon to'liq ko'rinadi
          SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 16.h),
                        if (_recentArtworks.isNotEmpty) ...[
                          _buildSectionTitle(
                              '⭐', 'Mening rasmlarim', 'Hammasi →', () {
                            SoundService().playPop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyArtworksScreen()),
                            ).then((_) => _loadData());
                          }),
                          SizedBox(height: 10.h),
                          _buildRecentArtworks(),
                          SizedBox(height: 20.h),
                        ],
                        _buildSectionTitle(
                            '📂', 'Kategoriyalar', null, null),
                        SizedBox(height: 12.h),
                        _buildCategoriesGrid(context, categories, allImages),
                        SizedBox(height: 48.h),
                      ],
                    ),
                  ),
      ),
        ], // Stack children
      ), // Stack
    );
  }

  // ═══════════════════════════════════════════════════════
  // FLOATING DECORATIONS
  // ═══════════════════════════════════════════════════════
  List<Widget> _buildFloatingDecorations() {
    return [
      // Star top-right
      AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          final offsetY = sin(_floatController.value * pi * 2) * 8;
          return Positioned(
            right: 20.w,
            top: 60.h + offsetY,
            child: Text('⭐', style: TextStyle(fontSize: 22.sp)),
          );
        },
      ),
      // Paint splash left
      AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          final offsetY = sin((_floatController.value + 0.3) * pi * 2) * 6;
          return Positioned(
            left: 15.w,
            top: 180.h + offsetY,
            child: Text('🎨', style: TextStyle(fontSize: 18.sp)),
          );
        },
      ),
      // Crayon right
      AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          final offsetY = sin((_floatController.value + 0.6) * pi * 2) * 10;
          return Positioned(
            right: 30.w,
            top: 350.h + offsetY,
            child: Text('🖍️', style: TextStyle(fontSize: 16.sp)),
          );
        },
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Back button — chunky 3D style
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
                  color: const Color(0xFF7C3AED), size: 22.sp),
            ),
          ),
          // Sarlavha yozuvi (Ranglar dunyosi) olib tashlandi, faqat Orqaga tugmasi qoldirildi.
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // FEATURED BANNER
  // ═══════════════════════════════════════════════════════
  Widget _buildFeaturedBanner(
      BuildContext context, List<ColoringImageInfo> images) {
    return SizedBox(
      height: 170.h,
      child: PageView.builder(
        controller: _featuredPageController,
        itemCount: images.length > 6 ? 6 : images.length,
        itemBuilder: (ctx, i) {
          final img = images[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              SoundService().playPop();
              _navigateToGallery(context);
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _categoryColor(img.category),
                    _categoryColor(img.category).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _categoryColor(img.category).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22.r),
                child: Stack(
                  children: [
                    // Bubble decorations
                    Positioned(
                      right: -10.w,
                      top: -10.h,
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -15.w,
                      bottom: -15.h,
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Content
                    Row(
                      children: [
                        SizedBox(width: 20.w),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(img.emoji,
                                  style: TextStyle(fontSize: 40.sp)),
                              SizedBox(height: 4.h),
                              Text(
                                img.name,
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
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
                              ),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  'Bo\'yashni boshlang! 🎨',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Thumbnail
                        Container(
                          width: 100.w,
                          height: 100.w,
                          margin: EdgeInsets.only(right: 16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: Image.asset(
                              img.assetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(img.emoji,
                                    style: TextStyle(fontSize: 40.sp)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // STATS — 3D GLOSSY CARDS
  // ═══════════════════════════════════════════════════════
  Widget _buildStats(int totalImages, int completed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _build3DStatCard(
            '🖼️',
            '$totalImages',
            'Rasmlar',
            const Color(0xFF7C3AED),
            const Color(0xFFA78BFA),
          ),
          SizedBox(width: 10.w),
          _build3DStatCard(
            '✅',
            '$completed',
            'Tugallangan',
            const Color(0xFF10B981),
            const Color(0xFF6EE7B7),
          ),
          SizedBox(width: 10.w),
          _build3DStatCard(
            '🎨',
            '${ColoringPalette.colors.length}',
            'Ranglar',
            const Color(0xFFF59E0B),
            const Color(0xFFFCD34D),
          ),
        ],
      ),
    );
  }

  Widget _build3DStatCard(
      String emoji, String value, String label, Color c1, Color c2) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c1, c2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: c1.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24.sp)),
            SizedBox(height: 2.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════════
  Widget _buildSectionTitle(
      String emoji, String title, String? actionText, VoidCallback? onAction) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [

          // Yozuvlarga joy yetishi uchun Expanded ishlatiladi (Overflow oldini ochadi)
          Expanded(
            child: Stack(
              children: [
                // Qalin oq silliq hoshiya (kichik burchaklar va qirralarni yumaloqlash uchun StrokeJoin.round qo'llaniladi)
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 28.sp, // Kattaroq
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 9.0
                      ..strokeJoin = StrokeJoin.round // BU JUDA MUHIM - Qirralarni yumaloq qiladi (xunuk tikanlarni olib tashlaydi)
                      ..strokeCap = StrokeCap.round
                      ..color = Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2), // Yumshoqroq o'tirgan soya
                        offset: const Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Asosiy ichki rang (Yuqoridan pastga Gradient orqali Premium 3D effekt)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF38BDF8), // Ochiq samoviy havo rang (tepada)
                      Color(0xFF0369A1), // To'q shirin ko'k (pastda)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white, // ShaderMask ishlashi uchun white kerak
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // RECENT ARTWORKS
  // ═══════════════════════════════════════════════════════
  Widget _buildRecentArtworks() {
    return SizedBox(
      height: 130.h,
      child: ListView.builder(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 10.h),
        itemCount: _recentArtworks.length + 1,
        itemBuilder: (ctx, i) {
          if (i == _recentArtworks.length) {
            return GestureDetector(
              onTap: () {
                SoundService().playPop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyArtworksScreen()),
                ).then((_) => _loadData());
              },
              child: Container(
                width: 90.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: const Color(0xFF7C3AED), size: 22.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Barchasi',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final artwork = _recentArtworks[i];
          return Container(
            width: 100.w,
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Image.file(
                File(artwork.savedPath),
                fit: BoxFit.cover,
                cacheWidth: 300, // RAM tejash
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CATEGORIES — TILTED KARTALAR (O'yin kartalari kabi)
  // ═══════════════════════════════════════════════════════

  Widget _buildCategoriesGrid(BuildContext context, List<String> categories,
      List<ColoringImageInfo> allImages) {
    // Ekranning 55% ini olamiz, lekin haddan tashqari katta yoki kichik bo'lmasligi uchun chegaralaymiz
    final double screenHeight = MediaQuery.of(context).size.height;
    final double gridHeight = (screenHeight * 0.55).clamp(400.0, 600.0);

    return SizedBox(
      height: gridHeight,
      child: PageView.builder(
            controller: _categoryPageController,
            clipBehavior: Clip.none,
            physics: const PageScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            allowImplicitScrolling: true,
            itemCount: categories.length,
            onPageChanged: (i) {
              setState(() => _currentCategoryPage = i);
              HapticFeedback.selectionClick();
            },
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final catImages =
                  allImages.where((img) => img.category == cat).toList();
              final color = _categoryColor(cat);
              final emoji = _categoryEmoji(cat);
              final bgImage = _categoryImage(cat);

              return AnimatedBuilder(
                animation: _categoryPageController,
                builder: (ctx, child) {
                  double pageOffset = 0;
                  if (_categoryPageController.position.haveDimensions) {
                    pageOffset = (_categoryPageController.page ?? 0) - i;
                  }

                  // Smooth 3D carousel effekti
                  final absOffset = pageOffset.abs();
                  final scale = (1 - absOffset * 0.12).clamp(0.85, 1.0);
                  final yShift = absOffset * 25;
                  final opacity = (1 - absOffset * 0.3).clamp(0.6, 1.0);
                  // Yondagi kartalar biroz buriladi
                  final rotateY = pageOffset * 0.03;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotateY)
                      ..scale(scale),
                    child: Transform.translate(
                      offset: Offset(0, yShift),
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ColoringGalleryScreen(category: cat)),
                    ).then((_) => _loadData());
                  },
                  child: Stack(
                    children: [
                      // Karta
                      Container(
                        margin: EdgeInsets.only(
                            left: 8.w, right: 8.w, top: gridHeight * 0.22, bottom: 5.h), // Ekran bo'yiga nisbatan margin

                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(bgImage),
                            fit: BoxFit.cover,
                          ),
                      borderRadius: BorderRadius.circular(32.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
                      child: Stack(
                        children: [
                        ],
                      ),
                    ),
                  ),
                  // Kategoriya nomi tepadagi bo'shliqda
                  Positioned(
                    top: (gridHeight * 0.22) - 20.h, // Kartaning dinamik margin-top iga moslab pastroqqa tushirildi
                    left: 12.w, // Kartaning yon chekkalariga tegrar-tegmas
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: color.withValues(alpha: 0.8),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Markazga joylashish
                        children: [
                          Text(emoji, style: TextStyle(fontSize: 18.sp)),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              cat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18.sp, // Biroz qisqartiramiz uzun nomlar sig'ishi uchun
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 0.5,
                              ),
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
            },
          ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ALL IMAGES GRID
  // ═══════════════════════════════════════════════════════
  Widget _buildAllImagesGrid(
      BuildContext context, List<ColoringImageInfo> allImages) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 800 ? 5 : (screenWidth > 600 ? 4 : (screenWidth > 400 ? 3 : 2));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.0,
        ),
        itemCount: allImages.length > 4 ? 4 : allImages.length,
        itemBuilder: (ctx, i) {
          final img = allImages[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              SoundService().playPop();
              _navigateToGallery(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: _categoryColor(img.category).withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 70.h,
                    width: 70.w,
                    child: Image.asset(
                      img.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        img.emoji,
                        style: TextStyle(fontSize: 40.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    img.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF424242),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (s) {
                      final isCompleted = _completedIds.contains(img.id);
                      return Icon(
                        isCompleted
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16.sp,
                        color: isCompleted
                            ? const Color(0xFFFFA726)
                            : const Color(0xFFE0E0E0),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════
  void _navigateToGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ColoringGalleryScreen()),
    ).then((_) => _loadData());
  }

  Color _categoryColor(String category) =>
      ColoringUtils.categoryColor(category);

  String _categoryEmoji(String category) =>
      ColoringUtils.categoryEmoji(category);

  String _categoryImage(String category) {
    switch (category) {
      case 'Hayvonlar':
        return 'assets/images/card_hayvonlar.png';
      case 'Mashinalar':
        return 'assets/images/card_mashinalar.png';
      case 'Mevalar':
        return 'assets/images/card_mevalar.png';
      case 'Tabiat':
        return 'assets/images/card_tabiat.png';
      case 'Poliz Mevalari':
        return 'assets/images/card_poliz.png';
      default:
        return 'assets/images/card_tabiat.png';
    }
  }
}
