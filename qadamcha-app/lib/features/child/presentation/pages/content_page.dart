import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../content/domain/entities/content_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/widgets/bubble_video_card.dart';
import 'video_library_page.dart';

/// KidsTube 1:1 — Bosh sahifa
/// Qizil header bar, to'liq kenglikda video kartochkalar
class ContentPage extends StatefulWidget {
  final bool isActive;

  const ContentPage({super.key, this.isActive = true});

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

  final _languages = ["O'zbek tili", 'Rus tili', 'Ingliz tili'];
  final _languageValues = {"O'zbek tili": 'uz', 'Rus tili': 'ru', 'Ingliz tili': 'en'};
  final _languageEmojis = {"O'zbek tili": '🇺🇿', 'Rus tili': '🇷🇺', 'Ingliz tili': '🇬🇧'};
  final _ageGroups = ['3-5', '6-8', '9-12', '13+'];

  ContentEntity? _lastWatched;

  // ===== INLINE VIDEO PLAYER =====
  ContentEntity? _inlineContent;
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  bool _inlineLoading = false;
  bool _inlineError = false;
  DateTime? _inlineSessionStart;
  List<_InlineQuality> _inlineQualities = [];
  _InlineQuality? _currentInlineQuality;

  // Auto-next for inline
  List<ContentEntity>? _inlineAllContents;
  int? _inlineCurrentIndex;
  bool _inlineVideoCompleted = false;
  bool _showInlineNextOverlay = false;
  int _inlineNextCountdown = 5;
  Timer? _inlineCountdownTimer;
  OverlayEntry? _fullscreenOverlay;

  // Overscroll debounce (bir marta ishlagandan keyin 1 soniya kutish)
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
    _scrollController.addListener(_onScroll);
    _loadLastWatched();
  }

  @override
  void didUpdateWidget(covariant ContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tab o'zgarganda — video pause/close qilish
    if (oldWidget.isActive && !widget.isActive && _inlineContent != null) {
      _closeInlinePlayer();
    }
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
            series: saved['series'] ?? '',
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
    // Overscroll bilan ishlaydi — _handleOverscroll() quyida
  }

  /// YouTube/Instagram-style overscroll: oxirga yetib, yana pastga tortganda
  /// 10 ta yangi video qo'shiladi, boshidan 10 ta olib tashlanadi
  void _handleOverscroll(OverscrollNotification notification) {
    // Faqat pastga overscroll (notification.overscroll > 0)
    if (notification.overscroll <= 0) return;
    if (_isSliding) return;

    final state = context.read<ContentBloc>().state;
    if (state.allContents.length <= state.windowSize) return;

    _isSliding = true;
    context.read<ContentBloc>().add(const SlideWindowEvent());

    // Scroll'ni biroz tepaga qaytarish (yangi videolarni ko'rsatish uchun)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent - 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 1 soniya debounce — tez-tez ishlamaslik uchun
    Future.delayed(const Duration(seconds: 1), () {
      _isSliding = false;
    });
  }

  @override
  void dispose() {
    _disposeInlinePlayer();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeInlinePlayer() {
    _inlineCountdownTimer?.cancel();
    _removeFullscreenOverlay();
    if (_inlineContent != null && _inlineSessionStart != null) {
      final dur = DateTime.now().difference(_inlineSessionStart!);
      final title = _inlineContent!.series.isNotEmpty
          ? '${_inlineContent!.series} \u2014 ${_inlineContent!.title}'
          : _inlineContent!.title;
      LocalMonitoringService.instance.batchUpdate(
        seconds: dur.inSeconds,
        activityType: 'video_watch',
        contentTitle: title,
        durationMinutes: dur.inMinutes < 1 ? 1 : dur.inMinutes,
        contentId: _inlineContent!.id,
      );
    }
    _vpc?.removeListener(_onInlineProgress);
    _vpc?.dispose();
    _chewie?.dispose();
    _vpc = null;
    _chewie = null;
    WakelockPlus.disable();
  }

  Future<void> _startInlinePlayer(ContentEntity c, {List<ContentEntity>? allContents, int? currentIndex}) async {
    _disposeInlinePlayer();
    setState(() {
      _inlineContent = c;
      _inlineLoading = true;
      _inlineError = false;
      _inlineSessionStart = DateTime.now();
      _inlineQualities = [];
      _currentInlineQuality = null;
      _inlineAllContents = allContents;
      _inlineCurrentIndex = currentIndex;
      _inlineVideoCompleted = false;
      _showInlineNextOverlay = false;
    });
    WakelockPlus.enable();
    final masterUrl = c.streamUrl ?? 'https://vz-b4d1a082-e06.b-cdn.net/${c.videoId}/playlist.m3u8';

    // Parse HLS qualities
    final qualities = await _parseHlsQualities(masterUrl);
    if (!mounted) return;
    setState(() {
      _inlineQualities = qualities;
      _currentInlineQuality = qualities.first;
    });

    await _initInlinePlayer(_currentInlineQuality!.url);
  }

  Future<List<_InlineQuality>> _parseHlsQualities(String masterUrl) async {
    final baseUrl = masterUrl.substring(0, masterUrl.lastIndexOf('/'));
    final List<_InlineQuality> qualities = [_InlineQuality(label: 'Avtomatik', height: 0, url: masterUrl)];
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(masterUrl));
      request.headers.add('Referer', 'https://qadamcha.uz/');
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('#EXT-X-STREAM-INF')) {
            final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
            if (resMatch != null && i + 1 < lines.length) {
              final height = int.parse(resMatch.group(2)!);
              var streamUri = lines[i + 1].trim();
              if (!streamUri.startsWith('http')) streamUri = '$baseUrl/$streamUri';
              String label;
              if (height >= 1080) { label = '1080p HD'; }
              else if (height >= 720) { label = '720p HD'; }
              else if (height >= 480) { label = '480p'; }
              else if (height >= 360) { label = '360p'; }
              else { label = '${height}p'; }
              qualities.add(_InlineQuality(label: label, height: height, url: streamUri));
            }
          }
        }
      }
    } catch (_) {}
    qualities.sort((a, b) {
      if (a.height == 0) return -1;
      if (b.height == 0) return 1;
      return b.height.compareTo(a.height);
    });
    return qualities;
  }

  Future<void> _initInlinePlayer(String url) async {
    final oldPos = _vpc?.value.position;
    _vpc?.dispose();
    _chewie?.dispose();
    setState(() => _inlineLoading = true);
    try {
      _vpc = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'Referer': 'https://qadamcha.uz/'},
      );
      await _vpc!.initialize();
      if (oldPos != null && oldPos > Duration.zero) {
        await _vpc!.seekTo(oldPos);
      }
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: _vpc!,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
          placeholder: Container(color: Colors.black),
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF43A047),
            handleColor: const Color(0xFF66BB6A),
            bufferedColor: Colors.white30,
            backgroundColor: Colors.white12,
          ),
          additionalOptions: (context) => [
            if (_inlineQualities.length > 1)
              OptionItem(
                onTap: (_) { Navigator.pop(context); _showInlineQualityPicker(); },
                iconData: Icons.hd_rounded,
                title: 'Sifat: ${_currentInlineQuality?.label ?? "Avtomatik"}',
              ),
          ],
          errorBuilder: (ctx, msg) => Center(
            child: Icon(Icons.error_outline, color: Colors.white54, size: 48.sp),
          ),
        );
        _inlineLoading = false;
        _inlineVideoCompleted = false;
      });
      // Video tugash listeneri qo'shish
      _vpc!.addListener(_onInlineProgress);
    } catch (e) {
      if (!mounted) return;
      setState(() { _inlineLoading = false; _inlineError = true; });
    }
  }

  void _showInlineQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(margin: EdgeInsets.only(top: 12.h), width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.r))),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(children: [
                  Icon(Icons.hd_rounded, color: const Color(0xFF43A047), size: 22.sp),
                  SizedBox(width: 8.w),
                  Text('Video sifati', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito')),
                ]),
              ),
              SizedBox(height: 12.h),
              ..._inlineQualities.map((q) {
                final sel = q == _currentInlineQuality;
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    if (q != _currentInlineQuality) {
                      setState(() => _currentInlineQuality = q);
                      _initInlinePlayer(q.url);
                    }
                  },
                  leading: Icon(sel ? Icons.check_circle_rounded : Icons.circle_outlined, color: sel ? const Color(0xFF43A047) : Colors.white30, size: 22.sp),
                  title: Text(q.label, style: TextStyle(fontSize: 15.sp, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? Colors.white : Colors.white70, fontFamily: 'Nunito')),
                  trailing: q.height > 0 ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(color: q.height >= 720 ? const Color(0xFF43A047).withValues(alpha: 0.2) : Colors.white10, borderRadius: BorderRadius.circular(6.r)),
                    child: Text(q.height >= 720 ? 'HD' : 'SD', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: q.height >= 720 ? const Color(0xFF66BB6A) : Colors.white54, fontFamily: 'Nunito')),
                  ) : null,
                );
              }),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  void _closeInlinePlayer() {
    _inlineCountdownTimer?.cancel();
    _disposeInlinePlayer();
    setState(() {
      _inlineContent = null;
      _inlineSessionStart = null;
      _inlineAllContents = null;
      _inlineCurrentIndex = null;
      _showInlineNextOverlay = false;
    });
  }

  // ===== INLINE AUTO-NEXT =====
  ContentEntity? get _inlineNextContent {
    if (_inlineAllContents == null || _inlineCurrentIndex == null) return null;
    final nextIdx = _inlineCurrentIndex! + 1;
    if (nextIdx >= _inlineAllContents!.length) return null;
    return _inlineAllContents![nextIdx];
  }

  void _onInlineProgress() {
    if (_inlineVideoCompleted) return;
    final controller = _vpc;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    final position = value.position;
    final duration = value.duration;
    if (duration < const Duration(seconds: 5)) return;

    bool completed = false;
    if (!value.isPlaying && position > Duration.zero &&
        position >= duration - const Duration(seconds: 2)) {
      completed = true;
    }
    if (position >= duration - const Duration(milliseconds: 500)) {
      completed = true;
    }

    if (completed) {
      _inlineVideoCompleted = true;
      _startInlineNextCountdown();
    }
  }

  void _startInlineNextCountdown() {
    final next = _inlineNextContent;
    if (next == null) return;
    _inlineNextCountdown = 5;
    _showInlineNextOverlay = true;

    // Fullscreen bo'lsa OverlayEntry ko'rsatish
    final isFS = _chewie != null && _chewie!.isFullScreen;
    if (isFS) {
      _showFullscreenOverlay(next);
    } else {
      setState(() {});
    }

    _inlineCountdownTimer?.cancel();
    _inlineCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      _inlineNextCountdown--;
      if (isFS) {
        _fullscreenOverlay?.markNeedsBuild();
      } else {
        setState(() {});
      }
      if (_inlineNextCountdown <= 0) {
        timer.cancel();
        _playNextInline();
      }
    });
  }

  void _showFullscreenOverlay(ContentEntity next) {
    _removeFullscreenOverlay();
    _fullscreenOverlay = OverlayEntry(
      builder: (_) => _buildFullscreenNextOverlay(next),
    );
    Overlay.of(context).insert(_fullscreenOverlay!);
  }

  void _removeFullscreenOverlay() {
    _fullscreenOverlay?.remove();
    _fullscreenOverlay = null;
  }

  Widget _buildFullscreenNextOverlay(ContentEntity next) {
    final thumbUrl = next.thumbnailUrl ?? 'https://vz-b4d1a082-e06.b-cdn.net/${next.videoId}/thumbnail.jpg';
    return Material(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Keyingi video', style: TextStyle(fontSize: 12, color: Colors.white54, fontFamily: 'Nunito')),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumbUrl, width: 150, height: 84, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 150, height: 84, color: Colors.white10,
                    child: const Icon(Icons.play_circle_outline, color: Colors.white38, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  next.series.isNotEmpty ? '${next.series} \u2014 ${next.title}' : next.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF43A047).withOpacity(0.3), shape: BoxShape.circle),
                    child: Center(child: Text('$_inlineNextCountdown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Nunito'))),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _cancelInlineCountdown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Bekor', style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _playNextInline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF43A047), borderRadius: BorderRadius.circular(8)),
                      child: const Text('\u25B6 Boshlash', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playNextInline() {
    _removeFullscreenOverlay();
    final next = _inlineNextContent;
    if (next == null || !mounted) return;
    // Fullscreen rejimidan chiqish
    if (_chewie != null && _chewie!.isFullScreen) {
      _chewie!.exitFullScreen();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final nextIndex = _inlineCurrentIndex! + 1;
        _navigate(context, next, allContents: _inlineAllContents, currentIndex: nextIndex);
      });
    } else {
      final nextIndex = _inlineCurrentIndex! + 1;
      _navigate(context, next, allContents: _inlineAllContents, currentIndex: nextIndex);
    }
  }

  void _cancelInlineCountdown() {
    _inlineCountdownTimer?.cancel();
    _removeFullscreenOverlay();
    setState(() => _showInlineNextOverlay = false);
  }

  List<ContentEntity> _getFiltered(List<ContentEntity> contents) {
    var filtered = List<ContentEntity>.from(contents);
    if (_selectedCategory > 0) {
      final val = _categories[_selectedCategory]['value'];
      if (val == 'new') {
        // Eng yangi videolar — hammasini ko'rsat
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

  bool get _hasFilters => _selectedLanguage != null || _selectedAge != null;

  int _parseAge(String g) {
    switch (g) { case '3-5': return 4; case '6-8': return 7; case '9-12': return 10; case '13+': return 13; default: return 5; }
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, ss) {
            final state = context.read<ContentBloc>().state;
            final results = query.isEmpty ? <ContentEntity>[] : state.allContents.where((c) => c.title.toLowerCase().contains(query.toLowerCase())).toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, MediaQuery.of(ctx).viewInsets.bottom + 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2.r)))),
                  SizedBox(height: 12.h),
                  TextField(
                    autofocus: true,
                    onChanged: (v) => ss(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'Qidirish...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF606060)),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                  ),
                  if (results.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 300.h,
                      child: ListView.separated(
                        itemCount: results.length > 10 ? 10 : results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F2F2)),
                        itemBuilder: (_, i) {
                          final c = results[i];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6.r),
                              child: SizedBox(
                                width: 64.w, height: 40.h,
                                child: c.thumbnailUrl != null && c.thumbnailUrl!.isNotEmpty
                                    ? Image.network(c.thumbnailUrl!, fit: BoxFit.cover, headers: const {'Referer': 'https://qadamcha.uz/'}, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE5E5E5)))
                                    : Container(color: const Color(0xFFE5E5E5)),
                              ),
                            ),
                            title: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                            onTap: () { Navigator.pop(ctx); _navigate(context, c, allContents: state.allContents, currentIndex: state.allContents.indexOf(c)); },
                          );
                        },
                      ),
                    ),
                  ],
                  if (query.isNotEmpty && results.isEmpty) ...[
                    SizedBox(height: 24.h),
                    Text('Topilmadi 😔', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF606060))),
                    SizedBox(height: 24.h),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilters() {
    String? tmpL = _selectedLanguage;
    int? tmpA = _selectedAge;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(ctx).padding.bottom + 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2.r)))),
              SizedBox(height: 16.h),
              Row(children: [
                Text('Filtr', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F0F0F))),
                const Spacer(),
                if (tmpL != null || tmpA != null)
                  GestureDetector(onTap: () => ss(() { tmpL = null; tmpA = null; }), child: Text('Tozalash', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF43A047)))),
              ]),
              SizedBox(height: 16.h),
              Text('Til', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 8.h),
              Wrap(spacing: 8.w, runSpacing: 8.h, children: _languages.map((l) {
                final s = tmpL == l;
                return GestureDetector(onTap: () => ss(() => tmpL = s ? null : l), child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(color: s ? const Color(0xFF43A047) : const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(20.r)),
                  child: Text('${_languageEmojis[l] ?? ''} $l', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: s ? Colors.white : const Color(0xFF0F0F0F))),
                ));
              }).toList()),
              SizedBox(height: 16.h),
              Text('Yosh', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              SizedBox(height: 8.h),
              Wrap(spacing: 8.w, runSpacing: 8.h, children: _ageGroups.map((g) {
                final v = _parseAge(g); final s = tmpA == v;
                return GestureDetector(onTap: () => ss(() => tmpA = s ? null : v), child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(color: s ? const Color(0xFF43A047) : const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(20.r)),
                  child: Text('$g yosh', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: s ? Colors.white : const Color(0xFF0F0F0F))),
                ));
              }).toList()),
              SizedBox(height: 20.h),
              SizedBox(width: double.infinity, height: 48.h, child: ElevatedButton(
                onPressed: () { setState(() { _selectedLanguage = tmpL; _selectedAge = tmpA; }); Navigator.pop(ctx); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43A047), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)), elevation: 0),
                child: Text('Qo\'llash', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _inlineContent == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _inlineContent != null) {
          _closeInlinePlayer();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ====== QIZIL HEADER BAR (KidsTube 1:1) ======
          Container(
            color: const Color(0xFF43A047),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [

                      // App name
                      Text(
                        'Qadamcha',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      // Search
                      IconButton(
                        onPressed: _showSearch,
                        icon: Icon(Icons.search_rounded, color: Colors.white, size: 24.sp),
                      ),
                      // Video library
                      IconButton(
                        onPressed: () {
                          _closeInlinePlayer();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoLibraryPage()));
                        },
                        icon: Icon(Icons.video_library_rounded, color: Colors.white, size: 24.sp),
                      ),
                      // Filter
                      IconButton(
                        onPressed: _showFilters,
                        icon: Stack(
                          children: [
                            Icon(Icons.tune_rounded, color: Colors.white, size: 24.sp),
                            if (_hasFilters) Positioned(top: 0, right: 0, child: Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(color: Color(0xFFFFEB3B), shape: BoxShape.circle))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ====== CATEGORY CHIPS ======
          Container(
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
          ),

          // Active filters
          if (_hasFilters)
            Container(
              color: Colors.white,
              height: 32.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                children: [
                  if (_selectedLanguage != null) _chip('${_languageEmojis[_selectedLanguage] ?? ''} $_selectedLanguage', () => setState(() => _selectedLanguage = null)),
                  if (_selectedAge != null) _chip('${_ageGroups.firstWhere((g) => _parseAge(g) == _selectedAge, orElse: () => '')} yosh', () => setState(() => _selectedAge = null)),
                ],
              ),
            ),

          // ====== INLINE VIDEO PLAYER ======
          if (_inlineContent != null)
            _buildInlinePlayer(),

          // ====== VIDEO FEED ======
          Expanded(
            child: BlocBuilder<ContentBloc, ContentState>(
              builder: (context, state) {
                if (state.status == ContentStatus.loading && state.windowContents.isEmpty) return _skeleton();
                if (state.status == ContentStatus.error && state.windowContents.isEmpty) return _error(state);
                final filtered = _getFiltered(state.windowContents);
                if (state.windowContents.isEmpty) return _empty();

                return NotificationListener<OverscrollNotification>(
                  onNotification: (notification) {
                    _handleOverscroll(notification);
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
                    },
                    color: const Color(0xFF43A047),
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                      itemCount: _itemCount(filtered, state),
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (ctx, i) => _buildItem(ctx, i, filtered, state),
                    ),
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

  int _itemCount(List<ContentEntity> f, ContentState s) {
    int n = f.length;
    if (_lastWatched != null && _inlineContent == null) n++;
    if (s.status == ContentStatus.loading && s.windowContents.isNotEmpty) n++;
    return n;
  }

  Widget _buildItem(BuildContext ctx, int i, List<ContentEntity> f, ContentState s) {
    if (_lastWatched != null && _inlineContent == null) {
      if (i == 0) return _continueCard();
      i -= 1;
    }
    if (i >= f.length) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: Color(0xFF43A047))));
    }
    final c = f[i];
    return BubbleVideoCard(content: c, onTap: () => _navigate(ctx, c, allContents: f, currentIndex: i));
  }

  Widget _continueCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(children: [
            Icon(Icons.history_rounded, size: 16.sp, color: const Color(0xFF606060)),
            SizedBox(width: 4.w),
            Text('Davom etish', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: const Color(0xFF606060))),
          ]),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () => _navigate(context, _lastWatched!, allContents: [], currentIndex: 0),
          child: Row(
            children: [
              SizedBox(width: 16.w),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 140.w, height: 80.h,
                  child: _lastWatched!.thumbnailUrl != null && _lastWatched!.thumbnailUrl!.isNotEmpty
                      ? Image.network(_lastWatched!.thumbnailUrl!, fit: BoxFit.cover, headers: const {'Referer': 'https://qadamcha.uz/'}, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE5E5E5)))
                      : Container(color: const Color(0xFFE5E5E5)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lastWatched!.series.isNotEmpty
                        ? '${_lastWatched!.series} \u2014 ${_lastWatched!.title}'
                        : _lastWatched!.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0F0F0F), height: 1.3)),
                    SizedBox(height: 4.h),
                    Text(_lastWatched!.series.isNotEmpty ? _lastWatched!.series : (_lastWatched!.category.isNotEmpty ? _lastWatched!.category : 'Multfilm'), style: TextStyle(fontSize: 12.sp, color: const Color(0xFF606060))),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16.w), child: Divider(height: 24.h, color: const Color(0xFFE8E8E8))),
      ],
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
      child: Padding(padding: EdgeInsets.all(32.w), child: Column(
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
      )),
    );
  }

  Widget _empty() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_library_outlined, size: 48.sp, color: const Color(0xFFBBBBBB)),
        SizedBox(height: 16.h),
        Text('Hozircha kontent yo\'q', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F0F0F))),
        SizedBox(height: 8.h),
        Text('Tez orada yangi multfilmlar qo\'shiladi!', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF606060))),
      ],
    ));
  }

  void _navigate(BuildContext ctx, ContentEntity c, {List<ContentEntity>? allContents, int? currentIndex}) {
    setState(() => _lastWatched = c);
    LocalMonitoringService.instance.saveLastWatched({
      'id': c.id, 'title': c.title, 'type': c.type, 'category': c.category, 'series': c.series,
      'videoId': c.videoId, 'streamUrl': c.streamUrl, 'thumbnailUrl': c.thumbnailUrl,
      'duration': c.duration, 'views': c.views, 'likes': c.likes,
      'isFeatured': c.isFeatured, 'language': c.language, 'ageMin': c.ageMin, 'ageMax': c.ageMax,
    });
    final wasPlaying = _inlineContent != null;
    _startInlinePlayer(c, allContents: allContents, currentIndex: currentIndex);
    // Faqat birinchi marta ochilganda scroll qilsin
    if (!wasPlaying) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Widget _buildInlinePlayer() {
    return Column(
      children: [
        // Video player with auto-next overlay ON TOP
        Container(
          color: Colors.black,
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // Video content
                if (_inlineLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF43A047)))
                else if (_inlineError)
                  Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 48.sp))
                else if (_chewie != null)
                  Positioned.fill(child: Chewie(controller: _chewie!))
                else
                  const SizedBox.shrink(),

                // Auto-next overlay — FULL video area
                if (_showInlineNextOverlay && _inlineNextContent != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.92),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Keyingi video', style: TextStyle(fontSize: 12.sp, color: Colors.white54, fontFamily: 'Nunito')),
                          SizedBox(height: 8.h),
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: Image.network(
                              _inlineNextContent!.thumbnailUrl ?? 'https://vz-b4d1a082-e06.b-cdn.net/${_inlineNextContent!.videoId}/thumbnail.jpg',
                              width: 160.w, height: 90.w,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 160.w, height: 90.w,
                                color: Colors.white10,
                                child: Icon(Icons.play_circle_outline, color: Colors.white38, size: 40.sp),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          // Title
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              _inlineNextContent!.series.isNotEmpty
                                  ? '${_inlineNextContent!.series} \u2014 ${_inlineNextContent!.title}'
                                  : _inlineNextContent!.title,
                              maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito'),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          // Countdown + buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36.w, height: 36.w,
                                decoration: BoxDecoration(color: const Color(0xFF43A047).withOpacity(0.3), shape: BoxShape.circle),
                                child: Center(child: Text('$_inlineNextCountdown', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Nunito'))),
                              ),
                              SizedBox(width: 12.w),
                              GestureDetector(
                                onTap: _cancelInlineCountdown,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8.r)),
                                  child: Text('Bekor', style: TextStyle(fontSize: 13.sp, color: Colors.white70, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: _playNextInline,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                                  decoration: BoxDecoration(color: const Color(0xFF43A047), borderRadius: BorderRadius.circular(8.r)),
                                  child: Text('\u25B6 Boshlash', style: TextStyle(fontSize: 13.sp, color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
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
        ),
        // Compact info bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _inlineContent!.series.isNotEmpty
                      ? '${_inlineContent!.series} \u2014 ${_inlineContent!.title}'
                      : _inlineContent!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F0F0F)),
                ),
              ),
            ],
          ),
        ),
        // Divider
        Container(height: 1, color: const Color(0xFFE8E8E8)),
      ],
    );
  }
}

class _InlineQuality {
  final String label;
  final int height;
  final String url;
  const _InlineQuality({required this.label, required this.height, required this.url});
}
