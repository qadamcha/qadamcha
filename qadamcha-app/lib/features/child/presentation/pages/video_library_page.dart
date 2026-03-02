import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../content/domain/entities/content_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/widgets/bubble_video_card.dart';
import '../../../content/presentation/pages/video_player_page.dart';

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

                // Category bo'yicha guruhlash
                final groups = <String, List<ContentEntity>>{};
                for (final c in state.contents) {
                  final key = c.category.isNotEmpty ? c.category : 'Boshqalar';
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

/// Tanlangan playlist videolari (masalan: faqat "Masha and The Bear")
class _PlaylistDetailPage extends StatelessWidget {
  final String playlistName;
  final List<ContentEntity> videos;

  const _PlaylistDetailPage({
    required this.playlistName,
    required this.videos,
  });

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
                      Expanded(
                        child: Text(
                          playlistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: Text(
                          '${videos.length} video',
                          style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== VIDEO LIST =====
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
              itemCount: videos.length,
              separatorBuilder: (_, __) => SizedBox(height: 20.h),
              itemBuilder: (ctx, i) {
                final c = videos[i];
                return BubbleVideoCard(
                  content: c,
                  onTap: () {
                    final url = c.streamUrl ?? 'https://vz-b4d1a082-e06.b-cdn.net/${c.videoId}/playlist.m3u8';
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerPage(
                          content: c,
                          streamUrl: url,
                          allContents: videos,
                          currentIndex: i,
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
}
