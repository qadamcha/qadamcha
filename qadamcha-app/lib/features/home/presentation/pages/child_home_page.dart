import 'package:flutter/foundation.dart';
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

/// Child Home Page — pastki navigatsiya paneli bilan
/// 2 ta tab: Multfilmlar va O'yinlar
/// Ota-ona menyusidagi bottom nav kabi ishlaydi
class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  int _currentIndex = 0;
  late final ChildBloc _childBloc;
  bool _childCreating = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _childBloc = context.read<ChildBloc>();

    _pages = const [
      ContentPage(),
      GamesPage(),
    ];

    // Child ID ni o'rnatish
    final childId = _childBloc.state.selectedChild?.id;
    if (childId != null) {
      LocalMonitoringService.instance.setChildId(childId);
      if (kDebugMode) print('🆔 [ChildHome] childId BLoC dan olindi: $childId');
    } else {
      if (kDebugMode) print('⚠️ [ChildHome] selectedChild null — LoadChildrenEvent yuborilmoqda');
      _childBloc.add(LoadChildrenEvent());
      
      // SharedPreferences'dan fallback
      final storedId = LocalMonitoringService.instance.childId;
      if (storedId != null && storedId.isNotEmpty) {
        if (kDebugMode) print('🆔 [ChildHome] childId SharedPreferences dan olindi: $storedId');
      }
    }

    // Umumiy vaqt tracking boshlash (global soniya timer)
    SessionTracker.instance.startSession('child_home');

    // Backend'dan sync qilish (kirganda)
    _syncFromBackend();
  }

  /// Bola menuga kirganda backend'dan ma'lumot sync qilish
  Future<void> _syncFromBackend() async {
    try {
      final childState = _childBloc.state;
      if (childState.selectedChild != null) {
        final usage = childState.selectedChild!.todayUsage;
        LocalMonitoringService.instance.loadFromBackend(
          minutesUsed: usage.minutesUsed,
          videosWatched: usage.videosWatched,
          gamesPlayed: usage.gamesPlayed,
          storiesRead: usage.storiesRead,
        );
        if (kDebugMode) print('🔄 [ChildHome] Backend dan sync qilindi');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [ChildHome] Backend sync xato: $e');
    }
  }

  @override
  void dispose() {
    // Sessiya timer to'xtatish va backend'ga sync (SessionTracker ichida)
    SessionTracker.instance.endSession('child_home');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChildBloc, ChildState>(
      listener: (context, childState) {
        if (childState.status == ChildStatus.loaded) {
          if (childState.children.isEmpty && !_childCreating) {
            // Backend'da bola profili yo'q — avtomatik yaratish
            _childCreating = true;
            if (kDebugMode) print('⚠️ [ChildHome] children=0 — avtomatik bola yaratilmoqda');
            context.read<ChildBloc>().add(const AddChildEvent(
              name: 'Bolajon',
              age: 5,
              gender: 'male',
            ));
            return;
          }
          // Bolalar bor — childId o'rnatish
          final childId = childState.selectedChild?.id;
          if (childId != null && childId.isNotEmpty) {
            final currentId = LocalMonitoringService.instance.childId;
            if (currentId != childId) {
              LocalMonitoringService.instance.setChildId(childId);
              if (kDebugMode) print('🆔 [ChildHome] BlocListener: childId yangilandi: $childId');
            }
          }
        }
      },
      child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, subState) {
          // Yuklash vaqtida spinner
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
      ),
    );
  }

  // ─── No Subscription Screen ───
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

  // ─── Main Screen with Bottom Navigation ───
  Widget _buildMainScreen(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ChildNavItem(
                  icon: Icons.movie_rounded,
                  label: 'Multfilmlar',
                  emoji: '🎬',
                  isSelected: _currentIndex == 0,
                  gradient: AppColors.cartoonGradient,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _ChildNavItem(
                  icon: Icons.sports_esports_rounded,
                  label: 'O\'yinlar',
                  emoji: '🎮',
                  isSelected: _currentIndex == 1,
                  gradient: AppColors.gamesGradient,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bola menyusi uchun navigatsiya elementi
class _ChildNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String emoji;
  final bool isSelected;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ChildNavItem({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20.w : 14.w,
          vertical: 10.h,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          borderRadius: BorderRadius.circular(16.r),
          color: isSelected ? null : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 22.sp)),
            if (isSelected) ...[
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
