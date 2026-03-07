import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/coloring_image_data.dart';
import '../data/coloring_storage.dart';
import '../engine/sound_service.dart';
import 'coloring_screen.dart';
import 'my_artworks_screen.dart';

// ═══════════════════════════════════════════════════════════
// Material Design 3 — Coloring Browse Screen
// Performance optimized — no unnecessary rebuilds
// ═══════════════════════════════════════════════════════════

class ColoringBrowseScreen extends StatefulWidget {
  const ColoringBrowseScreen({super.key});

  @override
  State<ColoringBrowseScreen> createState() => _ColoringBrowseScreenState();
}

class _ColoringBrowseScreenState extends State<ColoringBrowseScreen>
    with SingleTickerProviderStateMixin {
  late PageController _bannerCtrl;
  late AnimationController _introCtrl;

  int _currentBanner = 0;
  int _selectedCategoryIdx = 0;

  static const _categoryMeta = [
    _CatMeta('Mashinalar', '🚗', Color(0xFF4A90D9), Color(0xFF357ABD)),
    _CatMeta('Hayvonlar', '🐾', Color(0xFF66BB6A), Color(0xFF43A047)),
    _CatMeta('Mevalar', '🍎', Color(0xFFEF5350), Color(0xFFE53935)),
    _CatMeta('Tabiat', '🌿', Color(0xFF26A69A), Color(0xFF00897B)),
    _CatMeta('Poliz Mevalari', '🥬', Color(0xFFFF7043), Color(0xFFE64A19)),
  ];

  List<ColoringImageInfo> _filteredImages = [];
  List<SavedArtwork> _recentArtworks = [];

  @override
  void initState() {
    super.initState();
    SoundService().init();
    _bannerCtrl = PageController(viewportFraction: 0.92);

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _updateFilteredImages();
    _loadRecentArtworks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introCtrl.forward();
    });
  }

  void _updateFilteredImages() {
    final catName = _categoryMeta[_selectedCategoryIdx].name;
    _filteredImages = ColoringImages.byCategory(catName);
  }

  Future<void> _loadRecentArtworks() async {
    final all = await ColoringStorage.getSavedArtworks();
    if (mounted) {
      setState(() => _recentArtworks = all.take(5).toList());
    }
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  void _selectCategory(int idx) {
    if (idx == _selectedCategoryIdx) return;
    HapticFeedback.selectionClick();
    SoundService().playPop();
    setState(() {
      _selectedCategoryIdx = idx;
      _updateFilteredImages();
    });
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
            SliverToBoxAdapter(child: _TopBar(introCtrl: _introCtrl)),
            // ─── HERO BANNER ───
            SliverToBoxAdapter(
              child: _HeroBanner(
                ctrl: _bannerCtrl,
                introCtrl: _introCtrl,
                categories: _categoryMeta,
                currentBanner: _currentBanner,
                onPageChanged: (i) {
                  setState(() => _currentBanner = i);
                  _selectCategory(i);
                },
                onCategoryTap: _selectCategory,
              ),
            ),
            // ─── DOTS ───
            SliverToBoxAdapter(
              child: _BannerDots(
                count: _categoryMeta.length,
                current: _currentBanner,
                categories: _categoryMeta,
              ),
            ),
            // ─── RECENT ARTWORKS ───
            if (_recentArtworks.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecentArtworks(artworks: _recentArtworks),
              ),
            // ─── SECTION TITLE ───
            SliverToBoxAdapter(
              child: _SectionTitle(
                cat: _categoryMeta[_selectedCategoryIdx],
                count: _filteredImages.length,
                categoryIdx: _selectedCategoryIdx,
              ),
            ),
            // ─── COLORING GRID ───
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              sliver: _ColoringGrid(
                key: ValueKey(_selectedCategoryIdx),
                images: _filteredImages,
                color: _categoryMeta[_selectedCategoryIdx].color,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TOP BAR — faqat intro animatsiya bilan
// ═══════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final AnimationController introCtrl;
  const _TopBar({required this.introCtrl});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: introCtrl, curve: const Interval(0.0, 0.4)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: introCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
          child: Row(
            children: [
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
              Text(
                'Color Fun',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D2D3A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HERO BANNER — PageView bilan
// ═══════════════════════════════════════════════════════════
class _HeroBanner extends StatelessWidget {
  final PageController ctrl;
  final AnimationController introCtrl;
  final List<_CatMeta> categories;
  final int currentBanner;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onCategoryTap;

  const _HeroBanner({
    required this.ctrl,
    required this.introCtrl,
    required this.categories,
    required this.currentBanner,
    required this.onPageChanged,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: introCtrl, curve: const Interval(0.15, 0.5)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: introCtrl, curve: const Interval(0.15, 0.5, curve: Curves.easeOut))),
        child: SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: ctrl,
            itemCount: categories.length,
            onPageChanged: onPageChanged,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final images = ColoringImages.byCategory(cat.name);
              return AnimatedBuilder(
                animation: ctrl,
                builder: (ctx, child) {
                  double scale = 1.0;
                  if (ctrl.position.haveDimensions) {
                    final page = ctrl.page ?? currentBanner.toDouble();
                    scale = (1 - (page - i).abs() * 0.08).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: GestureDetector(
                  onTap: () => onCategoryTap(i),
                  child: _BannerCard(cat: cat, imageCount: images.length, images: images),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BANNER CARD — stateless, clean
// ═══════════════════════════════════════════════════════════
class _BannerCard extends StatelessWidget {
  final _CatMeta cat;
  final int imageCount;
  final List<ColoringImageInfo> images;

  const _BannerCard({
    required this.cat,
    required this.imageCount,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        '$imageCount ta rasm',
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
                // Image preview
                if (images.isNotEmpty)
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
}

// ═══════════════════════════════════════════════════════════
// BANNER DOTS
// ═══════════════════════════════════════════════════════════
class _BannerDots extends StatelessWidget {
  final int count;
  final int current;
  final List<_CatMeta> categories;

  const _BannerDots({
    required this.count,
    required this.current,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            width: isActive ? 20.w : 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.r),
              color: isActive ? categories[i].color : const Color(0xFFD0D0D0),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// RECENT ARTWORKS — oxirgi 5 ta bo'yalgan rasm
// ═══════════════════════════════════════════════════════════
class _RecentArtworks extends StatelessWidget {
  final List<SavedArtwork> artworks;
  const _RecentArtworks({required this.artworks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  '🎨 Oxirgi bo\'yalganlar',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D3A),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const MyArtworksScreen(),
                    ));
                  },
                  child: Text(
                    'Hammasi →',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C4DFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 90.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: artworks.length,
              itemBuilder: (ctx, i) {
                final artwork = artworks[i];
                final file = File(artwork.savedPath);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const MyArtworksScreen(),
                      ));
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60.w, height: 60.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF6B6B), Color(0xFFFFB347),
                                Color(0xFF4ECDC4), Color(0xFF7C4DFF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: EdgeInsets.all(2.5.w),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              image: file.existsSync()
                                  ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: !file.existsSync()
                                ? Center(child: Text(artwork.emoji, style: TextStyle(fontSize: 22.sp)))
                                : null,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        SizedBox(
                          width: 64.w,
                          child: Text(
                            artwork.name,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION TITLE — AnimatedSwitcher
// ═══════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final _CatMeta cat;
  final int count;
  final int categoryIdx;

  const _SectionTitle({
    required this.cat,
    required this.count,
    required this.categoryIdx,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 2.h),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: Row(
          key: ValueKey(categoryIdx),
          children: [
            Container(
              width: 4.w, height: 20.h,
              decoration: BoxDecoration(
                color: cat.color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '${cat.emoji} ${cat.name}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D2D3A),
              ),
            ),
            const Spacer(),
            Text(
              '$count ta',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COLORING GRID — ValueKey bilan qayta yaratiladi
// Har bir karta o'z ichki stagger animatsiyasiga ega
// ═══════════════════════════════════════════════════════════
class _ColoringGrid extends StatefulWidget {
  final List<ColoringImageInfo> images;
  final Color color;

  const _ColoringGrid({
    super.key,
    required this.images,
    required this.color,
  });

  @override
  State<_ColoringGrid> createState() => _ColoringGridState();
}

class _ColoringGridState extends State<_ColoringGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: widget.images.length,
      itemBuilder: (ctx, i) {
        // Stagger: har karta 30ms kechikish bilan
        final start = (i * 0.04).clamp(0.0, 0.6);
        final end = (start + 0.4).clamp(0.0, 1.0);

        return AnimatedBuilder(
          animation: _staggerCtrl,
          builder: (ctx, child) {
            final t = Curves.easeOutCubic.transform(
              (((_staggerCtrl.value - start) / (end - start)).clamp(0.0, 1.0)),
            );
            return Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.85 + 0.15 * t,
                child: child,
              ),
            );
          },
          child: _ImageCard(
            img: widget.images[i],
            number: i + 1,
            color: widget.color,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// IMAGE CARD — press effekti bilan
// ═══════════════════════════════════════════════════════════
class _ImageCard extends StatefulWidget {
  final ColoringImageInfo img;
  final int number;
  final Color color;

  const _ImageCard({
    required this.img,
    required this.number,
    required this.color,
  });

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    SoundService().playPop();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ColoringScreen(imageInfo: widget.img),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.forward().then((_) => _onTap()),
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Image.asset(widget.img.assetPath, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    // Number badge
                    Positioned(
                      top: 8.h, left: 8.w,
                      child: Container(
                        width: 28.w, height: 28.w,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.number}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.color,
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
                          si < widget.img.difficulty ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 14.sp,
                          color: si < widget.img.difficulty
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
                    Text(widget.img.emoji, style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        widget.img.name,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
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
  }
}

/// Kategoriya meta
class _CatMeta {
  final String name;
  final String emoji;
  final Color color;
  final Color darkColor;
  const _CatMeta(this.name, this.emoji, this.color, this.darkColor);
}
