import 'package:supabase_flutter/supabase_flutter.dart';

class FleetVehicleItem {
  FleetVehicleItem({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    this.licensePlate,
    this.imageUrl,
    required this.localAssetPath,
    this.hasDriverAssigned = false,
  });

  final String id;
  final String name;
  final String make;
  final String model;
  final int year;
  final String? licensePlate;
  final String? imageUrl;
  final String localAssetPath;
  final bool hasDriverAssigned;
}

class FleetService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static final List<FleetVehicleItem> fallbackFleet = [
    FleetVehicleItem(
      id: 'gmc_yukon',
      name: 'GMC Yukon',
      make: 'GMC',
      model: 'Yukon',
      year: 2024,
      localAssetPath: 'assets/images/GMC.png',
    ),
    FleetVehicleItem(
      id: 'cadillac_escalade',
      name: 'Cadillac Escalade',
      make: 'Cadillac',
      model: 'Escalade',
      year: 2024,
      localAssetPath: 'assets/images/cadillac.png',
    ),
    FleetVehicleItem(
      id: 'ford_expedition',
      name: 'Ford Expedition',
      make: 'Ford',
      model: 'Expedition',
      year: 2024,
      localAssetPath: 'assets/images/ford.png',
    ),
  ];

  static String _matchLocalAsset(String make, String model) {
    final lower = '$make $model'.toLowerCase();
    if (lower.contains('cadillac')) return 'assets/images/cadillac.png';
    if (lower.contains('ford')) return 'assets/images/ford.png';
    return 'assets/images/GMC.png';
  }

  static Future<List<FleetVehicleItem>> getAvailableFleet() async {
    try {
      // 1. Check active vehicles in fleet that have a chauffeur assigned (max 3)
      final vehicleRows = await _supabase
          .from('vehicles')
          .select('id, driver_id, make, model, year, color, license_plate, images')
          .eq('is_active', true)
          .not('driver_id', 'is', null)
          .isFilter('deleted_at', null)
          .limit(3);

      if (vehicleRows.isNotEmpty) {
        return vehicleRows.map<FleetVehicleItem>((v) {
          final make = v['make'] as String? ?? 'Luxury';
          final model = v['model'] as String? ?? 'SUV';
          final images = v['images'] as List<dynamic>?;
          final imgUrl = (images != null && images.isNotEmpty) ? images.first.toString() : null;
          return FleetVehicleItem(
            id: v['id'] as String,
            name: '$make $model',
            make: make,
            model: model,
            year: (v['year'] as num?)?.toInt() ?? 2024,
            licensePlate: v['license_plate'] as String?,
            imageUrl: imgUrl,
            localAssetPath: _matchLocalAsset(make, model),
            hasDriverAssigned: true,
          );
        }).toList();
      }

      // 2. If no active vehicles with driver assigned, fetch featured fleet cars from catalog
      final fleetRows = await _supabase
          .from('fleet_cars')
          .select('id, make, model, year, image_url, is_featured')
          .eq('is_available', true)
          .isFilter('deleted_at', null)
          .order('is_featured', ascending: false)
          .limit(3);

      if (fleetRows.isNotEmpty) {
        return fleetRows.map<FleetVehicleItem>((f) {
          final make = f['make'] as String? ?? 'Luxury';
          final model = f['model'] as String? ?? 'SUV';
          final imgUrl = f['image_url'] as String?;
          return FleetVehicleItem(
            id: f['id'] as String,
            name: '$make $model',
            make: make,
            model: model,
            year: (f['year'] as num?)?.toInt() ?? 2024,
            imageUrl: imgUrl,
            localAssetPath: _matchLocalAsset(make, model),
          );
        }).toList();
      }
    } catch (_) {
      // Fallback cleanly on error
    }

    return fallbackFleet;
  }
}
