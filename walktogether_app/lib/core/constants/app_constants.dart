/// App-wide constants
class AppConstants {
  AppConstants._();

  // === TIMEOUTS ===
  static const int connectTimeout = 90000; // 90s for Render cold start
  static const int receiveTimeout = 90000;
  static const int sendTimeout = 30000;

  // === RETRY ===
  static const int maxRetries = 3;
  static const List<int> retryDelays = [5000, 15000, 30000]; // ms

  // === PAGINATION ===
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // === STEP COUNTER ===
  static const int stepSyncInterval = 300; // 5 minutes in seconds
  static const int dailyStepGoalDefault = 10000;

  // === COMPANY CODE ===
  static const int companyCodeLength = 6;

  // === FILE ===
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];

  // === ANIMATION ===
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // === BORDER RADIUS ===
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 9999.0;
}
