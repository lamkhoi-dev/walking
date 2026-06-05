import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/step_sync_service.dart';

/// Widget displaying sync status with icon and label.
class SyncStatusWidget extends StatelessWidget {
  final StepSyncStatus status;
  final DateTime? lastSyncTime;
  final VoidCallback? onTapSync;

  const SyncStatusWidget({
    super.key,
    required this.status,
    this.lastSyncTime,
    this.onTapSync,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapSync,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(width: 6),
            Text(
              _label,
              style: AppTextStyles.labelSmall.copyWith(
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (status) {
      case StepSyncStatus.syncing:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _textColor,
          ),
        );
      case StepSyncStatus.synced:
        return Icon(Icons.cloud_done_rounded, size: 16, color: _textColor);
      case StepSyncStatus.offline:
        return Icon(Icons.cloud_off_rounded, size: 16, color: _textColor);
      case StepSyncStatus.error:
        return Icon(Icons.sync_problem_rounded, size: 16, color: _textColor);
      case StepSyncStatus.idle:
        return Icon(Icons.sync_rounded, size: 16, color: _textColor);
    }
  }

  String get _label {
    switch (status) {
      case StepSyncStatus.syncing:
        return 'step_tracker.syncing'.tr();
      case StepSyncStatus.synced:
        return _lastSyncLabel;
      case StepSyncStatus.offline:
        return 'step_tracker.offline'.tr();
      case StepSyncStatus.error:
        return 'step_tracker.sync_failed'.tr();
      case StepSyncStatus.idle:
        return 'step_tracker.tap_to_sync'.tr();
    }
  }

  String get _lastSyncLabel {
    if (lastSyncTime == null) return 'step_tracker.synced'.tr();
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inMinutes < 1) return 'step_tracker.synced'.tr();
    if (diff.inMinutes < 60) return 'step_tracker.sync_minutes_ago'.tr(namedArgs: {'n': diff.inMinutes.toString()});
    return 'step_tracker.sync_hours_ago'.tr(namedArgs: {'n': diff.inHours.toString()});
  }

  Color get _bgColor {
    switch (status) {
      case StepSyncStatus.synced:
        return AppColors.success.withValues(alpha: 0.1);
      case StepSyncStatus.syncing:
        return AppColors.info.withValues(alpha: 0.1);
      case StepSyncStatus.offline:
        return AppColors.warning.withValues(alpha: 0.1);
      case StepSyncStatus.error:
        return AppColors.danger.withValues(alpha: 0.1);
      case StepSyncStatus.idle:
        return AppColors.textSecondary.withValues(alpha: 0.1);
    }
  }

  Color get _textColor {
    switch (status) {
      case StepSyncStatus.synced:
        return AppColors.success;
      case StepSyncStatus.syncing:
        return AppColors.info;
      case StepSyncStatus.offline:
        return AppColors.warning;
      case StepSyncStatus.error:
        return AppColors.danger;
      case StepSyncStatus.idle:
        return AppColors.textSecondary;
    }
  }
}
