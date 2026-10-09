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
    this.category = 'Executive VIP',
    this.features = '',
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
  final String category;
  final String features;
}

class FleetService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static final List<FleetVehicleItem> fallbackFleet = [
    FleetVehicleItem(
      id: 'gmc_yukon',
      name: 'GMC Yukon Denali',
      make: 'GMC',
      model: 'Yukon Denali',
      year: 2024,
      features: 'Executive Captain Chairs, Chilled Console, Wi-Fi',
      localAssetPath: 'assets/images/GMC.png',
      hasDriverAssigned: true,
    ),
    FleetVehicleItem(
      id: 'cadillac_escalade',
      name: 'Cadillac Escalade Platinum',
      make: 'Cadillac',
      model: 'Escalade Platinum',
      year: 2024,
      features: 'Massaging Seats, AKG 36-Speaker Audio, Panoramic Glass',
      localAssetPath: 'assets/images/cadillac.png',
    ),
    FleetVehicleItem(
      id: 'ford_expedition',
      name: 'Ford Expedition Stealth',
      make: 'Ford',
      model: 'Expedition Stealth',
      year: 2024,
      features: 'Rear Entertainment, Privacy Tint, USB-C High Output',
      localAssetPath: 'assets/images/ford.png',
      hasDriverAssigned: true,
    ),
  ];

  static String matchLocalAsset(String make, String model) {
    final lower = '$make $model'.toLowerCase();
    if (lower.contains('cadillac')) return 'assets/images/cadillac.png';
    if (lower.contains('ford')) return 'assets/images/ford.png';
    return 'assets/images/GMC.png';
  }

  /// Returns all fleet cars from admin catalog with chauffeur availability
  static Future<List<FleetVehicleItem>> getAllFleetCarsWithChauffeurStatus() async {
    try {
      // 1. Fetch active assigned vehicles with drivers
      final vehicleRows = await _supabase
          .from('vehicles')
          .select('id, fleet_car_id, make, model, driver_id, is_active')
          .eq('is_active', true)
          .not('driver_id', 'is', null)
          .isFilter('deleted_at', null);

      final assignedFleetIds = <String>{};
      final assignedModels = <String>{};

      for (final v in vehicleRows) {
        final fid = v['fleet_car_id'] as String?;
        if (fid != null && fid.isNotEmpty) {
          assignedFleetIds.add(fid);
        }
        final make = (v['make'] as String? ?? '').trim().toLowerCase();
        final model = (v['model'] as String? ?? '').trim().toLowerCase();
        if (make.isNotEmpty && model.isNotEmpty) {
          assignedModels.add('$make $model');
        }
      }

      // 2. Fetch all fleet cars from admin catalog
      final fleetRows = await _supabase
          .from('fleet_cars')
          .select('id, make, model, year, image_url, features, is_available, is_featured')
          .eq('is_available', true)
          .isFilter('deleted_at', null)
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false);

      if (fleetRows.isNotEmpty) {
        return fleetRows.map<FleetVehicleItem>((f) {
          final id = f['id'] as String;
          final make = f['make'] as String? ?? 'VIP';
          final model = f['model'] as String? ?? 'Vehicle';
          final norm = '${make.trim().toLowerCase()} ${model.trim().toLowerCase()}';
          final hasChauffeur = assignedFleetIds.contains(id) || assignedModels.contains(norm);
          final imgUrl = f['image_url'] as String?;
          final features = f['features'] as String? ?? '';

          return FleetVehicleItem(
            id: id,
            name: '$make $model',
            make: make,
            model: model,
            year: (f['year'] as num?)?.toInt() ?? 2024,
            imageUrl: imgUrl,
            localAssetPath: matchLocalAsset(make, model),
            hasDriverAssigned: hasChauffeur,
            features: features,
          );
        }).toList();
      }
    } catch (_) {}

    return fallbackFleet;
  }

  static Future<List<FleetVehicleItem>> getAvailableFleet() async {
    return getAllFleetCarsWithChauffeurStatus();
  }
}
