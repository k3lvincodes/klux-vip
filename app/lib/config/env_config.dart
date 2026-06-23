class EnvConfig {
  EnvConfig._();

  // Supabase
  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  // Cloudinary
  static String get cloudinaryCloudName => _get('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryUploadPreset => _get('CLOUDINARY_UPLOAD_PRESET');

  // Mapbox
  static String get mapboxAccessToken => _get('MAPBOX_ACCESS_TOKEN');

  // Didit
  static String get diditApiKey => _get('DIDIT_API_KEY');
  static String get diditVerificationWorkflowId =>
      _get('DIDIT_VERIFICATION_WORKFLOW_ID');
  static String get diditWebhookSecret => _get('DIDIT_WEBHOOK_SECRET');

  // Resend
  static String get resendApiKey => _get('RESEND_API_KEY');
  static String get resendFromEmail => _get(
        'RESEND_FROM_EMAIL',
        fallback: 'Kenick Transportation LLC <onboarding@kenicktransportation.com>',
      );

  // Stripe
  static String get stripePublishableKey => _get('STRIPE_PUBLISHABLE_KEY');

  static String _get(String key, {String fallback = ''}) {
    final fromEnv = String.fromEnvironment(key);
    if (fromEnv.isNotEmpty) return fromEnv;
    return fallback;
  }
}
