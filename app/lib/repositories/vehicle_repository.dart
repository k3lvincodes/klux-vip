import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getDriverVehicles(String driverId) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch vehicles: $e');
    }
  }

  Future<Map<String, dynamic>?> getActiveVehicle(String driverId) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch active vehicle: $e');
    }
  }

  Future<String> registerVehicle({
    required String driverId,
    required String make,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
  }) async {
    try {
      await _supabase
          .from('vehicles')
          .update({'is_active': false})
          .eq('driver_id', driverId);

      final response = await _supabase
          .from('vehicles')
          .insert({
            'driver_id': driverId,
            'make': make,
            'model': model,
            'year': year,
            'color': color,
            'license_plate': licensePlate.toUpperCase(),
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
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (make != null) updates['make'] = make;
      if (model != null) updates['model'] = model;
      if (year != null) updates['year'] = year;
      if (color != null) updates['color'] = color;
      if (licensePlate != null) {
        updates['license_plate'] = licensePlate.toUpperCase();
      }
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase.from('vehicles').update(updates).eq('id', vehicleId);
    } catch (e) {
      throw Exception('Failed to update vehicle: $e');
    }
  }

  Future<void> setActiveVehicle(String driverId, String vehicleId) async {
    try {
      await _supabase
          .from('vehicles')
          .update({'is_active': false})
          .eq('driver_id', driverId);
      await _supabase
          .from('vehicles')
          .update({'is_active': true})
          .eq('id', vehicleId);
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
