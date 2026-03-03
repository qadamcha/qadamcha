import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../content/domain/entities/content_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/widgets/bubble_video_card.dart';
import '../widgets/inline_player_widget.dart';
import '../widgets/content_search_sheet.dart';
import '../widgets/content_filter_sheet.dart';
import '../widgets/continue_watching_card.dart';
import 'video_library_page.dart';

/// KidsTube 1:1 — Bosh sahifa
/// Yashil header bar, to'liq kenglikda video kartochkalar
class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final ScrollController _scrollController = ScrollController();
  int _selectedCategory = 0;

  final _categories = [
    {'label': 'Barchasi', 'icon': '🔥', 'value': null},
    {'label': 'Yangi', 'icon': '✨', 'value': 'new'},
    {"label": "Ta'limiy", 'icon': '📚', 'value': 'talimiy'},
    {"label": "O'zbek", 'icon': '🇺🇿', 'value': 'ozbek'},
    {'label': 'Jahon', 'icon': '🌍', 'value': 'jahon'},
  ];

  String? _selectedLanguage;
  int? _selectedAge;

  static const _languageValues = {"O'zbek tili": 'uz', 'Rus tili': 'ru', 'Ingliz tili': 'en'};
  static const _languageEmojis = {"O'zbek tili": '🇺🇿', 'Rus tili': '🇷🇺', 'Ingliz tili': '🇬🇧'};
  static const _ageGroups = ['3-5', '6-8', '9-12', '13+'];

  ContentEntity? _lastWatched;
  ContentEntity? _inlineContent;

  @override
  void initState() {
    super.initState();
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
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

  bool get _hasFilters => _selectedLanguage != null || _selectedAge != null;

  int _parseAge(String g) {
    switch (g) {
      case '3-5': return 4;
      case '6-8': return 7;
      case '9-12': return 10;
      case '13+': return 13;
      default: return 5;
    }
  }

  List<ContentEntity> _getFiltered(List<ContentEntity> contents) {
    var filtered = List<ContentEntity>.from(contents);
    if (_selectedCategory > 0) {
      final val = _categories[_selectedCategory]['value'];
      if (val == 'new') {
        if (filtered.length > 20) filtered = filtered.sublist(0, 20);
      } else if (val != null) {
        filtered = filtered.where((c) => c.type.toLowerCase() == val).toList();
      }
    }
    if (_selectedLanguage != null) {
      final langVal = _languageValues[_selectedLanguage] ?? 'uz';
      filtered = filtered.where((c) => c.language == langVal).toList();
    }
    if (_selectedAge != null) {
      filtered = filtered.where((c) => c.ageMin <= _selectedAge! && c.ageMax >= _selectedAge!).toList();
    }
    return filtered;
  }

  void _showSearch() {
    final state = context.read<ContentBloc>().state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => ContentSearchSheet(
        contents: state.contents,
        onSelect: (c, all, idx) => _navigate(context, c, allContents: all, currentIndex: idx),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => ContentFilterSheet(
        selectedLanguage: _selectedLanguage,
        selectedAge: _selectedAge,
        onApply: (lang, age) => setState(() {
          _selectedLanguage = lang;
          _selectedAge = age;
        }),
      ),
    );
  }

  void _navigate(
    BuildContext ctx,
    ContentEntity c, {
    List<ContentEntity>? allContents,
    int? currentIndex,
  }) {
    setState(() {
      _lastWatched = c;
      _inlineContent = c;
    });
    LocalMonitoringService.instance.saveLastWatched({
      'id': c.id, 'title': c.title, 'type': c.type, 'category': c.category,
      'videoId': c.videoId, 'streamUrl': c.streamUrl, 'thumbnailUrl': c.thumbnailUrl,
      'duration': c.duration, 'views': c.views, 'likes': c.likes,
      'isFeatured': c.isFeatured, 'language': c.language, 'ageMin': c.ageMin, 'ageMax': c.ageMax,
    });
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _closeInlinePlayer() {
    setState(() => _inlineContent = null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _inlineContent == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _inlineContent != null) _closeInlinePlayer();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ====== HEADER BAR ======
            _buildHeader(),
            // ====== CATEGORY CHIPS ======
            _buildCategoryChips(),
            // Active filters
            if (_hasFilters) _buildActiveFilters(),
            // ====== INLINE VIDEO PLAYER ======
            if (_inlineContent != null)
              InlinePlayerWidget(
                key: ValueKey(_inlineContent!.id),
                content: _inlineContent!,
                onClose: _closeInlinePlayer,
              ),
            // ====== VIDEO FEED ======
            Expanded(child: _buildVideoFeed()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF43A047),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  'Qadamcha',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                ),
                const Spacer(),
                IconButton(onPressed: _showSearch, icon: Icon(Icons.search_rounded, color: Colors.white, size: 24.sp)),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoLibraryPage())),
                  icon: Icon(Icons.video_library_rounded, color: Colors.white, size: 24.sp),
                ),
                IconButton(
                  onPressed: _showFilters,
                  icon: Stack(children: [
                    Icon(Icons.tune_rounded, color: Colors.white, size: 24.sp),
                    if (_hasFilters)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(color: Color(0xFFFFEB3B), shape: BoxShape.circle)),
                      ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      height: 48.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final sel = _selectedCategory == i;
          final cat = _categories[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF0F0F0F) : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: sel ? Colors.transparent : const Color(0xFFD4D4D4)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${cat['icon']} ${cat['label']}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: sel ? Colors.white : const Color(0xFF0F0F0F)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      color: Colors.white,
      height: 32.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: [
          if (_selectedLanguage != null)
            _chip(
              '${_languageEmojis[_selectedLanguage] ?? ''} $_selectedLanguage',
              () => setState(() => _selectedLanguage = null),
            ),
          if (_selectedAge != null)
            _chip(
              '${_ageGroups.firstWhere((g) => _parseAge(g) == _selectedAge, orElse: () => '')} yosh',
              () => setState(() => _selectedAge = null),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF43A047))),
        SizedBox(width: 4.w),
        GestureDetector(onTap: onRemove, child: Icon(Icons.close_rounded, size: 14.sp, color: const Color(0xFF43A047))),
      ]),
    );
  }

  Widget _buildVideoFeed() {
    return BlocBuilder<ContentBloc, ContentState>(
      builder: (context, state) {
        if (state.status == ContentStatus.loading && state.contents.isEmpty) return _skeleton();
        if (state.status == ContentStatus.error && state.contents.isEmpty) return _error(state);
        final filtered = _getFiltered(state.contents);
        if (state.contents.isEmpty) return _empty();

        final hasLastWatched = _lastWatched != null && _inlineContent == null;
        final isLoadingMore = state.status == ContentStatus.loading && state.contents.isNotEmpty;
        final itemCount = filtered.length + (hasLastWatched ? 1 : 0) + (isLoadingMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () async => context.read<ContentBloc>().add(const LoadContentEvent(refresh: true)),
          color: const Color(0xFF43A047),
          child: ListView.separated(
            controller: _scrollController,
            padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
            itemCount: itemCount,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (ctx, i) {
              if (hasLastWatched) {
                if (i == 0) {
                  return ContinueWatchingCard(
                    content: _lastWatched!,
                    onTap: () => _navigate(context, _lastWatched!, allContents: [], currentIndex: 0),
                  );
                }
                i -= 1;
              }
              if (i >= filtered.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF43A047))),
                );
              }
              final c = filtered[i];
              return BubbleVideoCard(
                content: c,
                onTap: () => _navigate(ctx, c, allContents: filtered, currentIndex: i),
              );
            },
          ),
        );
      },
    );
  }

  Widget _skeleton() {
    return ListView.separated(
      padding: EdgeInsets.only(top: 8.h),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(height: 24.h),
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 200.h, color: const Color(0xFFF2F2F2)),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Container(height: 16.h, width: 250.w, color: const Color(0xFFF2F2F2)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: Container(height: 14.h, width: 180.w, color: const Color(0xFFF2F2F2)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
            child: Row(children: [
              Container(width: 40.w, height: 40.w, decoration: const BoxDecoration(color: Color(0xFFF2F2F2), shape: BoxShape.circle)),
              SizedBox(width: 12.w),
              Container(height: 14.h, width: 140.w, color: const Color(0xFFF2F2F2)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _error(ContentState state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48.sp, color: const Color(0xFFBBBBBB)),
            SizedBox(height: 16.h),
            Text('Xatolik yuz berdi', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F0F0F))),
            SizedBox(height: 8.h),
            Text(state.errorMessage ?? 'Internetni tekshiring', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: const Color(0xFF606060))),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => context.read<ContentBloc>().add(const LoadContentEvent(refresh: true)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43A047), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)), elevation: 0),
              child: const Text('Qayta yuklash', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 48.sp, color: const Color(0xFFBBBBBB)),
          SizedBox(height: 16.h),
          Text('Hozircha kontent yo\'q', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F0F0F))),
          SizedBox(height: 8.h),
          Text('Tez orada yangi multfilmlar qo\'shiladi!', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF606060))),
        ],
      ),
    );
  }
}
