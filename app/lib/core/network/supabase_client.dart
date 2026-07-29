import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabaseClient {
  AppSupabaseClient._();

  static AppSupabaseClient? _instance;
  static AppSupabaseClient get instance => _instance ??= AppSupabaseClient._();

  SupabaseClient get client => Supabase.instance.client;

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  // Database helpers
  GoTrueClient get auth => client.auth;
  PostgrestQueryBuilder from(String table) => client.from(table);
  PostgrestFilterBuilder fromFilter(String table) => client.from(table).select();
}
