import 'package:intl/intl.dart';

/// Utility helper functions
class Helpers {
  Helpers._();

  /// Format step count with thousand separator: 8432 → "8,432"
  static String formatSteps(int steps) {
    return NumberFormat('#,###').format(steps);
  }

  /// Format distance in km: 6.42 → "6.4 km"
  static String formatDistance(double km) {
    return '${km.toStringAsFixed(1)} km';
  }

  /// Format duration in minutes: 84 → "1h 24m"
  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  /// Format calories: 342 → "342 cal"
  static String formatCalories(int cal) {
    return '$cal cal';
  }

  /// Format date to Vietnamese style: "Thứ Hai, 02/03/2026"
  static String formatDateVN(DateTime date) {
    final dayOfWeek = DateFormat('EEEE', 'vi').format(date);
    final formatted = DateFormat('dd/MM/yyyy').format(date);
    return '$dayOfWeek, $formatted';
  }

  /// Format time: "14:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Relative time: "2 phút trước", "1 giờ trước"
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Calculate step progress percentage
  static double stepProgress(int current, int goal) {
    if (goal <= 0) return 0;
    return (current / goal).clamp(0.0, 1.0);
  }

  /// Estimate calories from steps (rough: ~0.04 cal per step)
  static int estimateCalories(int steps) {
    return (steps * 0.04).round();
  }

  /// Estimate distance in km from steps (avg stride: 0.762m)
  static double estimateDistance(int steps) {
    return (steps * 0.000762);
  }

  /// Estimate duration in minutes from steps (avg: 100 steps/min)
  static int estimateDuration(int steps) {
    return (steps / 100).round();
  }
}
