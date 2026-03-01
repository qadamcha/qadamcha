import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:qadamcha_app/features/content/domain/entities/content_entity.dart';
import '../../../../core/services/local_monitoring_service.dart';

/// Bunny.net HLS video player — sifat tanlash + vaqt ko'rsatish
/// ✅ Video ko'rish tracking: har bir video ochilganda session boshlanadi,
/// yopilganda endSession → batchUpdate → video_watch activity qayd qilinadi
class VideoPlayerPage extends StatefulWidget {
  final ContentEntity content;
  final String streamUrl;
  final List<ContentEntity>? allContents;
  final int? currentIndex;

  const VideoPlayerPage({
    super.key,
    required this.content,
    required this.streamUrl,
    this.allContents,
    this.currentIndex,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  /// Mavjud sifat variantlari (HLS dan parse qilinadi)
  List<_QualityOption> _qualities = [];
  _QualityOption? _currentQuality;
  bool _isLoading = true;
  bool _hasError = false;
  late final DateTime _sessionStart;

  // Auto-next
  bool _showNextOverlay = false;
  int _nextCountdown = 5;
  Timer? _countdownTimer;
  bool _videoCompleted = false;
  bool _isDisposing = false; // dispose vaqtida false trigger oldini olish
  bool _activityRecorded = false; // activity 2 marta yozilmasligi uchun

  ContentEntity? get _nextContent {
    if (widget.allContents == null || widget.currentIndex == null) return null;
    final nextIdx = widget.currentIndex! + 1;
    if (nextIdx >= widget.allContents!.length) return null;
    return widget.allContents![nextIdx];
  }

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    WakelockPlus.enable(); // Ekran o'chmasin
    _loadQualities();
  }

  /// HLS master playlist ni parse qilib, sifat variantlarini olish
  Future<void> _loadQualities() async {
    try {
      // Master playlist URL
      final masterUrl = widget.streamUrl;

      // Bunny.net HLS resolutions — standard format
      // playlist.m3u8 ichida har xil sifatlar bor
      final baseUrl = masterUrl.substring(0, masterUrl.lastIndexOf('/'));

      // Standart bunny.net HLS sifatlari
      final List<_QualityOption> qualities = [];

      try {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(masterUrl));
        request.headers.add('Referer', 'https://qadamcha.uz/');
        final response = await request.close();

        if (response.statusCode == 200) {
          final content =
              await response.transform(utf8.decoder).join();
          final lines = content.split('\n');

          for (int i = 0; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.startsWith('#EXT-X-STREAM-INF')) {
              // RESOLUTION va BANDWIDTH olish
              final resMatch =
                  RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
              final bwMatch =
                  RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);

              if (resMatch != null && i + 1 < lines.length) {
                final height = int.parse(resMatch.group(2)!);
                final bandwidth = bwMatch != null
                    ? int.parse(bwMatch.group(1)!)
                    : 0;
                var streamUri = lines[i + 1].trim();

                // Relative URL ni absolute qilish
                if (!streamUri.startsWith('http')) {
                  streamUri = '$baseUrl/$streamUri';
                }

                String label;
                if (height >= 1080) {
                  label = '1080p HD';
                } else if (height >= 720) {
                  label = '720p HD';
                } else if (height >= 480) {
                  label = '480p';
                } else if (height >= 360) {
                  label = '360p';
                } else {
                  label = '${height}p';
                }

                qualities.add(_QualityOption(
                  label: label,
                  height: height,
                  bandwidth: bandwidth,
                  url: streamUri,
                ));
              }
            }
          }
        }
      } catch (_) {
        // Playlist parse qilib bo'lmasa, to'g'ridan-to'g'ri master URL ishlatamiz
      }

      // Agar sifatlar topilmasa, default qilib master URL ishlatamiz
      if (qualities.isEmpty) {
        qualities.add(_QualityOption(
          label: 'Avtomatik',
          height: 0,
          bandwidth: 0,
          url: masterUrl,
        ));
      } else {
        // "Avtomatik" (adaptive) sifatni ham qo'shamiz
        qualities.insert(
          0,
          _QualityOption(
            label: 'Avtomatik',
            height: 0,
            bandwidth: 0,
            url: masterUrl,
          ),
        );
        // Height bo'yicha kamayish tartibida sort
        qualities.sort((a, b) {
          if (a.height == 0) return -1; // "Avtomatik" eng tepada
          if (b.height == 0) return 1;
          return b.height.compareTo(a.height);
        });
      }

      setState(() {
        _qualities = qualities;
        _currentQuality = qualities.first; // Avtomatik
      });

      await _initializePlayer(_currentQuality!.url);
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Video player ni boshlash (berilgan sifat URL bilan)
  Future<void> _initializePlayer(String url) async {
    // Agar avvalgi controller bo'lsa, tozalash
    final oldPosition = _videoPlayerController?.value.position;
    _videoPlayerController?.removeListener(_onVideoProgress);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    setState(() => _isLoading = true);

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'Referer': 'https://qadamcha.uz/'},
      );
      await _videoPlayerController!.initialize();

      // Agar oldin ko'rilayotgan bo'lsa, shu pozitsiyadan davom
      if (oldPosition != null && oldPosition > Duration.zero) {
        await _videoPlayerController!.seekTo(oldPosition);
      }

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
          placeholder: Container(color: Colors.black),
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF7C4DFF),
            handleColor: const Color(0xFFB388FF),
            bufferedColor: Colors.white30,
            backgroundColor: Colors.white12,
          ),
          additionalOptions: (context) => [
            OptionItem(
              onTap: (_) {
                Navigator.pop(context);
                _showQualityPicker();
              },
              iconData: Icons.hd_rounded,
              title: 'Sifat: ${_currentQuality?.label ?? "Avtomatik"}',
            ),
            OptionItem(
              onTap: (_) {
                Navigator.pop(context);
                _showPlaybackSpeedPicker();
              },
              iconData: Icons.speed_rounded,
              title: 'Tezlik',
            ),
          ],
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.white54, size: 48.sp),
                  SizedBox(height: 8.h),
                  Text(
                    'Videoni yuklab bo\'lmadi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
        _isLoading = false;
        _hasError = false;
      });

      // Video tugash listener qo'shish
      _videoCompleted = false;
      _videoPlayerController!.addListener(_onVideoProgress);
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Sifat tanlash bottom sheet
  void _showQualityPicker() {
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
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(Icons.hd_rounded,
                        color: const Color(0xFF7C4DFF), size: 22.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Video sifati',
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
              SizedBox(height: 12.h),

              // Quality options
              ..._qualities.map((q) {
                final isSelected = q == _currentQuality;
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    if (q != _currentQuality) {
                      setState(() => _currentQuality = q);
                      _initializePlayer(q.url);
                    }
                  },
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? const Color(0xFF7C4DFF)
                        : Colors.white30,
                    size: 22.sp,
                  ),
                  title: Text(
                    q.label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  trailing: q.height > 0
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: q.height >= 720
                                ? const Color(0xFF7C4DFF).withValues(alpha: 0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            q.height >= 720 ? 'HD' : 'SD',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: q.height >= 720
                                  ? const Color(0xFFB388FF)
                                  : Colors.white54,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        )
                      : null,
                );
              }),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Tezlik tanlash
  void _showPlaybackSpeedPicker() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentSpeed =
        _videoPlayerController?.value.playbackSpeed ?? 1.0;

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
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded,
                        color: const Color(0xFF7C4DFF), size: 22.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Ijro tezligi',
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
              SizedBox(height: 12.h),
              ...speeds.map((speed) {
                final isSelected = speed == currentSpeed;
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _videoPlayerController?.setPlaybackSpeed(speed);
                  },
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? const Color(0xFF7C4DFF)
                        : Colors.white30,
                    size: 22.sp,
                  ),
                  title: Text(
                    speed == 1.0 ? 'Normal' : '${speed}x',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontFamily: 'Nunito',
                    ),
                  ),
                );
              }),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposing = true;
    WakelockPlus.disable();
    _countdownTimer?.cancel();
    // Video yopilganda activity qayd qilish — FAQAT 1 MARTA
    if (!_activityRecorded) {
      _activityRecorded = true;
      final duration = DateTime.now().difference(_sessionStart);
      final minutes = duration.inMinutes < 1 ? 1 : duration.inMinutes;
      LocalMonitoringService.instance.batchUpdate(
        seconds: duration.inSeconds,
        activityType: 'video_watch',
        contentTitle: widget.content.title,
        durationMinutes: minutes,
        contentId: widget.content.id,
      );
    }

    _videoPlayerController?.removeListener(_onVideoProgress);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  /// Video progress listener — tugashini aniqlash
  void _onVideoProgress() {
    // Dispose vaqtida yoki allaqachon completed bo'lsa — o'tkazib yuborish
    if (_videoCompleted || _isDisposing) return;
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    // Minimum 5 soniya davomiylik bo'lishi kerak (false trigger oldini olish)
    if (duration < const Duration(seconds: 5)) return;

    // Video tugashiga 500ms qolganda trigger (HLS uchun !isPlaying shart emas)
    if (position >= duration - const Duration(milliseconds: 500)) {
      _videoCompleted = true;
      _startNextCountdown();
    }
  }

  /// 5 soniyalik countdown boshlash
  void _startNextCountdown() {
    final next = _nextContent;
    if (next == null) return; // Keyingi video yo'q

    setState(() {
      _showNextOverlay = true;
      _nextCountdown = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _nextCountdown--);
      if (_nextCountdown <= 0) {
        timer.cancel();
        _playNextVideo();
      }
    });
  }

  /// Keyingi videoga o'tish
  void _playNextVideo() {
    final next = _nextContent;
    if (next == null || !mounted) return;

    final nextIndex = widget.currentIndex! + 1;
    final streamUrl = next.streamUrl ??
        'https://vz-b4d1a082-e06.b-cdn.net/${next.videoId}/playlist.m3u8';

    // Video counter
    // addVideoWatched() o'chirildi — dispose() dagi batchUpdate allaqachon counter oshiradi

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(
          content: next,
          streamUrl: streamUrl,
          allContents: widget.allContents,
          currentIndex: nextIndex,
        ),
      ),
    );
  }

  /// Countdown bekor qilish
  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() => _showNextOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          widget.content.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Sifat tanlash tugmasi
                      if (_qualities.length > 1)
                        GestureDetector(
                          onTap: _showQualityPicker,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color:
                                    const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hd_rounded,
                                    color: const Color(0xFFB388FF), size: 16.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  _currentQuality?.label ?? 'Avto',
                                  style: TextStyle(
                                    color: const Color(0xFFB388FF),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
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

                // Video Player
                Expanded(
                  child: Center(
                    child: _buildPlayerContent(),
                  ),
                ),

                // Bottom info bar
                _buildBottomInfo(),
              ],
            ),

            // Auto-next countdown overlay
            if (_showNextOverlay && _nextContent != null)
              _buildNextVideoOverlay(),
          ],
        ),
      ),
    );
  }

  /// YouTube-style keyingi video overlay
  Widget _buildNextVideoOverlay() {
    final next = _nextContent!;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Keyingi video', style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white54,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                )),
                SizedBox(height: 14.h),

                // Next video thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    width: double.infinity,
                    height: 120.h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        next.thumbnailUrl != null && next.thumbnailUrl!.isNotEmpty
                            ? Image.network(
                                next.thumbnailUrl!,
                                fit: BoxFit.cover,
                                headers: const {'Referer': 'https://qadamcha.uz/'},
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF2A2A4A),
                                  child: const Center(child: Icon(Icons.movie_rounded, color: Colors.white24, size: 40)),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF2A2A4A),
                                child: const Center(child: Icon(Icons.movie_rounded, color: Colors.white24, size: 40)),
                              ),
                        // Countdown overlay
                        Center(
                          child: Container(
                            width: 56.w,
                            height: 56.w,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 50.w,
                                  height: 50.w,
                                  child: CircularProgressIndicator(
                                    value: _nextCountdown / 5,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.white12,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                                  ),
                                ),
                                Text(
                                  '$_nextCountdown',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
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
                ),
                SizedBox(height: 12.h),

                // Next video title
                Text(
                  next.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 16.h),

                // Buttons
                Row(
                  children: [
                    // Bekor qilish
                    Expanded(
                      child: GestureDetector(
                        onTap: _cancelCountdown,
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text('Bekor qilish', style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              fontFamily: 'Nunito',
                            )),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Hozir o'ynash
                    Expanded(
                      child: GestureDetector(
                        onTap: _playNextVideo,
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF5C2DDF)],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text('Hozir o\'ynash', style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                            )),
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
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF7C4DFF)),
          SizedBox(height: 16.h),
          Text(
            'Video yuklanmoqda...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14.sp,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      );
    }

    if (_hasError) {
      return Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.white38, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'Videoni yuklab bo\'lmadi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Internet aloqangizni tekshiring',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13.sp,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () => _loadQualities(),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Qayta urinish',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }

    return const CircularProgressIndicator(color: Color(0xFF7C4DFF));
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: Row(
        children: [
          // Duration
          if (widget.content.duration > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded,
                      color: Colors.white70, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDuration(widget.content.duration),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Sifat badge
          if (_currentQuality != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                _currentQuality!.height >= 720
                    ? 'HD'
                    : _currentQuality!.height > 0
                        ? 'SD'
                        : 'AUTO',
                style: TextStyle(
                  color: const Color(0xFFB388FF),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Sifat varianti modeli
class _QualityOption {
  final String label;
  final int height;
  final int bandwidth;
  final String url;

  const _QualityOption({
    required this.label,
    required this.height,
    required this.bandwidth,
    required this.url,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _QualityOption &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}
