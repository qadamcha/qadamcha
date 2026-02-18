import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../../injection.dart';
import '../../../child/presentation/bloc/child_bloc.dart';
import '../../../ai_chat/presentation/bloc/ai_chat_bloc.dart';
import '../../../ai_chat/presentation/pages/ai_chat_page.dart';
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
        child: const AiChatPage(),
      ),
      const StoriesPage(),
      const MonitoringPage(),
    ];
    context.read<ChildBloc>().add(LoadChildrenEvent());
    
    // Backend sync'ni ulash — LocalMonitoringService → ChildBloc
    _initMonitoringSync();
  }

  @override
  void dispose() {
    _aiChatBloc.close();
    // Sync timer'ni to'xtatmaymiz — LocalMonitoringService singleton
    super.dispose();
  }

  /// LocalMonitoringService → ChildBloc backend sync ulash
  void _initMonitoringSync() {
    final monitoring = LocalMonitoringService.instance;
    final childBloc = context.read<ChildBloc>();
    
    // Sync callback — har 5 daqiqada monitoring data backend'ga yuboriladi
    monitoring.onSyncToBackend = (data) {
      final state = childBloc.state;
      final childId = state.selectedChild?.id ?? monitoring.childId;
      
      if (childId != null && data['minutesUsed'] != null && data['minutesUsed']! > 0) {
        childBloc.add(RecordActivityEvent(
          childId: childId,
          contentId: '',
          activityType: 'app_usage',
          durationMinutes: data['minutesUsed']!,
        ));
      }
    };
    
    // Sync timer'ni boshlash (har 5 daqiqada)
    monitoring.startSyncTimer();
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withOpacity(0.05),
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
