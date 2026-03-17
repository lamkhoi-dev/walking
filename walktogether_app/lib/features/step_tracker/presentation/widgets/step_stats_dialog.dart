import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Beautiful statistics popup dialog showing full step history
/// with filters, daily breakdown, and summary stats.
class StepStatsDialog extends StatefulWidget {
  final Map<String, dynamic> goalHistory;
  final int todaySteps;
  final int dailyGoal;

  const StepStatsDialog({
    super.key,
    required this.goalHistory,
    required this.todaySteps,
    required this.dailyGoal,
  });

  /// Show the dialog as a large popup (not full screen)
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> goalHistory,
    required int todaySteps,
    required int dailyGoal,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 500,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              elevation: 24,
              shadowColor: Colors.black26,
              child: StepStatsDialog(
                goalHistory: goalHistory,
                todaySteps: todaySteps,
                dailyGoal: dailyGoal,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<StepStatsDialog> createState() => _StepStatsDialogState();
}

class _StepStatsDialogState extends State<StepStatsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'week'; // week, month, all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedFilter = ['week', 'month', 'all'][_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Get all step records including today
  List<_StepDay> _getAllRecords() {
    final records = <_StepDay>[];
    final now = DateTime.now();
    final todayStr = _dateStr(now);

    // Add today
    records.add(_StepDay(
      date: now,
      dateStr: todayStr,
      steps: widget.todaySteps,
      goal: widget.dailyGoal,
      isToday: true,
    ));

    // Add history
    widget.goalHistory.forEach((dateStr, record) {
      if (dateStr == todayStr) return; // skip today (already added)
      if (record is Map) {
        final steps = record['steps'] as int? ?? 0;
        final goal = record['goal'] as int? ?? widget.dailyGoal;
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          records.add(_StepDay(
            date: date,
            dateStr: dateStr,
            steps: steps,
            goal: goal,
            isToday: false,
          ));
        }
      }
    });

    records.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return records;
  }

  List<_StepDay> _getFilteredRecords() {
    final all = _getAllRecords();
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'week':
        final cutoff = now.subtract(const Duration(days: 7));
        return all.where((r) => r.date.isAfter(cutoff)).toList();
      case 'month':
        final cutoff = now.subtract(const Duration(days: 30));
        return all.where((r) => r.date.isAfter(cutoff)).toList();
      case 'all':
      default:
        return all;
    }
  }

  /// Summary stats for filtered records
  _SummaryStats _calcSummary(List<_StepDay> records) {
    if (records.isEmpty) {
      return _SummaryStats(
          total: 0, avg: 0, best: 0, daysAchieved: 0, totalDays: 0);
    }
    int total = 0;
    int best = 0;
    int achieved = 0;
    for (final r in records) {
      total += r.steps;
      if (r.steps > best) best = r.steps;
      if (r.steps >= r.goal) achieved++;
    }
    return _SummaryStats(
      total: total,
      avg: total ~/ records.length,
      best: best,
      daysAchieved: achieved,
      totalDays: records.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredRecords();
    final summary = _calcSummary(filtered);
    final allRecords = _getAllRecords();
    final allTimeSummary = _calcSummary(allRecords);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(allTimeSummary),

          // Tab bar
          _buildTabBar(),

          // Summary cards
          _buildSummaryCards(summary),

          // Chart
          _buildChart(filtered),

          // Daily list
          Flexible(
            child: _buildDailyList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(_SummaryStats allTime) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF44C548), Color(0xFF2E8B31)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Thống kê bước chân',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // All-time total
          Row(
            children: [
              _miniStat(
                Icons.directions_walk_rounded,
                'Tổng cộng',
                _fmtLarge(allTime.total),
                'bước',
              ),
              const SizedBox(width: 16),
              _miniStat(
                Icons.calendar_month_rounded,
                'Số ngày',
                '${allTime.totalDays}',
                'ngày tracking',
              ),
              const SizedBox(width: 16),
              _miniStat(
                Icons.emoji_events_rounded,
                'Kỷ lục',
                _fmtLarge(allTime.best),
                'bước/ngày',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value, String unit) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 9, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: '7 ngày'),
          Tab(text: '30 ngày'),
          Tab(text: 'Tất cả'),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(_SummaryStats summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _statCard(
            icon: Icons.show_chart_rounded,
            iconColor: AppColors.secondary,
            label: 'Trung bình',
            value: _fmtLarge(summary.avg),
            unit: 'bước/ngày',
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            label: 'Đạt mục tiêu',
            value: '${summary.daysAchieved}/${summary.totalDays}',
            unit: 'ngày',
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.route_rounded,
            iconColor: AppColors.pendingOrange,
            label: 'Quãng đường',
            value: '${(summary.total * 0.762 / 1000).toStringAsFixed(1)}',
            unit: 'km',
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
            Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<_StepDay> records) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Show last N records in chart (reversed to show newest on right)
    final chartData = records.length > 14
        ? records.sublist(0, 14).reversed.toList()
        : records.reversed.toList();
    final maxSteps =
        chartData.map((d) => max(d.steps, d.goal)).fold<int>(1, max);

    return Container(
      height: 130,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartData.map((day) {
          final fraction = maxSteps > 0 ? day.steps / maxSteps : 0.0;
          final achieved = day.steps >= day.goal;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Tooltip(
                message:
                    '${_formatDateShort(day.date)}\n${_fmtLarge(day.steps)} bước',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: fraction.clamp(0.05, 1.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: achieved
                                  ? [
                                      const Color(0xFF44C548),
                                      const Color(0xFF66D96A)
                                    ]
                                  : day.isToday
                                      ? [
                                          const Color(0xFF2196F3),
                                          const Color(0xFF64B5F6)
                                        ]
                                      : [
                                          const Color(0xFFBDBDBD),
                                          const Color(0xFFE0E0E0)
                                        ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.isToday ? 'Nay' : '${day.date.day}',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight:
                            day.isToday ? FontWeight.w700 : FontWeight.w400,
                        color: day.isToday
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyList(List<_StepDay> records) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.directions_walk_rounded,
                  size: 48, color: AppColors.divider),
              SizedBox(height: 12),
              Text('Chưa có dữ liệu bước chân',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      shrinkWrap: true,
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final day = records[index];
        final achieved = day.steps >= day.goal;
        final pct = day.goal > 0 ? (day.steps / day.goal * 100).toInt() : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: day.isToday
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Date circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: achieved
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color:
                            achieved ? AppColors.primary : AppColors.textMain,
                      ),
                    ),
                    Text(
                      _monthLabel(day.date.month),
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (day.isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Hôm nay',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        Text(
                          _dayOfWeekLabel(day.date.weekday),
                          style: AppTextStyles.labelMedium,
                        ),
                        const Spacer(),
                        if (achieved)
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _fmtLarge(day.steps),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: achieved
                                ? AppColors.primary
                                : AppColors.textMain,
                          ),
                        ),
                        Text(
                          ' / ${_fmtLarge(day.goal)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: achieved
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Mini progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (day.steps / day.goal).clamp(0.0, 1.0),
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(
                          achieved ? AppColors.primary : AppColors.secondary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // === Helpers ===

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtLarge(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 100000) return '${(n / 1000).toStringAsFixed(0)}K';
    final str = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  String _formatDateShort(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  String _monthLabel(int m) {
    const labels = [
      'Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6',
      'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12'
    ];
    return labels[m - 1];
  }

  String _dayOfWeekLabel(int weekday) {
    const labels = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm',
      'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
    ];
    return labels[weekday - 1];
  }
}

class _StepDay {
  final DateTime date;
  final String dateStr;
  final int steps;
  final int goal;
  final bool isToday;

  _StepDay({
    required this.date,
    required this.dateStr,
    required this.steps,
    required this.goal,
    required this.isToday,
  });
}

class _SummaryStats {
  final int total;
  final int avg;
  final int best;
  final int daysAchieved;
  final int totalDays;

  _SummaryStats({
    required this.total,
    required this.avg,
    required this.best,
    required this.daysAchieved,
    required this.totalDays,
  });
}
