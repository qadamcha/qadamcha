import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/session_tracker.dart';
import '../../../../core/services/local_monitoring_service.dart';
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
  late final ChildBloc _childBloc;
  List<Map<String, dynamic>> _lastWatchedList = [];

  @override
  void initState() {
    super.initState();
    // BLoC referensini saqlash (dispose da context ishlamasligi uchun)
    _childBloc = context.read<ChildBloc>();
    
    // Child ID ni local monitoring'ga saqlash
    final childId = _childBloc.state.selectedChild?.id;
    if (childId != null) {
      LocalMonitoringService.instance.setChildId(childId);
    }
    
    // Backend sync timer boshlash
    LocalMonitoringService.instance.startSyncTimer();
    
    // Bola menyusiga kirganda monitoring datani sync qilish
    LocalMonitoringService.instance.syncAllToBackend();
    
    // Umumiy vaqt tracking boshlash
    SessionTracker.instance.startSession('child_home');
    
    // Oxirgi ko'rilgan multfilmlar ro'yxatini yuklash
    _loadLastWatchedList();
  }

  void _loadLastWatchedList() {
    setState(() {
      _lastWatchedList = LocalMonitoringService.instance.getLastWatchedList();
    });
  }

  @override
  void dispose() {
    // Tracking to'xtatish (lokal counter yangilanadi, backend batch sync orqali)
    SessionTracker.instance.endSession('child_home');
    // Chiqishda barcha ma'lumotlarni backend'ga sync qilish
    LocalMonitoringService.instance.syncAllToBackend();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        // Yuklash vaqtida spinner ko'rsatish (subscription tekshirilmoqda)
        if (subState.status == SubscriptionLoadStatus.loading ||
            subState.status == SubscriptionLoadStatus.initial) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE8F5E9), Color(0xFFF5F6FA), Colors.white],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
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

                _buildCategoryCard(
                  context,
                  emoji: '\u{1F3AC}',
                  title: 'Multfilmlar',
                  subtitle: 'Qiziqarli multiklar ko\'rish',
                  gradient: AppColors.cartoonGradient,
                  itemCount: '100+',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContentPage()),
                    ).then((_) => _loadLastWatchedList());
                  },
                ),
                SizedBox(height: 16.h),
                _buildCategoryCard(
                  context,
                  emoji: '\u{1F3AE}',
                  title: 'O\'yinlar',
                  subtitle: 'Ta\'limiy o\'yinlar o\'ynash',
                  gradient: AppColors.gamesGradient,
                  itemCount: '50+',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GamesPage()),
                    ).then((_) => _loadLastWatchedList());
                  },
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
    // Oxirgi ko'rilgan multfilmlar ro'yxati (max 3 ta)
    final watchedItems = _lastWatchedList.take(3).toList();
    
    if (watchedItems.isEmpty) {
      return const SizedBox.shrink(); // Hech narsa ko'rilmagan
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oxirgi ko\'rilganlar \u{25B6}\u{FE0F}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 140.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: watchedItems.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final item = watchedItems[index];
              return _buildLastWatchedCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLastWatchedCard(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Multfilm';
    final thumbnailUrl = item['thumbnailUrl'] as String?;
    final type = item['type'] ?? 'video';
    
    return GestureDetector(
      onTap: () {
        // ContentPage ga qaytarish
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContentPage()),
        ).then((_) => _loadLastWatchedList());
      },
      child: Container(
        width: 160.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              child: SizedBox(
                width: double.infinity,
                height: 85.h,
                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.kidPurple.withOpacity(0.15),
                          child: Center(
                            child: Text(
                              type == 'game' ? '\u{1F3AE}' : '\u{1F3AC}',
                              style: TextStyle(fontSize: 32.sp),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.kidPurple.withOpacity(0.15),
                        child: Center(
                          child: Text(
                            type == 'game' ? '\u{1F3AE}' : '\u{1F3AC}',
                            style: TextStyle(fontSize: 32.sp),
                          ),
                        ),
                      ),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
