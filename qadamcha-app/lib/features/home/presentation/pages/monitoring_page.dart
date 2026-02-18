import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/session_tracker.dart';
import '../../../../core/services/local_monitoring_service.dart';
import '../../../child/presentation/bloc/child_bloc.dart';
import '../../../child/domain/repositories/child_repository.dart';

/// Monitoring Page — Ota-ona panelida bolaning faolligini kuzatish
/// Summary cards + Haftalik chart + So'nggi faoliyat + Kategoriya foizlari
/// Har doim ma'lumot ko'rsatadi — bola rejimida o'tkazilgan vaqt asosida
class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  @override
  void initState() {
    super.initState();
    // Avval bolalarni yuklash, keyin monitoring datani
    final childState = context.read<ChildBloc>().state;
    if (childState.children.isEmpty) {
      context.read<ChildBloc>().add(const LoadChildrenEvent());
    }
    _loadMonitoringData();
  }

  void _loadMonitoringData() {
    final childState = context.read<ChildBloc>().state;
    if (childState.selectedChild != null) {
      final childId = childState.selectedChild!.id;
      context.read<ChildBloc>().add(LoadActivityLogsEvent(childId));
      context.read<ChildBloc>().add(LoadWeeklyStatsEvent(childId));
    } else if (childState.children.isNotEmpty) {
      // Agar selectedChild yo'q bo'lsa, birinchi bolani tanlash
      final childId = childState.children.first.id;
      context.read<ChildBloc>().add(SelectChildEvent(childId));
      context.read<ChildBloc>().add(LoadActivityLogsEvent(childId));
      context.read<ChildBloc>().add(LoadWeeklyStatsEvent(childId));
    }
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
                    '📊 Monitoring',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      context.read<ChildBloc>().add(const LoadChildrenEvent());
                      _loadMonitoringData();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 14.sp, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            'Yangilash',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
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
            Expanded(
              child: BlocConsumer<ChildBloc, ChildState>(
                listener: (context, state) {
                  // Bolalar yuklanganida avtomatik monitoring datani yuklash
                  if (state.status == ChildStatus.loaded && state.children.isNotEmpty) {
                    final child = state.selectedChild ?? state.children.first;
                    if (state.activityLogs.isEmpty && state.weeklyStats == null) {
                      context.read<ChildBloc>().add(LoadActivityLogsEvent(child.id));
                      context.read<ChildBloc>().add(LoadWeeklyStatsEvent(child.id));
                    }
                  }
                },
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ChildBloc>().add(const LoadChildrenEvent());
                      await Future.delayed(const Duration(milliseconds: 500));
                      _loadMonitoringData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 22.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary cards
                          _buildSummarySection(context, state),
                          SizedBox(height: 28.h),

                          // Usage chart
                          _buildUsageChart(state),
                          SizedBox(height: 28.h),

                          // Recent activity
                          _buildRecentActivity(state),
                          SizedBox(height: 28.h),

                          // Category breakdown
                          _buildCategoryBreakdown(state),
                          SizedBox(height: 32.h),
                        ],
                      ),
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

  // ─── Summary Cards ──────────────────────────────────────────────────

  Widget _buildSummarySection(BuildContext context, ChildState state) {
    final children = state.children;
    final localStats = LocalMonitoringService.instance;

    // Backend'dan bolalar umumiy vaqti
    final backendMinutes = children.fold<int>(
      0,
      (sum, child) => sum + child.todayUsage.minutesUsed,
    );
    final backendVideos = children.fold<int>(
      0,
      (sum, child) => sum + child.todayUsage.videosWatched,
    );
    final backendGames = children.fold<int>(
      0,
      (sum, child) => sum + child.todayUsage.gamesPlayed,
    );

    // Local + Backend: kattasini olish (local yangilangan bo'lishi mumkin)
    final totalMinutes = backendMinutes > localStats.minutesUsed
        ? backendMinutes
        : localStats.minutesUsed;
    final totalVideos = backendVideos > localStats.videosWatched
        ? backendVideos
        : localStats.videosWatched;
    final totalGames = backendGames > localStats.gamesPlayed
        ? backendGames
        : localStats.gamesPlayed;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: '⏱️',
                title: 'Umumiy vaqt',
                value: _formatMinutes(totalMinutes),
                color: const Color(0xFF667eea),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: _SummaryCard(
                icon: '🎬',
                title: 'Video ko\'rildi',
                value: '$totalVideos ta',
                color: const Color(0xFFf093fb),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: '🎮',
                title: 'O\'yin o\'ynaldi',
                value: '$totalGames ta',
                color: const Color(0xFF4ecdc4),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: _SummaryCard(
                icon: '📖',
                title: 'Ertak o\'qildi',
                value: '${localStats.storiesRead} ta',
                color: const Color(0xFFffecd2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}s ${mins}d' : '${hours} soat';
    }
    return '$minutes daqiqa';
  }

  // ─── Weekly Usage Chart ─────────────────────────────────────────────

  Widget _buildUsageChart(ChildState state) {
    final weeklyStats = state.weeklyStats;
    final dayLabels = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    final localWeekly = LocalMonitoringService.instance.weeklyMinutes;

    // Backend yoki local — kattasini olish
    final backendDaily = weeklyStats?.dailyMinutes ?? [0, 0, 0, 0, 0, 0, 0];
    final dailyMinutes = List.generate(7, (i) {
      final b = i < backendDaily.length ? backendDaily[i] : 0;
      final l = i < localWeekly.length ? localWeekly[i] : 0;
      return b > l ? b : l;
    });

    // Eng yuqori qiymatni topish (chart scaling uchun)
    final maxMinutes = dailyMinutes.reduce((a, b) => a > b ? a : b);
    final maxValue = maxMinutes > 0 ? maxMinutes.toDouble() : 60.0;

    // Bugungi kunning indeksini aniqlash (Du=0, ..., Ya=6)
    int todayIndex = DateTime.now().weekday - 1;
    if (todayIndex < 0) todayIndex = 6;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📊 Haftalik foydalanish',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              const Spacer(),
              Text(
                'Jami: ${_formatMinutes(dailyMinutes.fold(0, (a, b) => a + b))}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 140.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = dailyMinutes[index].toDouble();
                final barHeight = maxValue > 0 ? (value / maxValue) : 0.0;
                final isToday = index == todayIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _buildBar(
                      dayLabels[index],
                      barHeight.clamp(0.0, 1.0),
                      isToday,
                      dailyMinutes[index],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double height, bool isToday, int minutes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (minutes > 0)
          Text(
            '${minutes}d',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: isToday ? const Color(0xFF667eea) : AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        SizedBox(height: 4.h),
        Container(
          height: (height * 100.h).clamp(4.0, 100.0),
          decoration: BoxDecoration(
            gradient: isToday
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.6),
                      const Color(0xFF667eea).withOpacity(0.3),
                    ],
                  ),
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          day,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? const Color(0xFF667eea) : AppColors.textSecondary,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  // ─── Recent Activity ────────────────────────────────────────────────

  Widget _buildRecentActivity(ChildState state) {
    // Backend'dan va local'dan loglarni birlashtirish
    final backendLogs = state.activityLogs;
    final localLogs = LocalMonitoringService.instance.activityLogs;

    // Agar backend loglar bo'sh bo'lsa, local loglardan foydalanish
    List<ActivityLog> allLogs;
    if (backendLogs.isNotEmpty) {
      allLogs = backendLogs;
    } else {
      // Local loglarni ActivityLog'ga map qilish
      allLogs = localLogs.map((log) {
        return ActivityLog(
          id: 'local_${log['startedAt']}',
          childId: LocalMonitoringService.instance.childId ?? '',
          contentId: '',
          contentTitle: log['contentTitle'] ?? '',
          activityType: log['activityType'] ?? '',
          durationMinutes: log['durationMinutes'] ?? 0,
          startedAt: DateTime.tryParse(log['startedAt'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    }

    final filteredLogs = allLogs.where((log) {
      final type = log.activityType.toLowerCase();
      return type == 'video' || type == 'video_watch' ||
             type == 'game' || type == 'game_play' ||
             type == 'cartoon' || type == 'app_usage';
    }).take(5).toList();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📋 So\'nggi faoliyat',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              const Spacer(),
              Text(
                '${filteredLogs.length} ta',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (filteredLogs.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: Text(
                  'Hozircha faoliyat yo\'q',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            )
          else
            ...filteredLogs.map((log) => _buildActivityTile(log)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(ActivityLog log) {
    // Faoliyat turi bo'yicha icon va rang
    final isVideo = log.activityType == 'video' ||
        log.activityType == 'video_watch' ||
        log.activityType == 'cartoon';
    final icon = isVideo ? '🎬' : '🎮';
    final label = isVideo ? 'Multfilm ko\'rdi' : 'O\'yin o\'ynadi';
    final color = isVideo ? const Color(0xFFf093fb) : const Color(0xFF4facfe);

    // Vaqt formatlash
    final timeAgo = _formatTimeAgo(log.startedAt);
    final duration = log.durationMinutes > 0 ? '${log.durationMinutes} daqiqa' : '';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(icon, style: TextStyle(fontSize: 20.sp)),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.contentTitle.isNotEmpty ? log.contentTitle : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
              if (duration.isNotEmpty)
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFamily: 'Nunito',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Hozirgina';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays == 1) return 'Kecha';
    return '${diff.inDays} kun oldin';
  }

  // ─── Category Breakdown ─────────────────────────────────────────────

  Widget _buildCategoryBreakdown(ChildState state) {
    final localStats = LocalMonitoringService.instance;
    final children = state.children;

    // Backend + local data
    final backendMinutes = children.fold<int>(
      0, (sum, child) => sum + child.todayUsage.minutesUsed);
    final totalMinutes = backendMinutes > localStats.minutesUsed
        ? backendMinutes : localStats.minutesUsed;

    // Video va game vaqtlari (local data'dan)
    final videoCount = localStats.videosWatched;
    final gameCount = localStats.gamesPlayed;
    final totalActivities = videoCount + gameCount;

    // Foizlarni hisoblash
    final videoPercent = totalActivities > 0
        ? ((videoCount / totalActivities) * 100).clamp(0, 100).round()
        : 0;
    final gamePercent = totalActivities > 0
        ? ((gameCount / totalActivities) * 100).clamp(0, 100).round()
        : 0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Kategoriya bo\'yicha',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 16.h),
          _buildCategoryRow(
            '🎬',
            'Multfilmlar',
            videoPercent,
            const Color(0xFFf093fb),
          ),
          SizedBox(height: 14.h),
          _buildCategoryRow(
            '🎮',
            'O\'yinlar',
            gamePercent,
            const Color(0xFF4facfe),
          ),
          if (totalMinutes == 0) ...[
            SizedBox(height: 14.h),
            Center(
              child: Text(
                'Bugun hali faoliyat yo\'q',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    String icon,
    String label,
    int percent,
    Color color,
  ) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: 22.sp)),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 7.h,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Summary Card Widget ────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 28.sp)),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
