import 'package:kenick_vip/models/vehicle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Vehicle>> getDriverVehicles(String driverId) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get vehicles: $e');
    }
  }

  Future<Vehicle?> getActiveVehicle(String driverId) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .maybeSingle();
      if (response == null) return null;
      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get active vehicle: $e');
    }
  }

  Future<String> registerVehicle({
    required String driverId,
    required String make,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
    required List<String> images,
  }) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .insert({
            'driver_id': driverId,
            'make': make,
            'model': model,
            'year': year,
            'color': color,
            'license_plate': licensePlate,
            'images': images,
            'is_active': true,
          })
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to register vehicle: $e');
    }
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String make,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
  }) async {
    try {
      await _supabase.from('vehicles').update({
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'license_plate': licensePlate,
      }).eq('id', vehicleId);
    } catch (e) {
      throw Exception('Failed to update vehicle: $e');
    }
  }

  Future<void> setActiveVehicle(String driverId, String vehicleId) async {
    try {
      await _supabase.from('vehicles').update({'is_active': false}).eq('driver_id', driverId).neq('id', vehicleId);
      await _supabase.from('vehicles').update({'is_active': true}).eq('id', vehicleId);
    } catch (e) {
      throw Exception('Failed to set active vehicle: $e');
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _supabase.from('vehicles').delete().eq('id', vehicleId);
    } catch (e) {
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  /// Get active fleet vehicles from admin catalog
  Future<List<Map<String, dynamic>>> getFleetCars() async {
    try {
      final response = await _supabase
          .from('fleet_cars')
          .select()
          .isFilter('deleted_at', null)
          .eq('is_available', true)
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load fleet catalog: $e');
    }
  }

  /// Assign and activate an admin fleet car for the chauffeur
  Future<void> selectFleetCarForDriver({
    required String driverId,
    required String fleetCarId,
    required String make,
    required String model,
    required int year,
    required String licensePlate,
    String? imageUrl,
  }) async {
    try {
      // 1. Deactivate other vehicles for this driver
      await _supabase
          .from('vehicles')
          .update({'is_active': false})
          .eq('driver_id', driverId);

      // 2. Check if an assignment for this fleet_car_id already exists for this chauffeur
      final existing = await _supabase
          .from('vehicles')
          .select('id')
          .eq('driver_id', driverId)
          .eq('fleet_car_id', fleetCarId)
          .maybeSingle();

      if (existing != null) {
        // Reactivate and update license plate
        await _supabase.from('vehicles').update({
          'is_active': true,
          'license_plate': licensePlate,
          'color': 'Black',
          'images': imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : [],
        }).eq('id', existing['id']);
      } else {
        // Insert new active vehicle
        await _supabase.from('vehicles').insert({
          'driver_id': driverId,
          'make': make,
          'model': model,
          'year': year,
          'color': 'Black',
          'license_plate': licensePlate,
          'fleet_car_id': fleetCarId,
          'is_active': true,
          'images': imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : [],
        });
      }
    } catch (e) {
      throw Exception('Failed to select fleet car: $e');
    }
  }

  /// Submit an AI-vetted custom VIP vehicle request to admin
  Future<void> submitVehicleRequest({
    required String chauffeurId,
    required String make,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
    List<String> images = const [],
  }) async {
    try {
      await _supabase.from('vehicle_requests').insert({
        'chauffeur_id': chauffeurId,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'license_plate': licensePlate,
        'images': images,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to submit vehicle request: $e');
    }
  }

  /// Get pending vehicle requests for this chauffeur
  Future<List<Map<String, dynamic>>> getDriverVehicleRequests(String chauffeurId) async {
    try {
      final response = await _supabase
          .from('vehicle_requests')
          .select()
          .eq('chauffeur_id', chauffeurId)
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}
