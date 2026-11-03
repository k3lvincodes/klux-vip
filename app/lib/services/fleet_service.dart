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
  });

  final String name; // 'Business Class', 'Business Van', 'First Class'
  final String subtitle;
  final int passengers;
  final int luggage;
  final double priceMultiplier;
  final List<Color> gradientColors;
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
    this.localAssetPath,
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
  final String? localAssetPath;
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
      subtitle: 'Executive sedans • Up to 3 passengers',
      passengers: 3,
      luggage: 2,
      priceMultiplier: 1.0,
      gradientColors: [Color(0xFFBBE2D8), Color(0xFFF7F5F0)],
    ),
    FleetCategoryTier(
      name: 'Business Van',
      subtitle: 'Luxury SUVs & Vans • Up to 6 passengers',
      passengers: 6,
      luggage: 5,
      priceMultiplier: 1.253, // ~€177.29 based on base fare
      gradientColors: [Color(0xFFF6D6B8), Color(0xFFFDFBF7)],
    ),
    FleetCategoryTier(
      name: 'First Class',
      subtitle: 'Flagship luxury sedans • Up to 3 passengers',
      passengers: 3,
      luggage: 2,
      priceMultiplier: 1.51, // ~€213.68 based on base fare
      gradientColors: [Color(0xFF9ABDE2), Color(0xFFF5F7FA)],
    ),
  ];

  static String autoCategorize(String make, String model, [int? year]) {
    final text = '$make $model'.toLowerCase();

    // Criteria 2: Business Van / Full-size Luxury SUV
    final isVan = text.contains('van') ||
        text.contains('v-class') ||
        text.contains('v class') ||
        text.contains('vclass') ||
        text.contains('vito') ||
        text.contains('sprinter') ||
        text.contains('transit') ||
        text.contains('multivan') ||
        text.contains('caravelle') ||
        text.contains('metris') ||
        text.contains('alphard') ||
        text.contains('vellfire') ||
        text.contains('escalade') ||
        text.contains('suburban') ||
        text.contains('navigator') ||
        text.contains('yukon') ||
        text.contains('tahoe');

    if (isVan) {
      return 'Business Van';
    }

    // Criteria 3: First Class Flagship Sedans
    final isFlagship = text.contains('s-class') ||
        text.contains('s class') ||
        text.contains('sclass') ||
        text.contains('maybach') ||
        text.contains('s 580') ||
        text.contains('s 680') ||
        text.contains('s580') ||
        text.contains('s680') ||
        text.contains('7 series') ||
        text.contains('7-series') ||
        text.contains('740') ||
        text.contains('750') ||
        text.contains('760') ||
        text.contains('i7') ||
        text.contains('a8') ||
        text.contains('s8') ||
        text.contains('panamera') ||
        text.contains('flying spur') ||
        text.contains('phantom') ||
        text.contains('ghost') ||
        text.contains('continental') ||
        text.contains('rolls') ||
        text.contains('bentley') ||
        text.contains('eqs');

    if (isFlagship) {
      return 'First Class';
    }

    // Criteria 1: Business Class Executive Sedans
    return 'Business Class';
  }

  /// Returns real fleet cars from admin catalog with chauffeur availability
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

      // 2. Fetch all real fleet cars from database catalog
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
          final year = (f['year'] as num?)?.toInt() ?? 2024;
          final category = autoCategorize(make, model, year);

          return FleetVehicleItem(
            id: id,
            name: '$make $model',
            make: make,
            model: model,
            year: year,
            imageUrl: imgUrl,
            category: category,
            hasDriverAssigned: hasChauffeur,
            features: features,
          );
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<List<FleetVehicleItem>> getAvailableFleet() async {
    return getAllFleetCarsWithChauffeurStatus();
  }
}
