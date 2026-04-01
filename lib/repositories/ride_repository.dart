import 'package:supabase_flutter/supabase_flutter.dart';

class RideRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Requests a new ride as a passenger
  Future<String> requestRide({
    required String passengerId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required double fareAmount,
    String type = 'instant', // instant, scheduled, special
    DateTime? scheduledTime,
  }) async {
    try {
      final response = await _supabase.from('rides').insert({
        'passenger_id': passengerId,
        'pickup_location': 'POINT($pickupLng $pickupLat)',
        'pickup_address': pickupAddress,
        'dropoff_location': 'POINT($dropoffLng $dropoffLat)',
        'dropoff_address': dropoffAddress,
        'fare_amount': fareAmount,
        'type': type,
        'scheduled_time': scheduledTime?.toIso8601String(),
        'status': 'requested',
      }).select().single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to request ride: $e');
    }
  }

  /// Driver accepts a requested ride
  Future<void> acceptRide(String rideId, String driverId) async {
    try {
      await _supabase.from('rides').update({
        'driver_id': driverId,
        'status': 'accepted',
      }).eq('id', rideId);
    } catch (e) {
      throw Exception('Failed to accept ride: $e');
    }
  }

  /// Updates the status of an active ride
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await _supabase.from('rides').update({
        'status': status,
      }).eq('id', rideId);
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  /// Listens to real-time changes on a specific ride
  Stream<Map<String, dynamic>> listenToRide(String rideId) {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .map((events) => events.first);
  }

  /// Listens to newly requested rides (For drivers with status='requested')
  Stream<List<Map<String, dynamic>>> listenToRequestedRides() {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('status', 'requested')
        .map((events) => events);
  }
}
