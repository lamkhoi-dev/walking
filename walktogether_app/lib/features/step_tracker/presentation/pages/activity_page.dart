import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/step_sync_service.dart';
import '../../../contest/data/models/contest_model.dart';
import '../../../contest/data/repositories/contest_repository.dart';
import '../bloc/step_tracker_bloc.dart';
import '../widgets/step_progress_ring.dart';
import '../widgets/step_stat_card.dart';
import '../widgets/sync_status_widget.dart';

/// Main activity page showing step tracking progress
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    super.initState();
    // Tracking is auto-started from main.dart after login.
    // No need to start here.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<StepTrackerBloc, StepTrackerState>(
          builder: (context, state) {
            if (state is StepTrackerError) {
              return _buildError(state.message);
            }

            if (state is StepTrackerRunning) {
              return _buildContent(context, state);
            }

            // Initial / loading
            return _buildInitialLoading(context);
          },
        ),
      ),
    );
  }

  Widget _buildInitialLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StepProgressRing(
            currentSteps: 0,
            goalSteps: AppConstants.dailyStepGoalDefault,
          ),
          const SizedBox(height: 24),
          Text(
            'Đang khởi tạo bộ đếm bước...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, StepTrackerRunning state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<StepTrackerBloc>().add(StepTrackerSyncRequested());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 16),

          // Header
          _buildHeader(state),
          const SizedBox(height: 32),

          // Progress ring
          Center(
            child: StepProgressRing(
              currentSteps: state.todaySteps,
              goalSteps: state.goalSteps,
            ),
          ),
          const SizedBox(height: 8),

          // Pedestrian status
          Center(child: _buildPedestrianChip(state.pedestrianStatus)),
          const SizedBox(height: 24),

          // Stat cards row
          Row(
            children: [
              Expanded(
                child: StepStatCard(
                  icon: Icons.straighten_rounded,
                  value: _formatDistance(state.distance),
                  label: 'Khoảng cách',
                  iconColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StepStatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: _formatCalories(state.calories),
                  label: 'Calo',
                  iconColor: AppColors.pendingOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/goals'),
                  child: StepStatCard(
                    icon: Icons.flag_rounded,
                    value: '${(state.progress * 100).toInt()}%',
                    label: 'Mục tiêu',
                    iconColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tracking toggle & sync status
          _buildControlRow(context, state),
          const SizedBox(height: 16),

          // Goal detail button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/goals'),
              icon: const Icon(Icons.emoji_events_rounded, size: 20),
              label: Text('Xem mục tiêu & thành tựu',
                  style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Hourly chart
          _buildHourlyChart(state.hourlySteps, state.todaySteps),
          const SizedBox(height: 24),

          // Active contests section
          _ActiveContestsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(StepTrackerRunning state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoạt động hôm nay', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text(
                _todayLabel(),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        SyncStatusWidget(
          status: state.syncStatus,
          lastSyncTime: StepSyncService().lastSyncTime,
          onTapSync: () {
            context.read<StepTrackerBloc>().add(StepTrackerSyncRequested());
          },
        ),
      ],
    );
  }

  Widget _buildPedestrianChip(String status) {
    IconData icon;
    String label;
    Color color;

    switch (status) {
      case 'walking':
        icon = Icons.directions_walk_rounded;
        label = 'Đang đi bộ';
        color = AppColors.primary;
        break;
      case 'stopped':
        icon = Icons.accessibility_new_rounded;
        label = 'Đang đứng yên';
        color = AppColors.textSecondary;
        break;
      default:
        icon = Icons.help_outline_rounded;
        label = 'Chưa xác định';
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(BuildContext context, StepTrackerRunning state) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (state.isTracking) {
                  context.read<StepTrackerBloc>().add(StepTrackerStopRequested());
                } else {
                  context.read<StepTrackerBloc>().add(StepTrackerStartRequested());
                }
              },
              icon: Icon(
                state.isTracking ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              label: Text(
                state.isTracking ? 'Tạm dừng' : 'Tiếp tục',
                style: AppTextStyles.buttonMedium,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isTracking ? AppColors.textSecondary : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(Map<String, int> hourlySteps, int totalSteps) {
    if (hourlySteps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Center(
          child: Text(
            'Chưa có dữ liệu theo giờ',
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    // Find max for scaling
    final maxSteps = hourlySteps.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bước chân theo giờ', style: AppTextStyles.labelLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (i) {
                final hour = i.toString().padLeft(2, '0');
                final steps = hourlySteps[hour] ?? 0;
                final fraction = maxSteps > 0 ? steps / maxSteps : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: fraction.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: steps > 0
                                    ? AppColors.primary.withValues(alpha: 0.3 + 0.7 * fraction)
                                    : AppColors.divider,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (i % 4 == 0)
                          Text(
                            hour,
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          const SizedBox(height: 10),
                      ],
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

  Widget _buildError(String message) {
    final isPermissionError = message.contains('quyền') || message.contains('Motion') || message.contains('cảm biến') || message.contains('permission');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isPermissionError
                    ? AppColors.pendingOrange.withValues(alpha: 0.12)
                    : AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPermissionError ? Icons.directions_walk_rounded : Icons.error_outline,
                size: 40,
                color: isPermissionError ? AppColors.pendingOrange : AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPermissionError ? 'Cần quyền đếm bước' : 'Lỗi bộ đếm bước',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPermissionError
                  ? 'Để đếm bước chân, vui lòng cho phép ứng dụng truy cập cảm biến chuyển động trong Cài đặt.'
                  : message,
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (isPermissionError) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Open iOS/Android app settings
                    final opened = await openAppSettings();
                    if (!opened && mounted) {
                      // Fallback: try starting again
                      context.read<StepTrackerBloc>().add(StepTrackerStartRequested());
                    }
                  },
                  icon: const Icon(Icons.settings_rounded, size: 20),
                  label: const Text('Mở Cài đặt', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.read<StepTrackerBloc>().add(StepTrackerStartRequested());
                },
                child: Text(
                  'Tôi đã cấp quyền, thử lại',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<StepTrackerBloc>().add(StepTrackerStartRequested());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _formatCalories(double cal) {
    if (cal >= 1000) {
      return '${(cal / 1000).toStringAsFixed(1)} kcal';
    }
    return '${cal.toInt()} cal';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    const months = [
      '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month]}';
  }
}

/// Active contests section widget
class _ActiveContestsSection extends StatefulWidget {
  @override
  State<_ActiveContestsSection> createState() => _ActiveContestsSectionState();
}

class _ActiveContestsSectionState extends State<_ActiveContestsSection> {
  List<ContestModel> _activeContests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContests();
  }

  Future<void> _loadContests() async {
    try {
      final repo = context.read<ContestRepository>();
      final contests = await repo.getContests();
      final active = contests.where((c) => c.status == 'active').toList();
      if (mounted) {
        setState(() {
          _activeContests = active.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    if (_activeContests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.pendingOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: AppColors.pendingOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cuộc thi đang diễn ra',
                style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/goals'),
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Contest cards
        ..._activeContests.map((contest) => _buildContestCard(context, contest)),
      ],
    );
  }

  Widget _buildContestCard(BuildContext context, ContestModel contest) {
    final now = DateTime.now();
    final total = contest.endDate.difference(contest.startDate).inHours;
    final elapsed = now.difference(contest.startDate).inHours;
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
    final daysLeft = contest.endDate.difference(now).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/contests/${contest.id}'),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contest.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contest.groupName ?? 'Nhóm',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: daysLeft <= 1
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysLeft > 0 ? 'Còn $daysLeft ngày' : 'Hôm nay',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: daysLeft <= 1 ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.divider,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.group_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${contest.participants.length} người tham gia',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
