import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../content/domain/entities/content_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/widgets/bubble_video_card.dart';

/// Video Library — Playlistlar sahifasi
/// Videolarni category bo'yicha guruhlaydi (Masha, Booba, SpongeBob...)
/// Har bir guruh birinchi video thumbnailini playlist rasmi sifatida ishlatadi
class VideoLibraryPage extends StatelessWidget {
  const VideoLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ===== QIZIL HEADER =====
          Container(
            color: const Color(0xFF43A047),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Video Library',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== PLAYLIST LIST =====
          Expanded(
            child: BlocBuilder<ContentBloc, ContentState>(
              builder: (context, state) {
                if (state.contents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_outlined, size: 48.sp, color: const Color(0xFFBBBBBB)),
                        SizedBox(height: 16.h),
                        Text('Playlistlar topilmadi', style: TextStyle(fontSize: 16.sp, color: const Color(0xFF606060))),
                      ],
                    ),
                  );
                }

                // Series bo'yicha guruhlash
                final groups = <String, List<ContentEntity>>{};
                for (final c in state.contents) {
                  final key = c.series.isNotEmpty ? c.series : 'Boshqalar';
                  groups.putIfAbsent(key, () => []).add(c);
                }

                final playlists = groups.entries.toList()
                  ..sort((a, b) => b.value.length.compareTo(a.value.length));

                return ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                  itemCount: playlists.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (ctx, i) {
                    final entry = playlists[i];
                    final name = entry.key;
                    final videos = entry.value;
                    final cover = videos.first;

                    return InkWell(
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => _PlaylistDetailPage(
                            playlistName: name,
                            videos: videos,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Playlist cover — doira rasm
                            ClipOval(
                              child: SizedBox(
                                width: 72.w,
                                height: 72.w,
                                child: cover.thumbnailUrl != null && cover.thumbnailUrl!.isNotEmpty
                                    ? Image.network(
                                        cover.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        headers: const {'Referer': 'https://qadamcha.uz/'},
                                        errorBuilder: (_, __, ___) => _coverPlaceholder(name),
                                      )
                                    : _coverPlaceholder(name),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Playlist nomi va video soni
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F0F0F),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${videos.length} ta video',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF606060),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow
                            Icon(Icons.chevron_right_rounded, size: 24.sp, color: const Color(0xFFBBBBBB)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(String name) {
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFFF6D00),
      const Color(0xFF9C27B0),
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return Container(
      color: color.withOpacity(0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}

/// Tanlangan playlist videolari — inline player bilan
class _PlaylistDetailPage extends StatefulWidget {
  final String playlistName;
  final List<ContentEntity> videos;

  const _PlaylistDetailPage({
    required this.playlistName,
    required this.videos,
  });

  @override
  State<_PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<_PlaylistDetailPage> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  ContentEntity? _currentVideo;
  int? _currentIndex;
  bool _loading = false;
  bool _error = false;
  bool _videoCompleted = false;
  bool _showNextOverlay = false;
  int _nextCountdown = 5;
  Timer? _countdownTimer;
  DateTime? _sessionStart;

  // Pagination — 50 tadan ko'rsatish
  static const int _pageSize = 50;
  int _videoOffset = 0;
  late List<ContentEntity> _displayedVideos;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  void _loadPage(int offset) {
    final all = widget.videos;
    if (all.length <= _pageSize) {
      _displayedVideos = List.from(all);
    } else {
      _displayedVideos = [];
      for (int i = 0; i < _pageSize && i < all.length; i++) {
        final idx = (offset + i) % all.length;
        _displayedVideos.add(all[idx]);
      }
    }
    _videoOffset = offset;
  }

  void _loadNextPage() {
    final nextOffset = _videoOffset + _pageSize;
    setState(() {
      _loadPage(nextOffset >= widget.videos.length ? 0 : nextOffset);
    });
  }

  ContentEntity? get _nextContent {
    if (_currentIndex == null) return null;
    final nextIdx = _currentIndex! + 1;
    if (nextIdx >= _displayedVideos.length) return null;
    return _displayedVideos[nextIdx];
  }

  void _playVideo(int index) {
    // ✅ Oldingi video uchun activity tracking (yangi video boshlamasdan oldin)
    _trackCurrentVideo();
    _disposePlayer();
    final c = _displayedVideos[index];
    setState(() {
      _currentVideo = c;
      _currentIndex = index;
      _loading = true;
      _error = false;
      _videoCompleted = false;
      _showNextOverlay = false;
      _sessionStart = DateTime.now();
    });

    // ✅ Last watched saqlash (content_page kabi)
    LocalMonitoringService.instance.saveLastWatched({
      'id': c.id, 'title': c.title, 'type': c.type,
      'category': c.category, 'series': c.series,
      'videoId': c.videoId, 'streamUrl': c.streamUrl,
      'thumbnailUrl': c.thumbnailUrl, 'duration': c.duration,
      'views': c.views, 'likes': c.likes,
      'isFeatured': c.isFeatured, 'language': c.language,
      'ageMin': c.ageMin, 'ageMax': c.ageMax,
    });

    if (kDebugMode) print('▶️ [VideoLibrary] _playVideo: index=$index, title=${c.title}, series=${c.series}, id=${c.id}');

    final url = c.streamUrl ?? 'https://vz-b4d1a082-e06.b-cdn.net/${c.videoId}/playlist.m3u8';
    _initPlayer(url);
  }

  /// ✅ Joriy videoni monitoring'ga yozish
  void _trackCurrentVideo() {
    if (_currentVideo == null || _sessionStart == null) return;
    final dur = DateTime.now().difference(_sessionStart!);
    final title = _currentVideo!.series.isNotEmpty
        ? '${_currentVideo!.series} \u2014 ${_currentVideo!.title}'
        : _currentVideo!.title;
    if (kDebugMode) {
      print('📊 [VideoLibrary] _trackCurrentVideo:');
      print('   title=$title, duration=${dur.inSeconds}s, contentId=${_currentVideo!.id}');
    }
    LocalMonitoringService.instance.batchUpdate(
      seconds: dur.inSeconds,
      activityType: 'video_watch',
      contentTitle: title,
      durationMinutes: dur.inMinutes < 1 ? 1 : dur.inMinutes,
      contentId: _currentVideo!.id,
    );
    _sessionStart = null;
    if (kDebugMode) {
      print('   ✅ batchUpdate chaqirildi. videosWatched=${LocalMonitoringService.instance.videosWatched}');
    }
  }

  Future<void> _initPlayer(String url) async {
    try {
      _vpc = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'Referer': 'https://qadamcha.uz/'},
      );
      await _vpc!.initialize();
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
        );
        _loading = false;
        _videoCompleted = false;
      });
      _vpc!.addListener(_onProgress);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = true; });
    }
  }

  void _onProgress() {
    if (_videoCompleted) return;
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
      _videoCompleted = true;
      _startCountdown();
    }
  }

  OverlayEntry? _fullscreenOverlay;

  void _startCountdown() {
    final next = _nextContent;
    if (next == null) return;
    _nextCountdown = 5;
    _showNextOverlay = true;

    final isFS = _chewie != null && _chewie!.isFullScreen;
    if (isFS) {
      _showFullscreenOverlay(next);
    } else {
      setState(() {});
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      _nextCountdown--;
      if (isFS) {
        _fullscreenOverlay?.markNeedsBuild();
      } else {
        setState(() {});
      }
      if (_nextCountdown <= 0) { timer.cancel(); _playNextVideo(); }
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
                    child: Center(child: Text('$_nextCountdown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Nunito'))),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _cancelCountdown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Bekor', style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _playNextVideo,
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

  void _playNextVideo() {
    _removeFullscreenOverlay();
    final next = _nextContent;
    if (next == null || !mounted) return;
    if (_chewie != null && _chewie!.isFullScreen) {
      _chewie!.exitFullScreen();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _playVideo(_currentIndex! + 1);
      });
    } else {
      _playVideo(_currentIndex! + 1);
    }
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _removeFullscreenOverlay();
    setState(() => _showNextOverlay = false);
  }

  void _disposePlayer() {
    _countdownTimer?.cancel();
    _removeFullscreenOverlay();
    // ✅ Activity tracking — joriy video uchun
    _trackCurrentVideo();
    _vpc?.removeListener(_onProgress);
    _vpc?.dispose();
    _chewie?.dispose();
    _vpc = null;
    _chewie = null;
  }

  @override
  void dispose() {
    if (kDebugMode) print('🔴 [VideoLibrary] _PlaylistDetailPage dispose() chaqirildi');
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ===== HEADER =====
          Container(
            color: const Color(0xFF43A047),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          widget.playlistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: Text(
                          '${widget.videos.length} video',
                          style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== INLINE PLAYER =====
          if (_currentVideo != null) ...[
            Container(
              color: Colors.black,
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    if (_loading)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF43A047)))
                    else if (_error)
                      Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 48.sp))
                    else if (_chewie != null)
                      Positioned.fill(child: Chewie(controller: _chewie!))
                    else
                      const SizedBox.shrink(),

                    // Auto-next overlay — FULL video area
                    if (_showNextOverlay && _nextContent != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.92),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Keyingi video', style: TextStyle(fontSize: 12.sp, color: Colors.white54, fontFamily: 'Nunito')),
                              SizedBox(height: 8.h),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: Image.network(
                                  _nextContent!.thumbnailUrl ?? 'https://vz-b4d1a082-e06.b-cdn.net/${_nextContent!.videoId}/thumbnail.jpg',
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
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Text(
                                  _nextContent!.series.isNotEmpty
                                      ? '${_nextContent!.series} \u2014 ${_nextContent!.title}'
                                      : _nextContent!.title,
                                  maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito'),
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 36.w, height: 36.w,
                                    decoration: BoxDecoration(color: const Color(0xFF43A047).withOpacity(0.3), shape: BoxShape.circle),
                                    child: Center(child: Text('$_nextCountdown', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Nunito'))),
                                  ),
                                  SizedBox(width: 12.w),
                                  GestureDetector(
                                    onTap: _cancelCountdown,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8.r)),
                                      child: Text('Bekor', style: TextStyle(fontSize: 13.sp, color: Colors.white70, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap: _playNextVideo,
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
            // Info bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Text(
                _currentVideo!.series.isNotEmpty
                    ? '${_currentVideo!.series} \u2014 ${_currentVideo!.title}'
                    : _currentVideo!.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F0F0F)),
              ),
            ),
            Container(height: 1, color: const Color(0xFFE8E8E8)),
          ],

          // ===== VIDEO LIST =====
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadNextPage(),
              color: const Color(0xFF43A047),
              child: ListView.separated(
                padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                itemCount: _displayedVideos.length,
                separatorBuilder: (_, __) => SizedBox(height: 20.h),
                itemBuilder: (ctx, i) {
                  final c = _displayedVideos[i];
                  final isPlaying = _currentIndex == i;
                  return Opacity(
                    opacity: isPlaying ? 0.6 : 1.0,
                    child: BubbleVideoCard(
                      content: c,
                      onTap: () => _playVideo(i),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
