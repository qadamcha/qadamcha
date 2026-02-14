import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/content_entity.dart';
import '../bloc/content_bloc.dart';
import '../widgets/video_card.dart';
import 'video_player_page.dart';

/// Content Page — full_architecture.html "Multfilmlar" ekraniga moslangan
/// Featured video + kategoriya chipta + GridView
/// Mavjud BLoC logika va video streaming to'liq saqlanadi
class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final ScrollController _scrollController = ScrollController();
  int _selectedTab = 0;
  final _tabs = ['Barchasi', 'Yangi'];

  // Filter state
  String? _selectedAge;
  String? _selectedLanguage;
  String? _selectedType;

  final _ages = ['0-3 yosh', '3-6 yosh', '6-9 yosh', '9-12 yosh'];
  final _languages = ["O'zbekcha", 'Ruscha', 'Inglizcha'];
  final _types = ['Ertak', "Ta'limiy", 'Komediya'];

  @override
  void initState() {
    super.initState();
    context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final state = context.read<ContentBloc>().state;
      if (state.status == ContentStatus.loaded && !state.hasReachedMax) {
        context.read<ContentBloc>().add(const LoadContentEvent());
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    '🎬 Multfilmlar',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 22.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Tabs + Filter
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  // Tabs
                  Expanded(
                    child: SizedBox(
                      height: 40.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final selected = _selectedTab == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTab = index),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 22.w),
                              decoration: BoxDecoration(
                                gradient: selected ? AppColors.cartoonGradient : null,
                                color: selected ? null : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _tabs[index],
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : AppColors.textSecondary,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Filter button
                  GestureDetector(
                    onTap: () => _showFilterSheet(context),
                    child: Container(
                      height: 40.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20.r),
                        border: _hasActiveFilters
                            ? Border.all(color: AppColors.primary.withOpacity(0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18.sp,
                            color: _hasActiveFilters
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Filtr',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: _hasActiveFilters
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          if (_activeFilterCount > 0) ...[
                            SizedBox(width: 4.w),
                            Container(
                              width: 18.w,
                              height: 18.w,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_activeFilterCount',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Content
            Expanded(
              child: BlocBuilder<ContentBloc, ContentState>(
                builder: (context, state) {
                  if (state.status == ContentStatus.loading && state.contents.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (state.status == ContentStatus.error && state.contents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('😔', style: TextStyle(fontSize: 48.sp)),
                          SizedBox(height: 12.h),
                          Text(
                            'Xatolik yuz berdi',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            state.errorMessage ?? '',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(height: 20.h),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: const Text('Qayta yuklash'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.contents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📺', style: TextStyle(fontSize: 48.sp)),
                          SizedBox(height: 12.h),
                          Text(
                            'Hozircha kontent yo\'q',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Featured Video (first item)
                        if (state.contents.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: _buildFeaturedVideo(state.contents.first),
                            ),
                          ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16.w, top: 20.h, bottom: 12.h),
                            child: Text(
                              'Barcha multfilmlar',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ),

                        // Grid
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12.w,
                              mainAxisSpacing: 12.h,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // Skip first item since it's featured
                                final contentIndex = index + 1;
                                if (contentIndex >= state.contents.length) {
                                  return null;
                                }
                                final content = state.contents[contentIndex];
                                return VideoCard(
                                  content: content,
                                  onTap: () => _navigateToPlayer(context, content),
                                );
                              },
                              childCount: (state.contents.length - 1).clamp(0, state.contents.length),
                            ),
                          ),
                        ),

                        // Loading indicator
                        if (state.status == ContentStatus.loading && state.contents.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                          ),

                        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedVideo(ContentEntity content) {
    return GestureDetector(
      onTap: () => _navigateToPlayer(context, content),
      child: Container(
        height: 200.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.kidPink.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail or gradient
              content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      content.thumbnailUrl!,
                      fit: BoxFit.cover,
                      headers: const {'Referer': 'https://qadamcha.uz/'},
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.cartoonGradient),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(gradient: AppColors.cartoonGradient),
                    ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Play button
              Center(
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 32.sp,
                    color: Colors.white,
                  ),
                ),
              ),

              // Info
              Positioned(
                bottom: 16.h,
                left: 16.w,
                right: 16.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.kidPink,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '🔥 Tavsiya etiladi',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      content.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),

              // Duration badge
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _formatDuration(content.duration),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPlayer(BuildContext context, ContentEntity content) {
    final streamUrl = content.streamUrl ??
        'https://vz-b4d1a082-e06.b-cdn.net/c2b79c51-2c48-4453-9c33-0e5104e7dfc1/playlist.m3u8';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(
          content: content,
          streamUrl: streamUrl,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool get _hasActiveFilters =>
      _selectedAge != null || _selectedLanguage != null || _selectedType != null;

  int get _activeFilterCount =>
      (_selectedAge != null ? 1 : 0) +
      (_selectedLanguage != null ? 1 : 0) +
      (_selectedType != null ? 1 : 0);

  void _showFilterSheet(BuildContext context) {
    String? tempAge = _selectedAge;
    String? tempLang = _selectedLanguage;
    String? tempType = _selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),

                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🎛️ Filtr',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      if (tempAge != null || tempLang != null || tempType != null)
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              tempAge = null;
                              tempLang = null;
                              tempType = null;
                            });
                          },
                          child: Text(
                            'Tozalash',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Age filter
                  _buildFilterSection(
                    '👶 Yosh',
                    _ages,
                    tempAge,
                    (val) => setSheetState(() => tempAge = tempAge == val ? null : val),
                  ),

                  SizedBox(height: 16.h),

                  // Language filter
                  _buildFilterSection(
                    '🌐 Til',
                    _languages,
                    tempLang,
                    (val) => setSheetState(() => tempLang = tempLang == val ? null : val),
                  ),

                  SizedBox(height: 16.h),

                  // Type filter
                  _buildFilterSection(
                    '🎬 Tur',
                    _types,
                    tempType,
                    (val) => setSheetState(() => tempType = tempType == val ? null : val),
                  ),

                  SizedBox(height: 24.h),

                  // Apply button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAge = tempAge;
                        _selectedLanguage = tempLang;
                        _selectedType = tempType;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Qo\'llash',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selected,
    ValueChanged<String> onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () => onTap(opt),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.r),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
