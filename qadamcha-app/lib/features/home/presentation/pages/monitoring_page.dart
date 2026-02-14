import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../child/presentation/bloc/child_bloc.dart';

/// Monitoring Page - Parent can view child's activity
/// Matching full_architecture.html design with charts and stats
class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '📊 Monitoring',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Bugun',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    _buildSummarySection(context),
                    const SizedBox(height: 28),

                    // Usage chart
                    _buildUsageChart(),
                    const SizedBox(height: 28),

                    // Recent activity
                    _buildRecentActivity(),
                    const SizedBox(height: 28),

                    // Category breakdown
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return BlocBuilder<ChildBloc, ChildState>(
      builder: (context, state) {
        final totalMinutes = state.children.fold<int>(
          0,
          (sum, child) => sum + child.todayUsage.minutesUsed,
        );
        final totalVideos = state.children.fold<int>(
          0,
          (sum, child) => sum + child.todayUsage.videosWatched,
        );

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                emoji: '⏱️',
                value: '$totalMinutes daqiqa',
                label: 'Umumiy vaqt',
                gradient: AppColors.primaryGradient,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                emoji: '🎬',
                value: '$totalVideos ta',
                label: 'Ko\'rilgan video',
                gradient: AppColors.sunsetGradient,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsageChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Haftalik foydalanish',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 20),
          // Simple bar chart
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('Du', 0.4, false),
                _buildBar('Se', 0.6, false),
                _buildBar('Ch', 0.3, false),
                _buildBar('Pa', 0.8, false),
                _buildBar('Ju', 0.5, false),
                _buildBar('Sh', 0.9, false),
                _buildBar('Ya', 0.7, true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Foydalanish vaqti (daqiqa)',
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildBar(String label, double value, bool isToday) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 100 * value,
          decoration: BoxDecoration(
            gradient: isToday ? AppColors.primaryGradient : null,
            color: isToday ? null : AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? AppColors.primary : AppColors.textSecondary,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      _ActivityItem(
        emoji: '📺',
        title: 'Multfilm ko\'rdi',
        subtitle: 'Qiziqarli sarguzashtlar',
        time: '15 daqiqa oldin',
        duration: '12 min',
      ),
      _ActivityItem(
        emoji: '🎮',
        title: 'O\'yin o\'ynadi',
        subtitle: 'Matematik o\'yin',
        time: '45 daqiqa oldin',
        duration: '8 min',
      ),
      _ActivityItem(
        emoji: '📚',
        title: 'Ertak eshitdi',
        subtitle: 'Uch og\'a-ini',
        time: '1 soat oldin',
        duration: '15 min',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'So\'nggi faoliyat',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 14),
        ...activities.map((a) => _buildActivityTile(a)),
      ],
    );
  }

  Widget _buildActivityTile(_ActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 13,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.time,
                style: TextStyle(
                  fontSize: 11,
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

  Widget _buildCategoryBreakdown() {
    final categories = [
      _CategoryStat(emoji: '📺', label: 'Multfilmlar', percent: 45, color: AppColors.kidBlue),
      _CategoryStat(emoji: '🎮', label: 'O\'yinlar', percent: 25, color: AppColors.kidGreen),
      _CategoryStat(emoji: '📚', label: 'Ertaklar', percent: 20, color: AppColors.kidPurple),
      _CategoryStat(emoji: '🎵', label: 'Qo\'shiqlar', percent: 10, color: AppColors.kidYellow),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategoriya bo\'yicha',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 14),
        ...categories.map((c) => _buildCategoryRow(c)),
      ],
    );
  }

  Widget _buildCategoryRow(_CategoryStat cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              Text(
                '${cat.percent}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cat.color,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.percent / 100,
              backgroundColor: cat.color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final LinearGradient gradient;

  const _SummaryCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String emoji;
  final String title;
  final String subtitle;
  final String time;
  final String duration;

  const _ActivityItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.duration,
  });
}

class _CategoryStat {
  final String emoji;
  final String label;
  final int percent;
  final Color color;

  const _CategoryStat({
    required this.emoji,
    required this.label,
    required this.percent,
    required this.color,
  });
}
