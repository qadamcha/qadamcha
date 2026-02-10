import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/presentation/pages/content_list_page.dart';
import '../../../child/presentation/bloc/child_bloc.dart';

class ChildHomePage extends StatelessWidget {
  const ChildHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with child avatar
              _buildHeader(context),
              SizedBox(height: 24.h),
              
              // Time Remaining
              _buildTimeRemaining(context),
              SizedBox(height: 24.h),
              
              // Content Categories
              _buildContentCategories(context),
              SizedBox(height: 24.h),
              
              // Continue Watching
              _buildContinueWatching(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<ChildBloc, ChildState>(
      builder: (context, state) {
        final child = state.selectedChild;
        
        return Row(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundColor: child?.gender == 'girl' 
                  ? AppColors.kidPink 
                  : AppColors.kidBlue,
              child: Text(
                child?.name.isNotEmpty == true 
                    ? child!.name[0].toUpperCase() 
                    : '👶',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salom, ${child?.name ?? 'Do\'stim'}! 👋',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Bugun nima ko\'rmoqchisan?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeRemaining(BuildContext context) {
    return BlocBuilder<ChildBloc, ChildState>(
      builder: (context, state) {
        final child = state.selectedChild;
        final remaining = child?.remainingMinutes ?? 0;
        final total = child?.limits.weekdayMinutes ?? 60;
        final progress = remaining / total;
        
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: remaining > 10 
                ? AppColors.primaryGradient 
                : AppColors.sunsetGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '⏱️',
                    style: TextStyle(fontSize: 32.sp),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '$remaining min',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Bugungi qolgan vaqt',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 16.h),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8.h,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentCategories(BuildContext context) {
    final categories = [
      _CategoryItem(
        emoji: '📺',
        label: 'Multfilmlar',
        color: AppColors.kidBlue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContentListPage()),
        ),
      ),
      _CategoryItem(
        emoji: '🎮',
        label: 'O\'yinlar',
        color: AppColors.kidGreen,
        onTap: () {},
      ),
      _CategoryItem(
        emoji: '📚',
        label: 'Ertaklar',
        color: AppColors.kidPurple,
        onTap: () {},
      ),
      _CategoryItem(
        emoji: '🎵',
        label: 'Qo\'shiqlar',
        color: AppColors.kidYellow,
        onTap: () {},
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategoriyalar',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.5,
          children: categories.map((cat) => _CategoryCard(item: cat)).toList(),
        ),
      ],
    );
  }

  Widget _buildContinueWatching() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Davom ettirish',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                width: 80.w,
                height: 60.h,
                decoration: BoxDecoration(
                  gradient: AppColors.oceanGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text('🎬', style: TextStyle(fontSize: 28.sp)),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qiziqarli multfilm',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '12:30 / 25:00',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: 0.5,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 4.h,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem item;

  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: item.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: TextStyle(fontSize: 36.sp)),
            SizedBox(height: 8.h),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
