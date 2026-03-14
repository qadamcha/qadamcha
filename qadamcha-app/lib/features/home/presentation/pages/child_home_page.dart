import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/session_tracker.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../../core/widgets/bubble_nav_bar.dart';
import '../../../child/presentation/bloc/child_bloc.dart';
import '../../../child/presentation/pages/content_page.dart';
import '../../../child/presentation/pages/games_page.dart';
import '../../../auth/presentation/pages/role_selection_page.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';

/// YouTube Kids 1:1 — Child Home Page
/// Oq fon, toza nav bar, YouTube Kids stilida
class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key});

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  int _currentIndex = 0;
  late final ChildBloc _childBloc;
  bool _childCreating = false;
  Timer? _subscriptionCheckTimer;

  @override
  void initState() {
    super.initState();
    _childBloc = context.read<ChildBloc>();

    final childId = _childBloc.state.selectedChild?.id;
    if (childId != null) {
      LocalMonitoringService.instance.setChildId(childId);
      if (kDebugMode) print('🆔 [ChildHome] childId BLoC dan olindi: $childId');
    } else {
      if (kDebugMode) print('⚠️ [ChildHome] selectedChild null — LoadChildrenEvent yuborilmoqda');
      _childBloc.add(LoadChildrenEvent());
      final storedId = LocalMonitoringService.instance.childId;
      if (storedId != null && storedId.isNotEmpty) {
        if (kDebugMode) print('🆔 [ChildHome] childId SharedPreferences dan olindi: $storedId');
      }
    }

    SessionTracker.instance.startSession('child_home');
    _syncFromBackend();
    _setupTimeLimit();

    _subscriptionCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
      }
    });
  }

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

  Future<void> _setupTimeLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('time_limit_enabled') ?? false;
      final minutes = prefs.getInt('time_limit_minutes') ?? 60;
      if (kDebugMode) print('⏰ [ChildHome] Time limit: enabled=$enabled, minutes=$minutes');
      LocalMonitoringService.instance.setTimeLimit(enabled: enabled, minutes: minutes);
    } catch (e) {
      if (kDebugMode) print('⚠️ [ChildHome] Time limit xato: $e');
    }
  }

  @override
  void dispose() {
    _subscriptionCheckTimer?.cancel();
    LocalMonitoringService.instance.clearTimeLimit();
    SessionTracker.instance.endSession('child_home');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChildBloc, ChildState>(
      listener: (context, childState) {
        if (childState.status == ChildStatus.loaded) {
          if (childState.children.isEmpty && !_childCreating) {
            _childCreating = true;
            if (kDebugMode) print('⚠️ [ChildHome] children=0 — avtomatik bola yaratilmoqda');
            context.read<ChildBloc>().add(const AddChildEvent(name: 'Bolajon', age: 5, gender: 'male'));
            return;
          }
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
      child: Builder(
        // ⚠️ TODO: Test tugagach qaytarish! SubscriptionBloc check o'chirilgan
        // Eski kod: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context) {
          LocalMonitoringService.instance.setChildSessionActive(true);
          return _buildMain(context);
        },
      ),
    );
  }

  Widget _buildNoSubscription(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64.sp, color: const Color(0xFFBBBBBB)),
                SizedBox(height: 20.h),
                Text(
                  'Obuna faol emas',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F0F0F)),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Multfilmlar va o\'yinlardan foydalanish uchun\nota-ona panelidan obunani faollashtiring',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: const Color(0xFF606060), height: 1.5),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionPage())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065FD4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                      elevation: 0,
                    ),
                    child: Text('Orqaga qaytish', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ContentPage(),
          GamesPage(),
        ],
      ),
      bottomNavigationBar: YTKidsNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
