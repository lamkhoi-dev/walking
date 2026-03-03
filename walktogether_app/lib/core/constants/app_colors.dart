import 'package:flutter/material.dart';

/// WalkTogether Design System Colors
/// Based on Stitch UI Design - Primary: #44c548
class AppColors {
  AppColors._();

  // === PRIMARY ===
  static const Color primary = Color(0xFF44C548);
  static const Color primaryDark = Color(0xFF369E3A);
  static const Color primaryLight = Color(0xFFE8F5E9);

  // === SECONDARY ===
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryDark = Color(0xFF1976D2);

  // === BACKGROUND ===
  static const Color background = Color(0xFFF6F8F6);
  static const Color surface = Color(0xFFFFFFFF);

  // === TEXT ===
  static const Color textMain = Color(0xFF101910);
  static const Color textMuted = Color(0xFF5B8B5C);
  static const Color textSecondary = Color(0xFF64748B);

  // === STATUS ===
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // === GRADIENT ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient contestGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === CHAT ===
  static const Color chatBg = Color(0xFFF5F7FA);
  static const Color chatBubbleReceived = Color(0xFFFFFFFF);
  static const Color chatBubbleSent = Color(0xFF4CAF50);

  // === MEDALS ===
  static const Color goldMedal = Color(0xFFFFD700);
  static const Color silverMedal = Color(0xFFC0C0C0);
  static const Color bronzeMedal = Color(0xFFCD7F32);

  // === MISC ===
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x0A000000);
  static const Color pendingOrange = Color(0xFFF97316);
}
