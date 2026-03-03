import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Centered system message (e.g., "Nguyễn Văn A đã tham gia nhóm")
class SystemMessage extends StatelessWidget {
  final String content;

  const SystemMessage({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.divider.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
