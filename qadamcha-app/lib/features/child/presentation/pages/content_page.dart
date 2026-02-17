import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/session_tracker.dart';
import '../bloc/child_bloc.dart';
import '../../../content/domain/entities/content_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/widgets/video_card.dart';
import '../../../content/presentation/pages/video_player_page.dart';

/// Content Page — Multfilmlar ekrani
/// Oxirgi ko'rilgan + Filtrlar (tab + tur + til + yosh) + GridView
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
  String? _selectedType;
  String? _selectedLanguage;
  int? _selectedAge;

  final _types = ["Ta'limiy", "O'zbek", 'Jahon'];
  final _typeValues = {"Ta'limiy": 'talimiy', "O'zbek": 'ozbek', 'Jahon': 'jahon'};

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
    // Multfilm vaqt tracking
    SessionTracker.instance.startSession('content');
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
    // Multfilm vaqt tracking to'xtatish va backendga yuborish
    final minutes = SessionTracker.instance.endSession('content');
    if (minutes > 0) {
      final childState = _childBloc.state;
      final childId = childState.selectedChild?.id;
      if (childId != null) {
        _childBloc.add(RecordActivityEvent(
          childId: childId,
          contentId: 'content_browse',
          activityType: 'video_watch',
          durationMinutes: minutes,
        ));
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  List<ContentEntity> _getFilteredContents(List<ContentEntity> contents) {
    var filtered = List<ContentEntity>.from(contents);

    // Tab filter
    if (_selectedTab == 1) {
      // "Yangi" — oxirgi 20 ta
      if (filtered.length > 20) {
        filtered = filtered.sublist(0, 20);
      }
    }

    // Type filter
    if (_selectedType != null) {
      final typeValue = _typeValues[_selectedType] ?? _selectedType!.toLowerCase();
      filtered = filtered.where((c) => c.type.toLowerCase() == typeValue).toList();
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

  int get _activeFilterCount {
    int count = 0;
    if (_selectedType != null) count++;
    if (_selectedLanguage != null) count++;
    if (_selectedAge != null) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  void _showFilterSheet() {
    String? tempType = _selectedType;
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
                    if (tempType != null || tempLang != null || tempAge != null)
                      GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            tempType = null;
                            tempLang = null;
                            tempAge = null;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
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

                // ==================== TUR FILTRI ====================
                Text(
                  '📺 Turi',
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
                  children: _types.map((type) {
                    final sel = tempType == type;
                    return GestureDetector(
                      onTap: () => setSheetState(() => tempType = sel ? null : type),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: sel ? AppColors.cartoonGradient : null,
                          color: sel ? null : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12.r),
                          border: sel ? null : Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          type,
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

                // ==================== TIL FILTRI ====================
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
                      child: Container(
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

                // ==================== YOSH FILTRI ====================
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
                      child: Container(
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
                      _selectedType = tempType;
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
                          color: AppColors.kidPink.withValues(alpha: 0.3),
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
                  // Filter button
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? AppColors.kidPink.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                        border: _hasActiveFilters
                            ? Border.all(color: AppColors.kidPink, width: 1.5)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20.sp,
                              color: _hasActiveFilters
                                  ? AppColors.kidPink
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (_hasActiveFilters)
                            Positioned(
                              top: 6.h,
                              right: 6.w,
                              child: Container(
                                width: 16.w,
                                height: 16.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.kidPink,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
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

            // Category Tabs
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
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

                  final filteredContents = _getFilteredContents(state.contents);

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
                        // Oxirgi ko'rilgan multfilm
                        if (_lastWatched != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '⏱ Oxirgi ko\'rilgan',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: AppColors.kidPink.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          'Davom etish ▶',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.kidPink,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  SizedBox(
                                    height: 220.h,
                                    child: VideoCard(
                                      content: _lastWatched!,
                                      onTap: () => _navigateToPlayer(context, _lastWatched!),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                ],
                              ),
                            ),
                          ),


                        // Active filters chips
                        if (_hasActiveFilters)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
                              child: Wrap(
                                spacing: 6.w,
                                runSpacing: 6.h,
                                children: [
                                  if (_selectedType != null)
                                    _buildFilterChip('📺 $_selectedType', () {
                                      setState(() => _selectedType = null);
                                    }),
                                  if (_selectedLanguage != null)
                                    _buildFilterChip(
                                      '${_languageEmojis[_selectedLanguage] ?? ""} $_selectedLanguage',
                                      () => setState(() => _selectedLanguage = null),
                                    ),
                                  if (_selectedAge != null)
                                    _buildFilterChip(
                                      '👶 ${_ageGroups.firstWhere((g) => _parseAgeGroup(g) == _selectedAge, orElse: () => '')} yosh',
                                      () => setState(() => _selectedAge = null),
                                    ),
                                ],
                              ),
                            ),
                          ),

                        // "Barcha multfilmlar" title
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16.w, bottom: 12.h),
                            child: Row(
                              children: [
                                Text(
                                  'Barcha multfilmlar',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                if (_hasActiveFilters || _selectedTab == 1)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.kidPink.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      '${filteredContents.length}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.kidPink,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Empty filter result
                        if (filteredContents.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40.w),
                              child: Column(
                                children: [
                                  Text('🔍', style: TextStyle(fontSize: 48.sp)),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'Bu filtr bo\'yicha multfilm topilmadi',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Grid
                        if (filteredContents.isNotEmpty)
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
                                  if (index >= filteredContents.length) return null;
                                  final content = filteredContents[index];
                                  return VideoCard(
                                    content: content,
                                    onTap: () => _navigateToPlayer(context, content),
                                  );
                                },
                                childCount: filteredContents.length,
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

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.kidPink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.kidPink.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
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

  Widget _buildLastWatchedCard(ContentEntity content) {
    return GestureDetector(
      onTap: () => _navigateToPlayer(context, content),
      child: Container(
        height: 90.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.kidPink.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.kidPink.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(14.r)),
              child: SizedBox(
                width: 130.w,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            content.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(gradient: AppColors.cartoonGradient),
                              child: const Center(child: Icon(Icons.movie_rounded, color: Colors.white54, size: 30)),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(gradient: AppColors.cartoonGradient),
                            child: const Center(child: Icon(Icons.movie_rounded, color: Colors.white54, size: 30)),
                          ),
                    // Duration badge
                    if (content.duration > 0)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            _formatDuration(content.duration),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 22.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      content.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (content.duration > 0) ...[
                          Icon(Icons.access_time_rounded, size: 13.sp, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            _formatDuration(content.duration),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(width: 10.w),
                        ],
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.kidPink.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'Davom etish ▶',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kidPink,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
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

  void _navigateToPlayer(BuildContext context, ContentEntity content) {
    // Oxirgi ko'rilgan sifatida saqlash
    setState(() {
      _lastWatched = content;
    });

    final streamUrl = content.streamUrl ??
        'https://vz-b4d1a082-e06.b-cdn.net/${content.videoId}/playlist.m3u8';

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
    if (seconds <= 0) return '';
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
