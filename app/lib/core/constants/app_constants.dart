class AppConstants {
  AppConstants._();

  static const String appName = 'Kenick';
  static const String appVersion = '1.0.0+1';
  static const String packageName = 'kenick_vip';

  // Biometric lock thresholds
  static const Duration shortLockThreshold = Duration(minutes: 2);
  static const Duration mediumLockThreshold = Duration(minutes: 15);

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 280);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxRideHistory = 100;
}
