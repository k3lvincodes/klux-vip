import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> requestRide({
    required String passengerId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required double fareAmount,
    String type = 'instant',
    DateTime? scheduledTime,
    String? passengerNote,
  }) async {
    try {
      final response = await _supabase
          .from('rides')
          .insert({
            'passenger_id': passengerId,
            'pickup_location': 'POINT($pickupLng $pickupLat)',
            'pickup_address': pickupAddress,
            'dropoff_location': 'POINT($dropoffLng $dropoffLat)',
            'dropoff_address': dropoffAddress,
            'fare_amount': fareAmount,
            'type': type,
            'scheduled_time': scheduledTime?.toIso8601String(),
            if (passengerNote != null && passengerNote.isNotEmpty) 'passenger_note': passengerNote,
            'status': 'requested',
          })
          .select()
          .single();

      final rideId = response['id'] as String;

      if (type == 'instant') {
        await _supabase.functions.invoke(
          'matchmaker',
          body: {
            'ride_id': rideId,
            'pickup_lat': pickupLat,
            'pickup_lng': pickupLng,
          },
        );
      }

      return rideId;
    } catch (e) {
      throw Exception('Failed to request ride: $e');
    }
  }

  Future<void> acceptRide(String rideId, String driverId) async {
    try {
      await _supabase.rpc(
        'accept_ride',
        params: {'ride_uuid': rideId, 'driver_uuid': driverId},
      );
    } catch (e) {
      throw Exception('Failed to accept ride: $e');
    }
  }

  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await _supabase.from('rides').update({'status': status}).eq('id', rideId);
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  Stream<Map<String, dynamic>> listenToRide(String rideId) {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .map((events) => events.first);
  }

  Stream<List<Map<String, dynamic>>> listenToRequestedRides() {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('status', 'requested')
        .map((events) => events)
        .handleError((Object error) {
          debugPrint('listenToRequestedRides error: $error');
          return <Map<String, dynamic>>[];
        });
  }

  Future<List<Map<String, dynamic>>> getDriverCompletedRides(String driverId) async {
    try {
      final response = await _supabase
          .from('rides')
          .select()
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch completed rides: $e');
    }
  }

  Future<double> calculateFare({
    required double distanceMeters,
    required int durationSeconds,
    String bookingType = 'instant',
  }) async {
    try {
      final response = await _supabase.rpc(
        'calculate_fare',
        params: {
          'distance_meters': distanceMeters,
          'duration_seconds': durationSeconds,
          'booking_type': bookingType,
        },
      );
      return (response as num).toDouble();
    } catch (e) {
      throw Exception('Failed to calculate fare: $e');
    }
  }
}
