import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/session_tracker.dart';
import '../../../child/presentation/bloc/child_bloc.dart';
import '../../../child/presentation/pages/content_page.dart';
import '../../../child/presentation/pages/games_page.dart';
import '../../../auth/presentation/pages/role_selection_page.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';

/// Child Home Page — full_architecture.html dizaynida
/// Gradient fon + 2 ta katta kategoriya: Multfilmlar va O'yinlar
/// Obuna tekshirishi bilan — obuna bo'lmasa kiritilmaydi
/// Umumiy vaqt tracking: kirishda boshlaydi, chiqishda to'xtaydi
class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  @override
  void initState() {
    super.initState();
    // Umumiy vaqt tracking boshlash
    SessionTracker.instance.startSession('child_home');
  }

  @override
  void dispose() {
    // Tracking to'xtatish va backendga yuborish
    final minutes = SessionTracker.instance.endSession('child_home');
    if (minutes > 0) {
      final childState = context.read<ChildBloc>().state;
      final childId = childState.selectedChild?.id;
      if (childId != null) {
        context.read<ChildBloc>().add(RecordActivityEvent(
          childId: childId,
          contentId: 'app_session',
          activityType: 'app_usage',
          durationMinutes: minutes,
        ));
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        if (!subState.isPremium) {
          return _buildNoSubscriptionScreen(context);
        }
        return _buildMainScreen(context);
      },
    );
  }

  // ─── No Subscription Screen ───────────────────────────────────────────
  Widget _buildNoSubscriptionScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE0E0), Color(0xFFFFF5F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('\u{1F512}', style: TextStyle(fontSize: 48.sp)),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Text(
                    'Obuna faol emas',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  SizedBox(height: 12.h),

                  Text(
                    'Multfilmlar va o\'yinlardan foydalanish uchun\nota-ona panelidan obunani faollashtiring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 36.h),

                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Orqaga qaytish',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  // ─── Main Screen (with subscription) ──────────────────────────────────
  Widget _buildMainScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.childHomeGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 28.h),

                Text(
                  'Nima qilmoqchisan? \u{1F3AF}',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 16.h),

                _buildCategoryCard(
                  context,
                  emoji: '\u{1F3AC}',
                  title: 'Multfilmlar',
                  subtitle: 'Qiziqarli multiklar ko\'rish',
                  gradient: AppColors.cartoonGradient,
                  itemCount: '100+',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContentPage()),
                  ),
                ),
                SizedBox(height: 16.h),
                _buildCategoryCard(
                  context,
                  emoji: '\u{1F3AE}',
                  title: 'O\'yinlar',
                  subtitle: 'Ta\'limiy o\'yinlar o\'ynash',
                  gradient: AppColors.gamesGradient,
                  itemCount: '50+',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GamesPage()),
                  ),
                ),
                SizedBox(height: 28.h),

                _buildContinueWatching(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<ChildBloc, ChildState>(
      builder: (context, state) {
        final name = state.selectedChild?.name ?? 'Bolajon';
        return Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
              ),
              child: Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18.sp,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text('\u{1F476}', style: TextStyle(fontSize: 26.sp)),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salom! \u{1F31F}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Nunito',
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

  Widget _buildCategoryCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required String itemCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(28.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Center(
                child: Text(emoji, style: TextStyle(fontSize: 42.sp)),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    itemCount,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatching() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Davom etish \u{25B6}\u{FE0F}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 120.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildContinueCard(
                title: 'Qiziqarli sarguzashtlar',
                progress: 0.6,
                emoji: '\u{1F981}',
                color: AppColors.kidYellow,
              ),
              SizedBox(width: 12.w),
              _buildContinueCard(
                title: 'Matematik o\'yin',
                progress: 0.3,
                emoji: '\u{1F522}',
                color: AppColors.kidBlue,
              ),
              SizedBox(width: 12.w),
              _buildContinueCard(
                title: 'Alifbo sayohati',
                progress: 0.8,
                emoji: '\u{1F4D6}',
                color: AppColors.kidGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueCard({
    required String title,
    required double progress,
    required String emoji,
    required Color color,
  }) {
    return Container(
      width: 150.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 22.sp)),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5.h,
            ),
          ),
        ],
      ),
    );
  }
}
