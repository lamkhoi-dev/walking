import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// "Đang gõ..." indicator with animated dots
class TypingIndicator extends StatefulWidget {
  final List<String> typingNames;

  const TypingIndicator({
    super.key,
    required this.typingNames,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingNames.isEmpty) return const SizedBox.shrink();

    final text = widget.typingNames.length == 1
        ? '${widget.typingNames.first} đang gõ'
        : '${widget.typingNames.length} người đang gõ';

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          // Animated dots
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value =
                      ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                  final opacity = (1.0 - (value * 2 - 1).abs()).clamp(0.3, 1.0);
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
