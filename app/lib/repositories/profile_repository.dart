import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getDriverProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('*, driver_details(*)')
          .eq('id', userId)
          .or('role.eq.chauffeur,role.is.null')
          .maybeSingle();
      return data;
    } catch (e) {
      throw Exception('Failed to fetch chauffeur profile: $e');
    }
  }

  Future<void> createOrUpdateDriverProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final email = _supabase.auth.currentUser?.email;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email ?? '',
        'role': 'chauffeur',
        ...profileData,
      });
      await _supabase.from('driver_details').upsert({
        'profile_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to update chauffeur profile: $e');
    }
  }

  Future<void> updateDriverLocationAndStatus(String userId, double lat, double lng, bool isOnline) async {
    try {
      await _supabase.from('driver_details').upsert({
        'profile_id': userId,
        'last_location': 'POINT($lng $lat)',
        'is_online': isOnline,
      });
    } catch (e) {
      throw Exception('Failed to update location status: $e');
    }
  }

  Future<Map<String, dynamic>?> getPassengerProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .or('role.eq.client,role.is.null')
          .maybeSingle();
      return data;
    } catch (e) {
      throw Exception('Failed to fetch client profile: $e');
    }
  }

  Future<void> createOrUpdatePassengerProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final email = _supabase.auth.currentUser?.email;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email ?? '',
        'role': 'client',
        ...profileData,
      });
    } catch (e) {
      throw Exception('Failed to update client profile: $e');
    }
  }

  Future<void> markEmailVerified(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'email_verified_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to mark email verified: $e');
    }
  }
}
