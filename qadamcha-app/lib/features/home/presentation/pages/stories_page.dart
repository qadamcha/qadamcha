import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';

/// Ertaklar sahifasi — full_architecture.html dizaynida
/// O'zbek, Jahon, Islomiy ertaklar + statistika
class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  int _selectedCategory = 0;

  final _categories = ['Barchasi', 'O\'zbek', 'Jahon', 'Islomiy'];

  final _stories = [
    _Story(emoji: '🦊', title: 'Tulki bilan quyoncha', category: 'O\'zbek', pages: 12, color: AppColors.kidOrange),
    _Story(emoji: '🦁', title: 'Arslon va sichqoncha', category: 'Jahon', pages: 8, color: AppColors.kidYellow),
    _Story(emoji: '🐢', title: 'Quyon va toshbaqa', category: 'Jahon', pages: 10, color: AppColors.kidGreen),
    _Story(emoji: '🌙', title: 'Baxt qushi', category: 'Islomiy', pages: 15, color: AppColors.kidPurple),
    _Story(emoji: '🏔️', title: 'Alpomish', category: 'O\'zbek', pages: 25, color: AppColors.kidBlue),
    _Story(emoji: '📿', title: 'Sabr darvozasi', category: 'Islomiy', pages: 14, color: AppColors.kidPurple),
    _Story(emoji: '🐺', title: 'Uch og\'a-ini', category: 'Jahon', pages: 12, color: AppColors.kidPink),
    _Story(emoji: '🌾', title: 'Mehnatsevar Bolalar', category: 'O\'zbek', pages: 10, color: AppColors.kidGreen),
    _Story(emoji: '⭐', title: 'Yulduzli tun', category: 'Islomiy', pages: 18, color: AppColors.kidYellow),
  ];

  List<_Story> get _filteredStories {
    if (_selectedCategory == 0) return _stories;
    return _stories.where((s) => s.category == _categories[_selectedCategory]).toList();
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
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    '📖 Ertaklar',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),

            // Stats row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  _StatChip(label: '200+ ertak', emoji: '📚', color: AppColors.kidBlue),
                  SizedBox(width: 8.w),
                  _StatChip(label: '50+ audio', emoji: '🎧', color: AppColors.kidPurple),
                  SizedBox(width: 8.w),
                  _StatChip(label: '30+ interaktiv', emoji: '✨', color: AppColors.kidGreen),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Categories
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final selected = _selectedCategory == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.primaryGradient : null,
                        color: selected ? null : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _categories[index],
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

            // Stories grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: _filteredStories.length,
                itemBuilder: (context, index) {
                  return _StoryCard(story: _filteredStories[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Story {
  final String emoji;
  final String title;
  final String category;
  final int pages;
  final Color color;

  const _Story({
    required this.emoji,
    required this.title,
    required this.category,
    required this.pages,
    required this.color,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;

  const _StatChip({required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 16.sp)),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final _Story story;

  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: story.color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: story.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(story.emoji, style: TextStyle(fontSize: 32.sp)),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              story.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: story.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  story.category,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: story.color,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                '${story.pages} sahifa',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
