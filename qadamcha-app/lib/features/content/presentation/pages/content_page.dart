import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qadamcha_app/core/theme/app_colors.dart';
import 'package:qadamcha_app/features/content/presentation/bloc/content_bloc.dart';
import 'package:qadamcha_app/features/content/presentation/pages/video_player_page.dart';
import 'package:qadamcha_app/features/content/presentation/widgets/video_card.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadContent();
  }

  void _loadContent() {
    context.read<ContentBloc>().add(const LoadContentEvent());
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ContentBloc>().add(LoadMoreContentEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'Kontent',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: BlocBuilder<ContentBloc, ContentState>(
                builder: (context, state) {
                  if (state.status == ContentStatus.loading && state.contents.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == ContentStatus.error && state.contents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
                          SizedBox(height: 16.h),
                          Text(
                            state.errorMessage ?? 'Xatolik yuz berdi',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _loadContent,
                            child: const Text('Qayta urinish'),
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
                          Icon(Icons.videocam_off_outlined, size: 48.sp, color: AppColors.textSecondary),
                          SizedBox(height: 16.h),
                          Text(
                            'Hozircha hech qanday kontent yo\'q',
                            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ContentBloc>().add(const LoadContentEvent(refresh: true));
                    },
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                      ),
                      itemCount: state.hasReachedMax
                          ? state.contents.length
                          : state.contents.length + 1,
                      itemBuilder: (context, index) {
                        if (index >= state.contents.length) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final content = state.contents[index];
                        return VideoCard(
                          content: content,
                          onTap: () {
                            if (content.streamUrl != null && content.streamUrl!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerPage(
                                    content: content,
                                    streamUrl: content.streamUrl!,
                                  ),
                                ),
                              );
                            } else if (content.videoId.isNotEmpty) {
                               // Fallback if backend doesn't send streamUrl (masalan eski versiya)
                               const cdnHostname = "vz-cb48e060-a0f.b-cdn.net";
                               final streamUrl = "https://$cdnHostname/${content.videoId}/playlist.m3u8";
                               
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerPage(
                                    content: content,
                                    streamUrl: streamUrl,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Video topilmadi')),
                              );
                            }
                          },
                        );
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
}
