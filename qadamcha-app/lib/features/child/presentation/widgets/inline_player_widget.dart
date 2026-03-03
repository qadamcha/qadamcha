import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../content/domain/entities/content_entity.dart';

/// HLS video sifat darajalari
class InlineQuality {
  final String label;
  final int height;
  final String url;
  const InlineQuality({required this.label, required this.height, required this.url});
}

/// Inline video player — HLS adaptive streaming bilan
class InlinePlayerWidget extends StatefulWidget {
  final ContentEntity content;
  final VoidCallback onClose;

  const InlinePlayerWidget({
    super.key,
    required this.content,
    required this.onClose,
  });

  @override
  State<InlinePlayerWidget> createState() => _InlinePlayerWidgetState();
}

class _InlinePlayerWidgetState extends State<InlinePlayerWidget> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  bool _loading = true;
  bool _error = false;
  DateTime? _sessionStart;
  List<InlineQuality> _qualities = [];
  InlineQuality? _currentQuality;

  @override
  void initState() {
    super.initState();
    _startPlayer();
  }

  @override
  void didUpdateWidget(covariant InlinePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.id != widget.content.id) {
      _startPlayer();
    }
  }

  @override
  void dispose() {
    _recordSession();
    _vpc?.dispose();
    _chewie?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _recordSession() {
    if (_sessionStart != null) {
      final dur = DateTime.now().difference(_sessionStart!);
      LocalMonitoringService.instance.batchUpdate(
        seconds: dur.inSeconds,
        activityType: 'video_watch',
        contentTitle: widget.content.title,
        durationMinutes: dur.inMinutes < 1 ? 1 : dur.inMinutes,
        contentId: widget.content.id,
      );
    }
  }

  Future<void> _startPlayer() async {
    _recordSession();
    _vpc?.dispose();
    _chewie?.dispose();
    setState(() {
      _loading = true;
      _error = false;
      _sessionStart = DateTime.now();
      _qualities = [];
      _currentQuality = null;
    });
    WakelockPlus.enable();

    final masterUrl = widget.content.streamUrl ??
        'https://vz-b4d1a082-e06.b-cdn.net/${widget.content.videoId}/playlist.m3u8';

    final qualities = await _parseHlsQualities(masterUrl);
    if (!mounted) return;
    setState(() {
      _qualities = qualities;
      _currentQuality = qualities.first;
    });

    await _initPlayer(_currentQuality!.url);
  }

  Future<List<InlineQuality>> _parseHlsQualities(String masterUrl) async {
    final baseUrl = masterUrl.substring(0, masterUrl.lastIndexOf('/'));
    final List<InlineQuality> qualities = [
      InlineQuality(label: 'Avtomatik', height: 0, url: masterUrl),
    ];
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
              qualities.add(InlineQuality(label: label, height: height, url: streamUri));
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

  Future<void> _initPlayer(String url) async {
    final oldPos = _vpc?.value.position;
    _vpc?.dispose();
    _chewie?.dispose();
    setState(() => _loading = true);
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
            if (_qualities.length > 1)
              OptionItem(
                onTap: (_) {
                  Navigator.pop(context);
                  _showQualityPicker();
                },
                iconData: Icons.hd_rounded,
                title: 'Sifat: ${_currentQuality?.label ?? "Avtomatik"}',
              ),
          ],
          errorBuilder: (ctx, msg) => Center(
            child: Icon(Icons.error_outline, color: Colors.white54, size: 48.sp),
          ),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

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
                child: Row(children: [
                  Icon(Icons.hd_rounded, color: const Color(0xFF43A047), size: 22.sp),
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
                ]),
              ),
              SizedBox(height: 12.h),
              ..._qualities.map((q) {
                final sel = q == _currentQuality;
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    if (q != _currentQuality) {
                      setState(() => _currentQuality = q);
                      _initPlayer(q.url);
                    }
                  },
                  leading: Icon(
                    sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: sel ? const Color(0xFF43A047) : Colors.white30,
                    size: 22.sp,
                  ),
                  title: Text(
                    q.label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : Colors.white70,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  trailing: q.height > 0
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: q.height >= 720
                                ? const Color(0xFF43A047).withValues(alpha: 0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            q.height >= 720 ? 'HD' : 'SD',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: q.height >= 720
                                  ? const Color(0xFF66BB6A)
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Video player
        Container(
          color: Colors.black,
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF43A047)))
                : _error
                    ? Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 48.sp))
                    : _chewie != null
                        ? Chewie(controller: _chewie!)
                        : const SizedBox.shrink(),
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
                  widget.content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFE8E8E8)),
      ],
    );
  }
}
