import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/step_counter_service.dart';
import '../../../contest/data/models/contest_model.dart';
import '../../../contest/data/repositories/contest_repository.dart';
import '../bloc/step_tracker_bloc.dart';
import '../widgets/step_stats_dialog.dart';

/// Beautiful goals page — daily goal, weekly chart, milestones, streak
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late final StepCounterService _stepService;

  @override
  void initState() {
    super.initState();
    _stepService = StepCounterService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mục tiêu của tôi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<StepTrackerBloc, StepTrackerState>(
        builder: (context, state) {
          // Show loading indicator while syncing from server
          if (state is StepTrackerLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang đồng bộ dữ liệu...'),
                ],
              ),
            );
          }
          
          final todaySteps = state is StepTrackerRunning ? state.todaySteps : 0;
          final goalSteps = state is StepTrackerRunning ? state.goalSteps : _stepService.dailyGoal;
          final progress = goalSteps > 0 ? todaySteps / goalSteps : 0.0;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // === TODAY'S GOAL CARD ===
              _TodayGoalCard(
                todaySteps: todaySteps,
                goalSteps: goalSteps,
                progress: progress,
                onEditGoal: () => _showGoalPicker(context, goalSteps),
              ),
              const SizedBox(height: 20),

              // === STREAK CARD ===
              _StreakCard(streak: _stepService.currentStreak),
              const SizedBox(height: 20),

              // === WEEKLY PROGRESS ===
              GestureDetector(
                onTap: () => StepStatsDialog.show(
                  context,
                  goalHistory: _stepService.goalHistory,
                  todaySteps: todaySteps,
                  dailyGoal: goalSteps,
                ),
                child: _WeeklyProgressCard(
                  goalHistory: _stepService.goalHistory,
                  todaySteps: todaySteps,
                  dailyGoal: goalSteps,
                ),
              ),
              const SizedBox(height: 20),

              // === MILESTONES ===
              _MilestonesCard(
                totalStepsAllTime: _calculateTotalSteps(),
                todaySteps: todaySteps,
                goalHistory: _stepService.goalHistory,
              ),
              const SizedBox(height: 20),

              // === CONTESTS ===
              _ContestsCard(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  int _calculateTotalSteps() {
    int total = _stepService.todaySteps;
    final history = _stepService.goalHistory;
    for (final record in history.values) {
      if (record is Map) {
        total += (record['steps'] as int? ?? 0);
      }
    }
    return total;
  }

  void _showGoalPicker(BuildContext context, int currentGoal) {
    int selectedGoal = currentGoal;
    final presets = [3000, 5000, 8000, 10000, 15000, 20000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Đặt mục tiêu hàng ngày', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn số bước bạn muốn đạt mỗi ngày',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Big number display
                  Text(
                    _formatNumber(selectedGoal),
                    style: AppTextStyles.stepCount.copyWith(
                      color: AppColors.primary,
                      fontSize: 48,
                    ),
                  ),
                  Text('bước/ngày', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 20),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primaryLight,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.15),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                    ),
                    child: Slider(
                      value: selectedGoal.toDouble(),
                      min: 1000,
                      max: 30000,
                      divisions: 29,
                      onChanged: (v) {
                        setModalState(() => selectedGoal = v.round());
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Preset chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: presets.map((p) {
                      final isSelected = selectedGoal == p;
                      return ChoiceChip(
                        label: Text(_formatNumber(p)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textMain,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) {
                          setModalState(() => selectedGoal = p);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Info about the goal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '≈ ${(selectedGoal * 0.762 / 1000).toStringAsFixed(1)} km  ·  ≈ ${(selectedGoal * 0.04).toInt()} cal',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<StepTrackerBloc>().add(StepTrackerGoalChanged(selectedGoal));
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Lưu mục tiêu', style: AppTextStyles.buttonLarge),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final str = n.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return n.toString();
  }
}

// ============================================================
// TODAY'S GOAL CARD
// ============================================================
class _TodayGoalCard extends StatelessWidget {
  final int todaySteps;
  final int goalSteps;
  final double progress;
  final VoidCallback onEditGoal;

  const _TodayGoalCard({
    required this.todaySteps,
    required this.goalSteps,
    required this.progress,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final isGoalReached = progress >= 1.0;
    final pctText = '${(progress * 100).clamp(0, 999).toInt()}%';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isGoalReached
            ? const LinearGradient(
                colors: [Color(0xFF44C548), Color(0xFF36B03A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isGoalReached ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isGoalReached
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Icon(
                isGoalReached ? Icons.emoji_events_rounded : Icons.flag_rounded,
                color: isGoalReached ? Colors.white : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isGoalReached ? 'Hoàn thành mục tiêu! 🎉' : 'Mục tiêu hôm nay',
                  style: AppTextStyles.heading4.copyWith(
                    color: isGoalReached ? Colors.white : AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              GestureDetector(
                onTap: onEditGoal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isGoalReached
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: isGoalReached ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sửa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isGoalReached ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Circular progress
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _GoalRingPainter(
                    progress: value,
                    isCompleted: isGoalReached,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pctText,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isGoalReached ? Colors.white : AppColors.primary,
                      ),
                    ),
                    Text(
                      'hoàn thành',
                      style: TextStyle(
                        fontSize: 12,
                        color: isGoalReached
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Steps / Goal text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _fmt(todaySteps),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isGoalReached ? Colors.white : AppColors.textMain,
                ),
              ),
              Text(
                ' / ${_fmt(goalSteps)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isGoalReached
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                ' bước',
                style: TextStyle(
                  fontSize: 14,
                  color: isGoalReached
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (!isGoalReached) ...[
            const SizedBox(height: 8),
            Text(
              'Còn ${_fmt(goalSteps - todaySteps)} bước nữa — cố lên! 💪',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n < 0) n = 0;
    final str = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

// ============================================================
// STREAK CARD
// ============================================================
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFF44336)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi hoàn thành',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF44336),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'ngày liên tiếp',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Flame icons based on streak
          if (streak > 0) ...[
            ...List.generate(
              min(streak, 5),
              (i) => Icon(
                Icons.local_fire_department_rounded,
                color: Color.lerp(
                  const Color(0xFFFFB74D),
                  const Color(0xFFF44336),
                  i / 4,
                ),
                size: 18,
              ),
            ),
            if (streak > 5)
              Text(
                '+${streak - 5}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF44336),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// WEEKLY PROGRESS CARD
// ============================================================
class _WeeklyProgressCard extends StatelessWidget {
  final Map<String, dynamic> goalHistory;
  final int todaySteps;
  final int dailyGoal;

  const _WeeklyProgressCard({
    required this.goalHistory,
    required this.todaySteps,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = <_DayData>[];
    int achievedCount = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isToday = i == 0;

      int steps;
      int goal;
      if (isToday) {
        steps = todaySteps;
        goal = dailyGoal;
      } else {
        final record = goalHistory[dateStr];
        if (record is Map) {
          steps = record['steps'] as int? ?? 0;
          goal = record['goal'] as int? ?? dailyGoal;
        } else {
          steps = 0;
          goal = dailyGoal;
        }
      }

      final achieved = steps >= goal;
      if (achieved) achievedCount++;

      days.add(_DayData(
        date: date,
        steps: steps,
        goal: goal,
        achieved: achieved,
        isToday: isToday,
      ));
    }

    final maxSteps = days.map((d) => max(d.steps, d.goal)).fold<int>(1, max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text('Tuần này', style: AppTextStyles.heading4),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$achievedCount/7 ngày',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),

          // Bar chart
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final fraction = maxSteps > 0 ? day.steps / maxSteps : 0.0;
                final goalFraction = maxSteps > 0 ? day.goal / maxSteps : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Step count on top
                        if (day.steps > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _shortNumber(day.steps),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: day.achieved ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),

                        // Bar
                        Flexible(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Goal line (dotted background)
                              FractionallySizedBox(
                                heightFactor: goalFraction.clamp(0.05, 1.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.divider.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              // Actual steps
                              FractionallySizedBox(
                                heightFactor: fraction.clamp(0.0, 1.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: day.achieved
                                          ? [AppColors.primary, const Color(0xFF66D96A)]
                                          : day.isToday
                                              ? [AppColors.secondary, const Color(0xFF64B5F6)]
                                              : [AppColors.textSecondary.withValues(alpha: 0.5), AppColors.textSecondary.withValues(alpha: 0.3)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              // Check mark if achieved
                              if (day.achieved)
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Day label
                        Text(
                          day.isToday ? 'Nay' : _dayLabel(day.date.weekday),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                            color: day.isToday ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(int weekday) {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[weekday - 1];
  }

  String _shortNumber(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _DayData {
  final DateTime date;
  final int steps;
  final int goal;
  final bool achieved;
  final bool isToday;

  _DayData({
    required this.date,
    required this.steps,
    required this.goal,
    required this.achieved,
    required this.isToday,
  });
}

// ============================================================
// MILESTONES CARD
// ============================================================
class _MilestonesCard extends StatelessWidget {
  final int totalStepsAllTime;
  final int todaySteps;
  final Map<String, dynamic> goalHistory;

  const _MilestonesCard({
    required this.totalStepsAllTime,
    required this.todaySteps,
    required this.goalHistory,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = [
      _Milestone('Bước đầu tiên', 'Đi 1.000 bước trong ngày', 1000, Icons.child_care_rounded, const Color(0xFF81C784)),
      _Milestone('Người đi bộ', 'Đi 5.000 bước trong ngày', 5000, Icons.directions_walk_rounded, const Color(0xFF4CAF50)),
      _Milestone('Chinh phục mục tiêu', 'Đạt 10.000 bước', 10000, Icons.flag_rounded, const Color(0xFF2196F3)),
      _Milestone('Siêu đi bộ', 'Đi 20.000 bước trong ngày', 20000, Icons.bolt_rounded, const Color(0xFFF44336)),
      _Milestone('Tổng 50K', 'Tổng cộng 50.000 bước', 50000, Icons.star_rounded, const Color(0xFFFF9800), isLifetime: true),
      _Milestone('Tổng 100K', 'Tổng cộng 100.000 bước', 100000, Icons.military_tech_rounded, const Color(0xFF9C27B0), isLifetime: true),
    ];

    // Calculate personal best from history
    int personalBest = todaySteps;
    for (final record in goalHistory.values) {
      if (record is Map) {
        final steps = record['steps'] as int? ?? 0;
        if (steps > personalBest) personalBest = steps;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB300), size: 22),
              const SizedBox(width: 8),
              Text('Thành tựu', style: AppTextStyles.heading4),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kỷ lục cá nhân: ${_fmt(personalBest)} bước  ·  Tổng cộng: ${_fmt(totalStepsAllTime)} bước',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          ...milestones.map((m) {
            final bool unlocked;
            final double progress;
            if (m.isLifetime) {
              unlocked = totalStepsAllTime >= m.threshold;
              progress = (totalStepsAllTime / m.threshold).clamp(0.0, 1.0);
            } else {
              unlocked = personalBest >= m.threshold;
              progress = (personalBest / m.threshold).clamp(0.0, 1.0);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? m.color.withValues(alpha: 0.15)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      m.icon,
                      size: 22,
                      color: unlocked ? m.color : AppColors.divider,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              m.name,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: unlocked ? AppColors.textMain : AppColors.textSecondary,
                              ),
                            ),
                            if (unlocked) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.description,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation(
                              unlocked ? m.color : m.color.withValues(alpha: 0.4),
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _Milestone {
  final String name;
  final String description;
  final int threshold;
  final IconData icon;
  final Color color;
  final bool isLifetime;

  const _Milestone(this.name, this.description, this.threshold, this.icon, this.color, {this.isLifetime = false});
}

// ============================================================
// GOAL RING PAINTER
// ============================================================
class _GoalRingPainter extends CustomPainter {
  final double progress;
  final bool isCompleted;

  _GoalRingPainter({required this.progress, required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 12.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isCompleted
            ? Colors.white.withValues(alpha: 0.2)
            : AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isCompleted) {
      progressPaint.color = Colors.white;
    } else {
      progressPaint.shader = const LinearGradient(
        colors: [AppColors.primary, Color(0xFF66D96A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter old) =>
      old.progress != progress || old.isCompleted != isCompleted;
}

// ============================================================
// CONTESTS SECTION
// ============================================================

class _ContestsCard extends StatefulWidget {
  const _ContestsCard();

  @override
  State<_ContestsCard> createState() => _ContestsCardState();
}

class _ContestsCardState extends State<_ContestsCard> {
  List<ContestModel>? _contests;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contests == null) _loadContests();
  }

  Future<void> _loadContests() async {
    try {
      final dio = context.read<DioClient>();
      final repo = ContestRepository(dio: dio);
      final contests = await repo.getContests();
      // Sort: active first, then upcoming, then completed
      contests.sort((a, b) {
        const order = {'active': 0, 'upcoming': 1, 'completed': 2, 'cancelled': 3};
        return (order[a.status] ?? 9).compareTo(order[b.status] ?? 9);
      });
      if (mounted) setState(() { _contests = contests; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _contests = []; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Cuộc thi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textMain)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_contests == null || _contests!.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('Chưa tham gia cuộc thi nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            ...(_contests!.map((c) => _buildContestTile(c))),
        ],
      ),
    );
  }

  Widget _buildContestTile(ContestModel contest) {
    final dateFormat = DateFormat('dd/MM');
    final statusColors = {
      'active': AppColors.success,
      'upcoming': Colors.amber.shade700,
      'completed': AppColors.textSecondary,
      'cancelled': AppColors.danger,
    };
    final statusLabels = {
      'active': 'Đang diễn ra',
      'upcoming': 'Sắp diễn ra',
      'completed': 'Đã kết thúc',
      'cancelled': 'Đã hủy',
    };
    final color = statusColors[contest.status] ?? AppColors.textSecondary;

    return InkWell(
      onTap: () => context.push('/contests/${contest.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.emoji_events_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contest.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textMain),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (contest.groupName != null) ...[
                        Icon(Icons.group_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            contest.groupName!,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${dateFormat.format(contest.startDate)} - ${dateFormat.format(contest.endDate)}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabels[contest.status] ?? contest.status,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
