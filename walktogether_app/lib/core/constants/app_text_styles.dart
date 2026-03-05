import 'package:flutter/material.dart';
import 'app_colors.dart';

/// WalkTogether Text Styles - Font: Inter
class AppTextStyles {
  AppTextStyles._();

  // === HEADINGS ===
  static const TextStyle heading1 = TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textMain,
        letterSpacing: -0.5,
      );

  static const TextStyle heading2 = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
        letterSpacing: -0.3,
      );

  static const TextStyle heading3 = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      );

  static const TextStyle heading4 = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      );

  // === BODY ===
  static const TextStyle bodyLarge = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textMain,
      );

  static const TextStyle bodyMedium = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMain,
      );

  static const TextStyle bodySmall = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // === LABELS ===
  static const TextStyle labelLarge = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      );

  static const TextStyle labelMedium = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  static const TextStyle labelSmall = TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );

  // === BUTTON ===
  static const TextStyle buttonLarge = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static const TextStyle buttonMedium = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // === SPECIAL ===
  static const TextStyle stepCount = TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.textMain,
        letterSpacing: -1,
      );

  static const TextStyle statNumber = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      );
}
