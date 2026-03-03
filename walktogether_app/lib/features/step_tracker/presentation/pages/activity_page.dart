import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/step_sync_service.dart';
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
    // Auto-start tracking when page loads
    final bloc = context.read<StepTrackerBloc>();
    if (bloc.state is StepTrackerInitial) {
      bloc.add(StepTrackerStartRequested());
    }
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
                child: StepStatCard(
                  icon: Icons.flag_rounded,
                  value: '${(state.progress * 100).toInt()}%',
                  label: 'Mục tiêu',
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tracking toggle & sync status
          _buildControlRow(context, state),
          const SizedBox(height: 24),

          // Hourly chart
          _buildHourlyChart(state.hourlySteps, state.todaySteps),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Lỗi bộ đếm bước',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<StepTrackerBloc>().add(StepTrackerStartRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
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
