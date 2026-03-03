import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Animated circular progress ring showing step count progress toward goal.
class StepProgressRing extends StatelessWidget {
  final int currentSteps;
  final int goalSteps;
  final double size;

  const StepProgressRing({
    super.key,
    required this.currentSteps,
    required this.goalSteps,
    this.size = 220,
  });

  double get _progress => goalSteps > 0 ? currentSteps / goalSteps : 0.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: _progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              isGoalReached: _progress >= 1.0,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_walk_rounded,
                size: 28,
                color: _progress >= 1.0 ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                _formatNumber(currentSteps),
                style: AppTextStyles.stepCount.copyWith(
                  color: _progress >= 1.0 ? AppColors.primary : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'bước',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '/ ${_formatNumber(goalSteps)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final k = n ~/ 1000;
      final r = (n % 1000) ~/ 100;
      if (r == 0) return '${k}K';
      return '$k.${r}K';
    }
    return n.toString();
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isGoalReached;

  _RingPainter({
    required this.progress,
    required this.isGoalReached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isGoalReached) {
        progressPaint.shader = const SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [
            AppColors.primary,
            Color(0xFF66BB6A),
            AppColors.primary,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      } else {
        progressPaint.shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: const [
            AppColors.primary,
            Color(0xFF81C784),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      }

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isGoalReached != isGoalReached;
  }
}
