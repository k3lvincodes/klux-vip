import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Driver Profile Methods
  Future<Map<String, dynamic>?> getDriverProfile(String userId) async {
    try {
      final data = await _supabase
          .from('driver_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      throw Exception('Failed to fetch driver profile: $e');
    }
  }

  Future<void> createOrUpdateDriverProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      await _supabase.from('driver_profiles').upsert({
        'user_id': userId,
        ...profileData,
      });
    } catch (e) {
      throw Exception('Failed to update driver profile: $e');
    }
  }

  Future<void> updateDriverLocationAndStatus(String userId, double lat, double lng, bool isOnline) async {
    try {
      // NOTE: PostGIS geography point format: 'POINT(lon lat)'
      await _supabase.from('driver_profiles').update({
        'current_location': 'POINT($lng $lat)',
        'is_online': isOnline,
      }).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update location status: $e');
    }
  }

  // Passenger Profile Methods
  Future<Map<String, dynamic>?> getPassengerProfile(String userId) async {
    try {
      final data = await _supabase
          .from('passenger_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      throw Exception('Failed to fetch passenger profile: $e');
    }
  }

  Future<void> createOrUpdatePassengerProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      await _supabase.from('passenger_profiles').upsert({
        'user_id': userId,
        ...profileData,
      });
    } catch (e) {
      throw Exception('Failed to update passenger profile: $e');
    }
  }
}
