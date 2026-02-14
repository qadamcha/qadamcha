import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/content_bloc.dart';
import '../widgets/video_card.dart';

/// Content List Page — Video/Kontent ro'yxati
/// Bolalar uchun multfilm, o'yin, hikoya va boshqa kontentlar
class ContentListPage extends StatefulWidget {
  const ContentListPage({super.key});

  @override
  State<ContentListPage> createState() => _ContentListPageState();
}

class _ContentListPageState extends State<ContentListPage> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Barchasi', 'emoji': '\u{1F3AC}'},
    {'id': 'cartoon', 'name': 'Multfilm', 'emoji': '\u{1F9F8}'},
    {'id': 'game', 'name': "O'yin", 'emoji': '\u{1F3AE}'},
    {'id': 'story', 'name': 'Hikoya', 'emoji': '\u{1F4D6}'},
    {'id': 'quest', 'name': 'Topshiriq', 'emoji': '\u{2B50}'},
  ];

  @override
  void initState() {
    super.initState();
    _loadContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadContent() {
    context.read<ContentBloc>().add(LoadContentEvent(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      refresh: true,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ContentBloc>().add(LoadMoreContentEvent());
    }
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    context.read<ContentBloc>().add(LoadContentEvent(
      category: category == 'all' ? null : category,
      refresh: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kontent',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 50.h,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () => _onCategoryChanged(cat['id']!),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Center(
                        child: Text(
                          '${cat['emoji']} ${cat['name']}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
          // Content grid
          Expanded(
            child: BlocBuilder<ContentBloc, ContentState>(
              builder: (context, state) {
                if (state.status == ContentStatus.loading &&
                    state.contents.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == ContentStatus.error &&
                    state.contents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\u{1F61E}',
                          style: TextStyle(fontSize: 48.sp),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          state.errorMessage ?? 'Xatolik yuz berdi',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
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
                        Text(
                          '\u{1F4ED}',
                          style: TextStyle(fontSize: 48.sp),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Hozircha kontent yo\'q',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadContent(),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: state.contents.length +
                        (state.hasReachedMax ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= state.contents.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final content = state.contents[index];
                      return VideoCard(
                        content: content,
                        onTap: () {
                          // TODO: Navigate to video player
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Video: ${content.title}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
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
    );
  }
}
