import 'dart:math';

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
// Hero banner + Category chips + 2-column grid
// ANIMATSIYALI (stagger, bounce, scale, shimmer)
// ═══════════════════════════════════════════════════════════

class ColoringBrowseScreen extends StatefulWidget {
  const ColoringBrowseScreen({super.key});

  @override
  State<ColoringBrowseScreen> createState() => _ColoringBrowseScreenState();
}

class _ColoringBrowseScreenState extends State<ColoringBrowseScreen>
    with TickerProviderStateMixin {
  late PageController _bannerCtrl;
  
  // Intro stagger animatsiya
  late AnimationController _introCtrl;
  late Animation<double> _topBarAnim;
  late Animation<double> _bannerAnim;
  late Animation<double> _dotsAnim;
  late Animation<double> _chipsAnim;
  late Animation<double> _gridAnim;
  
  // Grid o'zgarish animatsiyasi
  late AnimationController _gridChangeCtrl;
  
  // Shimmer effekt (banner uchun)
  late AnimationController _shimmerCtrl;
  
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
    
    // ═══ INTRO STAGGER ═══
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Ketma-ket animatsiya intervallari
    _topBarAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _bannerAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
    );
    _dotsAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
    );
    _chipsAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    );
    _gridAnim = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );
    
    // ═══ GRID CHANGE ═══
    _gridChangeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..value = 1.0;
    
    // ═══ SHIMMER ═══
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    
    _updateFilteredImages();
    
    // Intro boshlash
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _introCtrl.forward();
    });
  }

  void _updateFilteredImages() {
    final catName = _categoryMeta[_selectedCategoryIdx].name;
    _filteredImages = ColoringImages.byCategory(catName);
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _introCtrl.dispose();
    _gridChangeCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _selectCategory(int idx) {
    if (idx == _selectedCategoryIdx) return;
    HapticFeedback.selectionClick();
    SoundService().playPop();
    _gridChangeCtrl.reset();
    setState(() {
      _selectedCategoryIdx = idx;
      _updateFilteredImages();
    });
    _gridChangeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_introCtrl, _shimmerCtrl]),
          builder: (context, _) => CustomScrollView(
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
              // ─── SECTION TITLE ───
              SliverToBoxAdapter(child: _buildSectionTitle()),
              // ─── COLORING GRID ───
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                sliver: _buildColoringGrid(),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ TOP BAR — tepadan slide + fade ═══
  Widget _buildTopBar() {
    return Transform.translate(
      offset: Offset(0, -30 * (1 - _topBarAnim.value.clamp(0.0, 1.0))),
      child: Opacity(
        opacity: _topBarAnim.value.clamp(0.0, 1.0),
        child: Padding(
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
              _buildArtworksButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtworksButton() {
    return GestureDetector(
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
    );
  }

  // ═══ HERO BANNER — chapdan slide + scale ═══
  Widget _buildHeroBanner() {
    return Transform.translate(
      offset: Offset(-80 * (1 - _bannerAnim.value), 0),
      child: Opacity(
        opacity: _bannerAnim.value,
        child: Transform.scale(
          scale: 0.85 + 0.15 * _bannerAnim.value,
          child: SizedBox(
            height: 180.h,
            child: PageView.builder(
              controller: _bannerCtrl,
              itemCount: _categoryMeta.length,
              onPageChanged: (i) => setState(() => _currentBanner = i),
              itemBuilder: (ctx, i) {
                final cat = _categoryMeta[i];
                final images = ColoringImages.byCategory(cat.name);
                return AnimatedBuilder(
                  animation: _bannerCtrl,
                  builder: (ctx, child) {
                    double scale = 1.0;
                    if (_bannerCtrl.position.haveDimensions) {
                      final page = _bannerCtrl.page ?? _currentBanner.toDouble();
                      scale = (1 - (page - i).abs() * 0.08).clamp(0.9, 1.0);
                    }
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: GestureDetector(
                    onTap: () => _selectCategory(i),
                    child: _buildBannerCard(cat, images),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(_CatMeta cat, List<ColoringImageInfo> images) {
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
          // Shimmer effekt
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (ctx, _) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment(-1 + 2 * _shimmerCtrl.value, -0.3),
                        end: Alignment(-0.5 + 2 * _shimmerCtrl.value, 0.3),
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.0),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(color: Colors.white.withOpacity(0.05)),
                  );
                },
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

  // ═══ DOTS — fade in ═══
  Widget _buildDots() {
    return Opacity(
      opacity: _dotsAnim.value,
      child: Padding(
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
      ),
    );
  }

  // ═══ CATEGORY CHIPS — bounce in + scale on select ═══
  Widget _buildCategoryChips() {
    return Transform.translate(
      offset: Offset(0, 20 * (1 - _chipsAnim.value.clamp(0.0, 1.0))),
      child: Opacity(
        opacity: _chipsAnim.value.clamp(0.0, 1.0),
        child: SizedBox(
          height: 48.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            itemCount: _categoryMeta.length,
            itemBuilder: (ctx, i) => _buildChip(i),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(int i) {
    final cat = _categoryMeta[i];
    final isSelected = i == _selectedCategoryIdx;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: GestureDetector(
        onTap: () => _selectCategory(i),
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
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
                  color: cat.color.withOpacity(0.35),
                  blurRadius: 10, offset: const Offset(0, 4),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Text(cat.emoji, style: TextStyle(fontSize: 16.sp)),
                ),
                SizedBox(width: 6.w),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══ SECTION TITLE ═══
  Widget _buildSectionTitle() {
    final cat = _categoryMeta[_selectedCategoryIdx];
    return Opacity(
      opacity: _gridAnim.value.clamp(0.0, 1.0),
      child: Padding(
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
            key: ValueKey(_selectedCategoryIdx),
            children: [
              Container(
                width: 4.w,
                height: 20.h,
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
                '${_filteredImages.length} ta',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ COLORING GRID — staggered scale + fade ═══
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
        // Staggered animatsiya — har bir karta kechikish bilan paydo bo'ladi
        final delay = (i * 0.06).clamp(0.0, 0.5);
        final itemAnim = CurvedAnimation(
          parent: _gridChangeCtrl,
          curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        );
        
        return AnimatedBuilder(
          animation: Listenable.merge([_gridAnim, itemAnim]),
          builder: (ctx, child) {
            final introP = _gridAnim.value;
            final changeP = itemAnim.value;
            final progress = introP * changeP;
            
            return Transform.scale(
              scale: 0.7 + 0.3 * progress,
              child: Opacity(
                opacity: progress.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _AnimatedImageCard(
            img: img,
            number: i + 1,
            color: _categoryMeta[_selectedCategoryIdx].color,
            onTap: () {
              HapticFeedback.lightImpact();
              SoundService().playPop();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ColoringScreen(imageInfo: img),
              ));
            },
          ),
        );
      },
    );
  }
}

/// Animatsiyali rasm kartasi — bosilganda scale effekti
class _AnimatedImageCard extends StatefulWidget {
  final ColoringImageInfo img;
  final int number;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedImageCard({
    required this.img,
    required this.number,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedImageCard> createState() => _AnimatedImageCardState();
}

class _AnimatedImageCardState extends State<_AnimatedImageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _isPressed = true;
        _pressCtrl.reverse();
      },
      onTapUp: (_) {
        _isPressed = false;
        _pressCtrl.forward().then((_) => widget.onTap());
      },
      onTapCancel: () {
        _isPressed = false;
        _pressCtrl.forward();
      },
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (ctx, child) => Transform.scale(
          scale: _pressCtrl.value,
          child: child,
        ),
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
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Hero(
                            tag: 'coloring_${widget.img.id}',
                            child: Image.asset(widget.img.assetPath, fit: BoxFit.contain),
                          ),
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
                    Icon(
                      Icons.play_circle_filled_rounded,
                      size: 20.sp,
                      color: widget.color,
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

/// Kategoriya meta ma'lumotlari
class _CatMeta {
  final String name;
  final String emoji;
  final Color color;
  final Color darkColor;
  const _CatMeta(this.name, this.emoji, this.color, this.darkColor);
}
