class ApiConstants {
  ApiConstants._();

  // Edge function endpoints
  static const String createBooking = 'create-booking';
  static const String matchmaker = 'matchmaker';
  static const String payments = 'payments';
  static const String stripeWebhook = 'stripe-webhook';
  static const String notifications = 'notifications';
  static const String emailNotifications = 'email-notifications';
  static const String smsNotifications = 'sms-notifications';
  static const String diditLookup = 'didit-lookup';
  static const String diditWebhook = 'didit-webhook';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
