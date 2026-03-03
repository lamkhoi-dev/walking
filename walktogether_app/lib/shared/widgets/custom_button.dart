import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable primary/secondary/danger buttons matching Stitch design
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isDanger;
  final IconData? icon;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDanger = false,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? 56.0;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: h,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDanger ? AppColors.danger.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            foregroundColor: isDanger ? AppColors.danger : AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildChild(isDanger ? AppColors.danger : AppColors.primary),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDanger
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
          color: isDanger ? AppColors.danger : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDanger ? AppColors.danger : AppColors.primary).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildChild(Colors.white),
        ),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
