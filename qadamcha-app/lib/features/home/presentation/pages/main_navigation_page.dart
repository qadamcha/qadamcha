import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../../injection.dart';
import '../../../child/presentation/bloc/child_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../ai_chat/presentation/bloc/ai_chat_bloc.dart';
import '../../../ai_chat/presentation/pages/chat_sessions_page.dart';
import 'parent_home_page.dart';
import 'guides_page.dart';
import 'monitoring_page.dart';
import 'stories_page.dart';

/// Main Navigation Page — Ota-ona uchun bottom tab navigatsiya
/// Tabs: Bosh sahifa, Qo'llanma, AI, Ertaklar, Nazorat
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  late final AiChatBloc _aiChatBloc;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _aiChatBloc = sl<AiChatBloc>();
    _pages = [
      const ParentHomePage(),
      const GuidesPage(),
      BlocProvider.value(
        value: _aiChatBloc,
        child: const ChatSessionsPage(),
      ),
      const StoriesPage(),
      const MonitoringPage(),
    ];
    
    // Barcha asosiy ma'lumotlarni backend'dan yuklash
    _loadAllData();
    
    // Ota-ona menyusiga kirganda monitoring datani sync qilish
    LocalMonitoringService.instance.syncAllToBackend();
    
    // Backend sync'ni ulash — LocalMonitoringService → ChildBloc
    _initMonitoringSync();
  }

  /// Barcha kerakli ma'lumotlarni backend'dan yuklash
  /// Yangi qurilmada ham ishlashi uchun
  void _loadAllData() {
    // 1. Bolalar ro'yxatini yuklash
    context.read<ChildBloc>().add(const LoadChildrenEvent());
    
    // 2. Obuna holatini yuklash
    context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
    
    // 3. Agar bolalar allaqachon yuklangan bo'lsa — monitoring datani darhol yuklash
    // (BlocListener faqat yangi state o'zgarishini ushlab oladi, eski loaded state ni emas)
    final childState = context.read<ChildBloc>().state;
    if (childState.children.isNotEmpty) {
      final child = childState.selectedChild ?? childState.children.first;
      _loadMonitoringForChild(child.id);
      
      // Backend'dan kelgan todayUsage ni LocalMonitoringService ga sync qilish
      final monitoring = LocalMonitoringService.instance;
      monitoring.loadFromBackend(
        minutesUsed: child.todayUsage.minutesUsed,
        videosWatched: child.todayUsage.videosWatched,
        gamesPlayed: child.todayUsage.gamesPlayed,
        storiesRead: child.todayUsage.storiesRead,
      );
    }
  }

  /// Bolaning monitoring ma'lumotlarini backend'dan yuklash
  void _loadMonitoringForChild(String childId) {
    final childBloc = context.read<ChildBloc>();
    childBloc.add(LoadActivityLogsEvent(childId));
    childBloc.add(LoadWeeklyStatsEvent(childId));
    
    // LocalMonitoringService'ga ham child ID o'rnatish
    LocalMonitoringService.instance.setChildId(childId);
  }

  @override
  void dispose() {
    _aiChatBloc.close();
    // Chiqishda barcha ma'lumotlarni backend'ga sync qilish
    LocalMonitoringService.instance.syncAllToBackend();
    super.dispose();
  }

  /// LocalMonitoringService → ChildBloc backend sync ulash
  void _initMonitoringSync() {
    final monitoring = LocalMonitoringService.instance;
    final childBloc = context.read<ChildBloc>();
    
    // Sync callback — har 5 daqiqada monitoring data backend'ga batch sync
    monitoring.onSyncToBackend = (data) {
      final state = childBloc.state;
      final childId = state.selectedChild?.id ?? monitoring.childId;
      
      if (childId != null) {
        childBloc.add(SyncUsageEvent(
          childId: childId,
          minutesUsed: data['minutesUsed'] ?? 0,
          videosWatched: data['videosWatched'] ?? 0,
          gamesPlayed: data['gamesPlayed'] ?? 0,
          storiesRead: data['storiesRead'] ?? 0,
        ));
      }
    };
    
    // Sync timer'ni boshlash (har 5 daqiqada)
    monitoring.startSyncTimer();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ChildBloc, ChildState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status && curr.status == ChildStatus.loaded,
          listener: (context, state) {
            // Bolalar yuklanganda monitoring datani ham yuklash
            print('🟢 [BlocListener] ChildStatus.loaded! children=${state.children.length}');
            if (state.children.isNotEmpty) {
              final child = state.selectedChild ?? state.children.first;
              print('   child.todayUsage: min=${child.todayUsage.minutesUsed}, vid=${child.todayUsage.videosWatched}, game=${child.todayUsage.gamesPlayed}, story=${child.todayUsage.storiesRead}');
              _loadMonitoringForChild(child.id);
              
              // Backend'dan kelgan todayUsage ni LocalMonitoringService ga sync qilish
              // Yangi qurilmada local 0 bo'ladi, backend esa to'g'ri qiymat beradi
              final monitoring = LocalMonitoringService.instance;
              monitoring.loadFromBackend(
                minutesUsed: child.todayUsage.minutesUsed,
                videosWatched: child.todayUsage.videosWatched,
                gamesPlayed: child.todayUsage.gamesPlayed,
                storiesRead: child.todayUsage.storiesRead,
              );
            }
          },
        ),
        BlocListener<ChildBloc, ChildState>(
          listenWhen: (prev, curr) => prev.weeklyStats != curr.weeklyStats,
          listener: (context, state) {
            // Haftalik statistikani lokal ga sync qilish
            if (state.weeklyStats != null) {
              LocalMonitoringService.instance.loadWeeklyFromBackend(
                state.weeklyStats!.dailyMinutes,
              );
            }
          },
        ),
      ],
      child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
               color: const Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Bosh sahifa',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Qo\'llanma',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.psychology_rounded,
                  label: 'AI',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.auto_stories_rounded,
                  label: 'Ertaklar',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Nazorat',
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.w : 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            if (isSelected) ...[
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
