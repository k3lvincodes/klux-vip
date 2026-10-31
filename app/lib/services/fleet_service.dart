import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FleetCategoryTier {
  const FleetCategoryTier({
    required this.name,
    required this.subtitle,
    required this.passengers,
    required this.luggage,
    required this.priceMultiplier,
    required this.gradientColors,
    required this.defaultAsset,
  });

  final String name; // 'Business Class', 'Business Van', 'First Class'
  final String subtitle;
  final int passengers;
  final int luggage;
  final double priceMultiplier;
  final List<Color> gradientColors;
  final String defaultAsset;
}

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
    this.category = 'Business Class',
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

  /// The 3 official Kenick VIP experience categories
  static const List<FleetCategoryTier> experienceCategories = [
    FleetCategoryTier(
      name: 'Business Class',
      subtitle: 'Mercedes-Benz EQE or similar',
      passengers: 3,
      luggage: 2,
      priceMultiplier: 1.0,
      gradientColors: [Color(0xFFBBE2D8), Color(0xFFF7F5F0)],
      defaultAsset: 'assets/images/car1.png',
    ),
    FleetCategoryTier(
      name: 'Business Van',
      subtitle: 'Mercedes-Benz V-Class or similar',
      passengers: 5,
      luggage: 5,
      priceMultiplier: 1.253, // ~€177.29 based on base fare
      gradientColors: [Color(0xFFF6D6B8), Color(0xFFFDFBF7)],
      defaultAsset: 'assets/images/ford.png',
    ),
    FleetCategoryTier(
      name: 'First Class',
      subtitle: 'Mercedes-Benz S-Class or similar',
      passengers: 3,
      luggage: 2,
      priceMultiplier: 1.51, // ~€213.68 based on base fare
      gradientColors: [Color(0xFF9ABDE2), Color(0xFFF5F7FA)],
      defaultAsset: 'assets/images/cadillac.png',
    ),
  ];

  static String autoCategorize(String make, String model) {
    final text = '$make $model'.toLowerCase();
    if (text.contains('van') ||
        text.contains('v-class') ||
        text.contains('v class') ||
        text.contains('vclass') ||
        text.contains('vito') ||
        text.contains('sprinter') ||
        text.contains('transit') ||
        text.contains('multivan') ||
        text.contains('caravelle') ||
        text.contains('metris') ||
        text.contains('escalade') ||
        text.contains('suburban') ||
        text.contains('navigator')) {
      return 'Business Van';
    }
    if (text.contains('s-class') ||
        text.contains('s class') ||
        text.contains('sclass') ||
        text.contains('maybach') ||
        text.contains('7 series') ||
        text.contains('7-series') ||
        text.contains('750') ||
        text.contains('760') ||
        text.contains('i7') ||
        text.contains('a8') ||
        text.contains('s8') ||
        text.contains('panamera') ||
        text.contains('flying spur') ||
        text.contains('phantom') ||
        text.contains('ghost') ||
        text.contains('rolls') ||
        text.contains('bentley')) {
      return 'First Class';
    }
    return 'Business Class';
  }

  static final List<FleetVehicleItem> fallbackFleet = [
    FleetVehicleItem(
      id: 'mercedes_eqe',
      name: 'Mercedes-Benz EQE',
      make: 'Mercedes-Benz',
      model: 'EQE',
      year: 2024,
            features: 'Executive Silent Cabin, Ambient Lighting, Fast Charging',
      localAssetPath: 'assets/images/car1.png',
      hasDriverAssigned: true,
    ),
    FleetVehicleItem(
      id: 'mercedes_vclass',
      name: 'Mercedes-Benz V-Class',
      make: 'Mercedes-Benz',
      model: 'V-Class',
      year: 2024,
      category: 'Business Van',
      features: 'Conference Seating, Massive Luggage Bay, Wi-Fi',
      localAssetPath: 'assets/images/ford.png',
      hasDriverAssigned: true,
    ),
    FleetVehicleItem(
      id: 'mercedes_sclass',
      name: 'Mercedes-Benz S-Class',
      make: 'Mercedes-Benz',
      model: 'S-Class',
      year: 2024,
      category: 'First Class',
      features: 'Rear Chauffeur Package, Executive Recline, Champagne Cooler',
      localAssetPath: 'assets/images/cadillac.png',
      hasDriverAssigned: true,
    ),
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
  ];

  static String matchLocalAsset(String make, String model) {
    final lower = '$make $model'.toLowerCase();
    if (lower.contains('cadillac') || lower.contains('s-class') || lower.contains('rolls')) {
      return 'assets/images/cadillac.png';
    }
    if (lower.contains('ford') || lower.contains('v-class') || lower.contains('van')) {
      return 'assets/images/ford.png';
    }
    if (lower.contains('gmc') || lower.contains('yukon')) {
      return 'assets/images/GMC.png';
    }
    return 'assets/images/car1.png';
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
          .select('id, make, model, year, image_url, features, category, is_available, is_featured')
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
          final category = (f['category'] as String?)?.isNotEmpty == true
              ? f['category'] as String
              : autoCategorize(make, model);

          return FleetVehicleItem(
            id: id,
            name: '$make $model',
            make: make,
            model: model,
            year: (f['year'] as num?)?.toInt() ?? 2024,
            imageUrl: imgUrl,
            category: category,
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
