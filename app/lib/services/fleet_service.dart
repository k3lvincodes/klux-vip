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

  final String name; // 'Sedans', 'SUVs', 'Vans', 'Buses'
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
    this.category = 'Sedans',
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

  /// The official Kenick VIP client categories (Sedans, SUVs, Vans, Buses)
  /// Pricing order: Sedans (lowest) < SUVs < Vans < Buses (highest)
  static const List<FleetCategoryTier> experienceCategories = [
    FleetCategoryTier(
      name: 'Sedans',
      subtitle: 'Executive & luxury sedans • Up to 3 passengers',
      passengers: 3,
      luggage: 2,
      priceMultiplier: 1.0, // Lowest pricing
      gradientColors: [Color(0xFFBBE2D8), Color(0xFFF7F5F0)],
    ),
    FleetCategoryTier(
      name: 'SUVs',
      subtitle: 'Prestige full-size & luxury SUVs • Up to 5 passengers',
      passengers: 5,
      luggage: 4,
      priceMultiplier: 1.25, // Higher than Sedans
      gradientColors: [Color(0xFF9ABDE2), Color(0xFFF5F7FA)],
    ),
    FleetCategoryTier(
      name: 'Vans',
      subtitle: 'Executive MPVs & luxury Sprinters • Up to 7 passengers',
      passengers: 7,
      luggage: 6,
      priceMultiplier: 1.45, // Higher than SUVs
      gradientColors: [Color(0xFFF6D6B8), Color(0xFFFDFBF7)],
    ),
    FleetCategoryTier(
      name: 'Buses',
      subtitle: 'VIP coaches & delegation minibuses • Up to 16+ passengers',
      passengers: 16,
      luggage: 14,
      priceMultiplier: 1.80, // Highest pricing
      gradientColors: [Color(0xFFD8B4E2), Color(0xFFFAF5FD)],
    ),
  ];

  static String? normalizeCategory(String? rawCategory, [String? make, String? model, int? year]) {
    if (rawCategory != null && rawCategory.isNotEmpty) {
      final c = rawCategory.trim().toLowerCase();
      if (c == 'none') return null;
      if (c == 'sedans' || c == 'sedan') return 'Sedans';
      if (c == 'suvs' || c == 'suv') return 'SUVs';
      if (c == 'vans' || c == 'van') return 'Vans';
      if (c == 'buses' || c == 'bus') return 'Buses';
    }
    return null;
  }

  static String autoCategorize(String make, String model, [int? year]) {
    final text = '$make $model'.toLowerCase();

    // 1. Buses: Minibuses, Coaches, High-capacity Shuttles (highest tier)
    final isBus = text.contains('bus') ||
        text.contains('minibus') ||
        text.contains('coach') ||
        text.contains('coaster') ||
        text.contains('rosa') ||
        text.contains('tourliner') ||
        text.contains('setra') ||
        text.contains('sprinter 15') ||
        text.contains('sprinter 16') ||
        text.contains('sprinter 18') ||
        text.contains('sprinter 20') ||
        text.contains('transit 15') ||
        text.contains('transit 14') ||
        text.contains('crafter 16') ||
        text.contains('intercity');

    if (isBus) {
      return 'Buses';
    }

    // 2. Vans: Executive MPVs, Passenger Vans, Standard Sprinters
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
        text.contains('carnival') ||
        text.contains('sienna') ||
        text.contains('odyssey') ||
        text.contains('pacifica') ||
        text.contains('transporter');

    if (isVan) {
      return 'Vans';
    }

    // 3. SUVs: Full-size & luxury SUVs
    final isSuv = text.contains('suv') ||
        text.contains('escalade') ||
        text.contains('suburban') ||
        text.contains('yukon') ||
        text.contains('tahoe') ||
        text.contains('navigator') ||
        text.contains('expedition') ||
        text.contains('gle') ||
        text.contains('gls') ||
        text.contains('g-class') ||
        text.contains('g class') ||
        text.contains('g-wagon') ||
        text.contains('gwagon') ||
        text.contains('x5') ||
        text.contains('x7') ||
        text.contains('q7') ||
        text.contains('q8') ||
        text.contains('cayenne') ||
        text.contains('urus') ||
        text.contains('cullinan') ||
        text.contains('bentayga') ||
        text.contains('range rover') ||
        text.contains('land rover') ||
        text.contains('defender') ||
        text.contains('discovery') ||
        text.contains('lx 600') ||
        text.contains('lx 570') ||
        text.contains('gx') ||
        text.contains('sequoia') ||
        text.contains('cherokee') ||
        text.contains('patrol') ||
        text.contains('land cruiser') ||
        text.contains('armada') ||
        text.contains('telluride') ||
        text.contains('palisade') ||
        text.contains('aviator');

    if (isSuv) {
      return 'SUVs';
    }

    // 4. Sedans: Default for executive & luxury sedans (lowest pricing)
    return 'Sedans';
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
          .select('id, make, model, year, image_url, features, category, is_available, is_featured')
          .eq('is_available', true)
          .isFilter('deleted_at', null)
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false);

      if (fleetRows.isNotEmpty) {
        final items = <FleetVehicleItem>[];
        for (final f in fleetRows) {
          final rawCategory = f['category'] as String?;
          final category = normalizeCategory(rawCategory);
          // Only show cars with a valid category set in admin
          if (category == null) continue;

          final id = f['id'] as String;
          final make = f['make'] as String? ?? 'VIP';
          final model = f['model'] as String? ?? 'Vehicle';
          final norm = '${make.trim().toLowerCase()} ${model.trim().toLowerCase()}';
          final hasChauffeur = assignedFleetIds.contains(id) || assignedModels.contains(norm);
          final imgUrl = f['image_url'] as String?;
          final features = f['features'] as String? ?? '';
          final year = (f['year'] as num?)?.toInt() ?? 2024;

          items.add(FleetVehicleItem(
            id: id,
            name: '$make $model',
            make: make,
            model: model,
            year: year,
            imageUrl: imgUrl,
            category: category,
            hasDriverAssigned: hasChauffeur,
            features: features,
          ));
        }
        return items;
      }
    } catch (_) {}

    return [];
  }

  static Future<List<FleetVehicleItem>> getAvailableFleet() async {
    return getAllFleetCarsWithChauffeurStatus();
  }
}
