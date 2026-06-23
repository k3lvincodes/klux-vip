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
}
