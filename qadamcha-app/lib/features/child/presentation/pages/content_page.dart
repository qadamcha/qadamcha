import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../bloc/child_bloc.dart';
import '../../../content/domain/entities/content_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/widgets/video_card.dart';
import '../../../content/presentation/pages/video_player_page.dart';

  /// Content Page — YouTube-style Multfilmlar ekrani
/// ✅ OPTIMIZED: Tab-level session tracking olib tashlandi
/// (phantom 1-min video_watch yaratardi — haqiqiy tracking VideoPlayerPage da ishlaydi)
class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final ScrollController _scrollController = ScrollController();

  // Category chips (YouTube-style horizontal pills)
  int _selectedCategory = 0;
  final _categories = [
    {'label': 'Barchasi', 'icon': '🔥', 'value': null},
    {'label': 'Yangi', 'icon': '✨', 'value': 'new'},
    {"label": "Ta'limiy", 'icon': '📚', 'value': 'talimiy'},
    {"label": "O'zbek", 'icon': '🇺🇿', 'value': 'ozbek'},
    {'label': 'Jahon', 'icon': '🌍', 'value': 'jahon'},
  ];

  // Advanced filter state
  String? _selectedLanguage;
  int? _selectedAge;

  final _languages = ["O'zbek tili", 'Rus tili', 'Ingliz tili'];
  final _languageValues = {"O'zbek tili": 'uz', 'Rus tili': 'ru', 'Ingliz tili': 'en'};
  final _languageEmojis = {"O'zbek tili": '🇺🇿', 'Rus tili': '🇷🇺', 'Ingliz tili': '🇬🇧'};

  final _ageGroups = ['3-5', '6-8', '9-12', '13+'];

  // Oxirgi ko'rilgan
  ContentEntity? _lastWatched;

  late final ChildBloc _childBloc;

  @override
  void initState() {
    super.initState();
    _childBloc = context.read<ChildBloc>();
    context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
    _scrollController.addListener(_onScroll);
    _loadLastWatched();
  }

  void _loadLastWatched() {
    final saved = LocalMonitoringService.instance.getLastWatched();
    if (saved != null) {
      try {
        setState(() {
          _lastWatched = ContentEntity(
            id: saved['id'] ?? '',
            title: saved['title'] ?? '',
            type: saved['type'] ?? 'cartoon',
            category: saved['category'] ?? '',
            videoId: saved['videoId'] ?? '',
            streamUrl: saved['streamUrl'],
            thumbnailUrl: saved['thumbnailUrl'],
            duration: saved['duration'] ?? 0,
            views: saved['views'] ?? 0,
            likes: saved['likes'] ?? 0,
            isFeatured: saved['isFeatured'] ?? false,
            language: saved['language'] ?? 'uz',
            ageMin: saved['ageMin'] ?? 3,
            ageMax: saved['ageMax'] ?? 12,
          );
        });
      } catch (_) {}
    }
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

  List<ContentEntity> _getFilteredContents(List<ContentEntity> contents) {
    var filtered = List<ContentEntity>.from(contents);

    // Category filter
    if (_selectedCategory > 0) {
      final categoryValue = _categories[_selectedCategory]['value'] as String?;
      if (categoryValue == 'new') {
        // Yangi — oxirgi 20 ta
        if (filtered.length > 20) {
          filtered = filtered.sublist(0, 20);
        }
      } else if (categoryValue != null) {
        filtered = filtered.where((c) => c.type.toLowerCase() == categoryValue).toList();
      }
    }

    // Language filter
    if (_selectedLanguage != null) {
      final langValue = _languageValues[_selectedLanguage] ?? 'uz';
      filtered = filtered.where((c) => c.language == langValue).toList();
    }

    // Age filter
    if (_selectedAge != null) {
      filtered = filtered.where((c) {
        return c.ageMin <= _selectedAge! && c.ageMax >= _selectedAge!;
      }).toList();
    }

    return filtered;
  }

  bool get _hasAdvancedFilters => _selectedLanguage != null || _selectedAge != null;

  void _showFilterSheet() {
    String? tempLang = _selectedLanguage;
    int? tempAge = _selectedAge;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🎯 Filtr',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    if (tempLang != null || tempAge != null)
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          tempLang = null;
                          tempAge = null;
                        }),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Tozalash',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20.h),

                // TIL FILTRI
                Text(
                  '🌐 Til',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _languages.map((lang) {
                    final sel = tempLang == lang;
                    final emoji = _languageEmojis[lang] ?? '';
                    return GestureDetector(
                      onTap: () => setSheetState(() => tempLang = sel ? null : lang),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: sel ? const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          ) : null,
                          color: sel ? null : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12.r),
                          border: sel ? null : Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          '$emoji $lang',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 18.h),

                // YOSH FILTRI
                Text(
                  '👶 Yosh',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _ageGroups.map((ageGroup) {
                    final ageVal = _parseAgeGroup(ageGroup);
                    final sel = tempAge == ageVal;
                    return GestureDetector(
                      onTap: () => setSheetState(() => tempAge = sel ? null : ageVal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: sel ? const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                          ) : null,
                          color: sel ? null : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12.r),
                          border: sel ? null : Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          '$ageGroup yosh',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),

                // Apply button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLanguage = tempLang;
                      _selectedAge = tempAge;
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: AppColors.cartoonGradient,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.kidPink.withOpacity(0.3),
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
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _parseAgeGroup(String group) {
    switch (group) {
      case '3-5': return 4;
      case '6-8': return 7;
      case '9-12': return 10;
      case '13+': return 13;
      default: return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER — YouTube-style =====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  // Logo/Title
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
                  // Filter button
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: _hasAdvancedFilters
                            ? AppColors.kidPink.withOpacity(0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                        border: _hasAdvancedFilters
                            ? Border.all(color: AppColors.kidPink, width: 1.5)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20.sp,
                              color: _hasAdvancedFilters
                                  ? AppColors.kidPink
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (_hasAdvancedFilters)
                            Positioned(
                              top: 6.h,
                              right: 6.w,
                              child: Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.kidPink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Refresh
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

            // ===== CATEGORY CHIPS — YouTube-style horizontal pills =====
            SizedBox(
              height: 42.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final selected = _selectedCategory == index;
                  final cat = _categories[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10.r),
                        border: selected
                            ? null
                            : Border.all(color: AppColors.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${cat['icon']} ${cat['label']}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 8.h),

            // ===== ACTIVE FILTER CHIPS =====
            if (_hasAdvancedFilters)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SizedBox(
                  height: 32.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_selectedLanguage != null)
                        _buildFilterChip(
                          '${_languageEmojis[_selectedLanguage] ?? ""} $_selectedLanguage',
                          () => setState(() => _selectedLanguage = null),
                        ),
                      if (_selectedAge != null)
                        _buildFilterChip(
                          '${_ageGroups.firstWhere((g) => _parseAgeGroup(g) == _selectedAge, orElse: () => '')} yosh',
                          () => setState(() => _selectedAge = null),
                        ),
                    ],
                  ),
                ),
              ),

            // ===== VIDEO FEED =====
            Expanded(
              child: BlocBuilder<ContentBloc, ContentState>(
                builder: (context, state) {
                  if (state.status == ContentStatus.loading && state.contents.isEmpty) {
                    return _buildSkeletonLoader();
                  }

                  if (state.status == ContentStatus.error && state.contents.isEmpty) {
                    return _buildErrorState(state);
                  }

                  final filteredContents = _getFilteredContents(state.contents);

                  if (state.contents.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
                    },
                    color: AppColors.kidPink,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _buildFeedItemCount(filteredContents, state),
                      itemBuilder: (context, index) {
                        return _buildFeedItem(context, index, filteredContents, state);
                      },
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

  // Feed items: [last watched] + [videos] + [loading indicator]
  int _buildFeedItemCount(List<ContentEntity> filtered, ContentState state) {
    int count = filtered.length;
    if (_lastWatched != null) count++; // oxirgi ko'rilgan
    if (state.status == ContentStatus.loading && state.contents.isNotEmpty) count++; // loader
    return count;
  }

  Widget _buildFeedItem(BuildContext context, int index, List<ContentEntity> filtered, ContentState state) {
    // Oxirgi ko'rilgan — birinchi element
    if (_lastWatched != null) {
      if (index == 0) {
        return _buildLastWatchedSection();
      }
      index -= 1;
    }

    // Loading indicator — oxirgi element
    if (index >= filtered.length) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.kidPink),
        ),
      );
    }

    // Video card — YouTube-style
    final content = filtered[index];
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: VideoCard(
        content: content,
        onTap: () => _navigateToPlayer(context, content, allContents: filtered, currentIndex: index),
      ),
    );
  }

  // ===== OXIRGI KO'RILGAN — YouTube "Continue watching" style =====
  Widget _buildLastWatchedSection() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.kidPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 14.sp, color: AppColors.kidPink),
                    SizedBox(width: 4.w),
                    Text(
                      'Davom etish',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kidPink,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildLastWatchedCard(_lastWatched!),
        ],
      ),
    );
  }

  Widget _buildLastWatchedCard(ContentEntity content) {
    return GestureDetector(
      onTap: () => _navigateToPlayer(context, content, allContents: [], currentIndex: 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.kidPink.withOpacity(0.15), width: 1.5),
        ),
        child: Row(
          children: [
            // Thumbnail — chap tomonda
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(11.r)),
              child: SizedBox(
                width: 140.w,
                height: 86.h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            content.thumbnailUrl!,
                            fit: BoxFit.cover,
                            headers: const {'Referer': 'https://qadamcha.uz/'},
                            errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(gradient: AppColors.cartoonGradient),
                              child: const Center(child: Icon(Icons.movie_rounded, color: Colors.white54, size: 30)),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(gradient: AppColors.cartoonGradient),
                            child: const Center(child: Icon(Icons.movie_rounded, color: Colors.white54, size: 30)),
                          ),
                    // Play overlay
                    Center(
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 20.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Duration badge
                    if (content.duration > 0)
                      Positioned(
                        bottom: 4.h,
                        right: 4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: Text(
                            _formatDuration(content.duration),
                            style: TextStyle(
                              fontSize: 9.sp,
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
            // Info — o'ng tomonda
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      content.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      content.category.isNotEmpty ? content.category : 'Multfilm',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
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

  // ===== SKELETON LOADER =====
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail skeleton
            Container(
              height: 190.h,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            SizedBox(height: 10.h),
            // Info skeleton
            Row(
              children: [
                // Avatar
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14.h,
                        width: 200.w,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: 12.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== ERROR STATE =====
  Widget _buildErrorState(ContentState state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 48.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'Xatolik yuz berdi',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              state.errorMessage ?? 'Internetni tekshiring',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () {
                context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: AppColors.cartoonGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Qayta yuklash',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📺', style: TextStyle(fontSize: 56.sp)),
          SizedBox(height: 16.h),
          Text(
            'Hozircha kontent yo\'q',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tez orada yangi multfilmlar qo\'shiladi!',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  // ===== FILTER CHIP =====
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.kidPink.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.kidPink.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.kidPink,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14.sp, color: AppColors.kidPink),
          ),
        ],
      ),
    );
  }

  // ===== NAVIGATION =====
  void _navigateToPlayer(BuildContext context, ContentEntity content, {List<ContentEntity>? allContents, int? currentIndex}) {
    setState(() {
      _lastWatched = content;
    });

    LocalMonitoringService.instance.saveLastWatched({
      'id': content.id,
      'title': content.title,
      'type': content.type,
      'category': content.category,
      'videoId': content.videoId,
      'streamUrl': content.streamUrl,
      'thumbnailUrl': content.thumbnailUrl,
      'duration': content.duration,
      'views': content.views,
      'likes': content.likes,
      'isFeatured': content.isFeatured,
      'language': content.language,
      'ageMin': content.ageMin,
      'ageMax': content.ageMax,
    });

    // addVideoWatched() O'CHIRILDI — VideoPlayerPage.dispose() dagi
    // batchUpdate(activityType: 'video_watch') allaqachon counter oshiradi

    final streamUrl = content.streamUrl ??
        'https://vz-b4d1a082-e06.b-cdn.net/${content.videoId}/playlist.m3u8';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(
          content: content,
          streamUrl: streamUrl,
          allContents: allContents,
          currentIndex: currentIndex,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
