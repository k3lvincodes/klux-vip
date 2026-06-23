import 'package:flutter/foundation.dart';
import 'package:kenick_vip/models/ride.dart';
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
          .from('ride_requests')
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
            'status': 'pending',
          })
          .select()
          .single();

      final requestId = response['id'] as String;

      if (type == 'instant') {
        try {
          await _supabase.functions.invoke(
            'matchmaker',
            body: {
              'ride_id': requestId,
              'pickup_lat': pickupLat,
              'pickup_lng': pickupLng,
            },
          );
        } catch (e) {
          debugPrint('Matchmaker dispatch (non-fatal): $e');
        }
      }

      return requestId;
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

  Future<void> updateDriverLocation(String rideId, double lat, double lng) async {
    try {
      await _supabase.from('rides').update({
        'driver_lat': lat,
        'driver_lng': lng,
      }).eq('id', rideId);
    } catch (e) {
      debugPrint('Failed to update driver location: $e');
    }
  }

  Stream<Ride> listenToRide(String rideId) {
    return _supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .map((events) => Ride.fromJson(events.first));
  }

  Stream<List<Map<String, dynamic>>> listenToRequestedRides() {
    return _supabase
        .from('ride_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((events) => events)
        .handleError((Object error) {
          debugPrint('listenToRequestedRides error: $error');
          return <Map<String, dynamic>>[];
        });
  }

  Future<List<Ride>> getDriverCompletedRides(String driverId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('rides')
          .select()
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List).map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
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
