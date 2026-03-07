import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/coloring_image_data.dart';
import '../data/coloring_storage.dart';
import '../engine/sound_service.dart';
import 'coloring_screen.dart';
import 'my_artworks_screen.dart';

// ═══════════════════════════════════════════════════════════
// Material Design 3 — Coloring Landing Page
// Hero banner + Category chips + 2-column grid
// ═══════════════════════════════════════════════════════════

class ColoringBrowseScreen extends StatefulWidget {
  const ColoringBrowseScreen({super.key});

  @override
  State<ColoringBrowseScreen> createState() => _ColoringBrowseScreenState();
}

class _ColoringBrowseScreenState extends State<ColoringBrowseScreen>
    with TickerProviderStateMixin {
  late PageController _bannerCtrl;
  late AnimationController _fadeCtrl;
  int _currentBanner = 0;
  int _selectedCategoryIdx = 0;
  final _storage = ColoringStorage();

  // Kategoriya ma'lumotlari
  static const _categoryMeta = [
    _CatMeta('Mashinalar', '🚗', Color(0xFF4A90D9), Color(0xFF357ABD)),
    _CatMeta('Hayvonlar', '🐾', Color(0xFF66BB6A), Color(0xFF43A047)),
    _CatMeta('Mevalar', '🍎', Color(0xFFEF5350), Color(0xFFE53935)),
    _CatMeta('Tabiat', '🌿', Color(0xFF26A69A), Color(0xFF00897B)),
    _CatMeta('Poliz Mevalari', '🥬', Color(0xFFFF7043), Color(0xFFE64A19)),
  ];

  List<ColoringImageInfo> _filteredImages = [];

  @override
  void initState() {
    super.initState();
    SoundService().init();
    _bannerCtrl = PageController(viewportFraction: 0.92);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _updateFilteredImages();
  }

  void _updateFilteredImages() {
    final catName = _categoryMeta[_selectedCategoryIdx].name;
    _filteredImages = ColoringImages.byCategory(catName);
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectCategory(int idx) {
    if (idx == _selectedCategoryIdx) return;
    HapticFeedback.selectionClick();
    SoundService().playPop();
    _fadeCtrl.reset();
    setState(() {
      _selectedCategoryIdx = idx;
      _updateFilteredImages();
    });
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── TOP BAR ───
            SliverToBoxAdapter(child: _buildTopBar()),
            // ─── HERO BANNER CAROUSEL ───
            SliverToBoxAdapter(child: _buildHeroBanner()),
            // ─── BANNER DOTS ───
            SliverToBoxAdapter(child: _buildDots()),
            // ─── CATEGORY CHIPS ───
            SliverToBoxAdapter(child: _buildCategoryChips()),
            // ─── COLORING GRID ───
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              sliver: _buildColoringGrid(),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          ],
        ),
      ),
    );
  }

  // ═══ TOP BAR ═══
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w, height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: const Color(0xFF333333)),
            ),
          ),
          SizedBox(width: 12.w),
          // Title
          Expanded(
            child: Text(
              'Color Fun',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D2D3A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          // My Artworks button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              SoundService().playPop();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const MyArtworksScreen(),
              ));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_rounded, size: 16.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text('Rasmlarim', style: TextStyle(
                    fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ HERO BANNER ═══
  Widget _buildHeroBanner() {
    final banners = _categoryMeta;
    return SizedBox(
      height: 180.h,
      child: PageView.builder(
        controller: _bannerCtrl,
        itemCount: banners.length,
        onPageChanged: (i) => setState(() => _currentBanner = i),
        itemBuilder: (ctx, i) {
          final cat = banners[i];
          final images = ColoringImages.byCategory(cat.name);
          return AnimatedBuilder(
            animation: _bannerCtrl,
            builder: (ctx, child) {
              double scale = 1.0;
              if (_bannerCtrl.position.haveDimensions) {
                final page = _bannerCtrl.page ?? _currentBanner.toDouble();
                scale = (1 - (page - i).abs() * 0.08).clamp(0.9, 1.0);
              }
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => _selectCategory(i),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cat.color, cat.darkColor],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: cat.color.withOpacity(0.35),
                      blurRadius: 15, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Dekorativ doiralar
                    Positioned(
                      right: -20.w, top: -20.h,
                      child: Container(
                        width: 100.w, height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -15.w, bottom: -15.h,
                      child: Container(
                        width: 70.w, height: 70.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${cat.emoji} ${cat.name}',
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  '${images.length} ta rasm',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    'Boshlash →',
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
                          // Image preview stack
                          SizedBox(
                            width: 110.w,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (images.length > 1)
                                  Positioned(
                                    right: 0, top: 10.h,
                                    child: _miniPreview(images[1], 70.w, 8),
                                  ),
                                Positioned(
                                  left: 0,
                                  child: _miniPreview(images[0], 85.w, 0),
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
            ),
          );
        },
      ),
    );
  }

  Widget _miniPreview(ColoringImageInfo img, double size, double rotation) {
    return Transform.rotate(
      angle: rotation * 0.02,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8, offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(6.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.asset(img.assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  // ═══ DOTS ═══
  Widget _buildDots() {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_categoryMeta.length, (i) {
          final isActive = i == _currentBanner;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            width: isActive ? 20.w : 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.r),
              color: isActive
                  ? _categoryMeta[i].color
                  : const Color(0xFFD0D0D0),
            ),
          );
        }),
      ),
    );
  }

  // ═══ CATEGORY CHIPS ═══
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemCount: _categoryMeta.length,
        itemBuilder: (ctx, i) {
          final cat = _categoryMeta[i];
          final isSelected = i == _selectedCategoryIdx;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => _selectCategory(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? cat.color : const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: cat.color.withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 3),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.emoji, style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 6.w),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF555555),
                      ),
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

  // ═══ COLORING GRID ═══
  SliverGrid _buildColoringGrid() {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _filteredImages.length,
      itemBuilder: (ctx, i) {
        final img = _filteredImages[i];
        return FadeTransition(
          opacity: _fadeCtrl,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 0.15 + i * 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic)),
            child: _buildImageCard(img, i + 1),
          ),
        );
      },
    );
  }

  Widget _buildImageCard(ColoringImageInfo img, int number) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        SoundService().playPop();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ColoringScreen(imageInfo: img),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  // Main image
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Image.asset(img.assetPath, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  // Number badge
                  Positioned(
                    top: 8.h, left: 8.w,
                    child: Container(
                      width: 28.w, height: 28.w,
                      decoration: BoxDecoration(
                        color: _categoryMeta[_selectedCategoryIdx].color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: _categoryMeta[_selectedCategoryIdx].color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Difficulty stars
                  Positioned(
                    top: 8.h, right: 8.w,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (si) => Icon(
                        si < img.difficulty ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 14.sp,
                        color: si < img.difficulty
                            ? const Color(0xFFFFB300)
                            : const Color(0xFFD0D0D0),
                      )),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Text(img.emoji, style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      img.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.play_circle_filled_rounded,
                    size: 20.sp,
                    color: _categoryMeta[_selectedCategoryIdx].color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kategoriya meta ma'lumotlari
class _CatMeta {
  final String name;
  final String emoji;
  final Color color;
  final Color darkColor;
  const _CatMeta(this.name, this.emoji, this.color, this.darkColor);
}
