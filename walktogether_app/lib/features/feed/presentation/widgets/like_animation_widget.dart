import 'dart:math';
import 'package:flutter/material.dart';

/// Heart animation overlay for double-tap like gesture.
/// Shows a heart icon with scale/opacity animation + sparkle particles.
class LikeAnimationWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onDoubleTap;
  final bool isLiked;

  const LikeAnimationWidget({
    super.key,
    required this.child,
    required this.onDoubleTap,
    required this.isLiked,
  });

  @override
  State<LikeAnimationWidget> createState() => _LikeAnimationWidgetState();
}

class _LikeAnimationWidgetState extends State<LikeAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showHeart = false;

  // Pre-generated sparkle positions
  final List<_Sparkle> _sparkles = List.generate(8, (i) {
    final angle = (i / 8) * 2 * pi;
    return _Sparkle(angle: angle, delay: i * 0.05);
  });

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 0.95),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_heartController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartController);

    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    widget.onDoubleTap();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
    _particleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart) ...[
            // Sparkle particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(120, 120),
                  painter: _SparklePainter(
                    progress: _particleController.value,
                    sparkles: _sparkles,
                  ),
                );
              },
            ),
            // Heart icon
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, _) {
                return Opacity(
                  opacity: _opacityAnimation.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _scaleAnimation.value.clamp(0.0, 2.0),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF6B81), Color(0xFFE91E63)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 80,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 24, color: Color(0x44E91E63)),
                          Shadow(blurRadius: 8, color: Color(0x33000000)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Sparkle {
  final double angle;
  final double delay;

  _Sparkle({required this.angle, required this.delay});
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final List<_Sparkle> sparkles;

  _SparklePainter({required this.progress, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);

    for (final sparkle in sparkles) {
      final adjustedProgress =
          ((progress - sparkle.delay) / (1 - sparkle.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final distance = 30 + adjustedProgress * 35;
      final opacity = adjustedProgress < 0.6
          ? adjustedProgress / 0.6
          : 1.0 - ((adjustedProgress - 0.6) / 0.4);
      final radius = 2.5 * (1 - adjustedProgress * 0.5);

      final x = center.dx + cos(sparkle.angle) * distance;
      final y = center.dy + sin(sparkle.angle) * distance;

      final paint = Paint()
        ..color = const Color(0xFFFF6B81).withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
