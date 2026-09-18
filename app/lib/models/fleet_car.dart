class FleetCar {
  FleetCar({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    this.imageUrl,
    this.features,
    this.isAvailable = true,
    this.isFeatured = false,
    required this.createdAt,
  });

  factory FleetCar.fromJson(Map<String, dynamic> json) {
    return FleetCar(
      id: json['id'] as String,
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      imageUrl: json['image_url'] as String?,
      features: json['features'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  final String id;
  final String make;
  final String model;
  final int year;
  final String? imageUrl;
  final String? features;
  final bool isAvailable;
  final bool isFeatured;
  final DateTime createdAt;

  String get displayName => '$year $make $model';

  /// Returns appropriate local asset fallback if imageUrl is absent or empty
  String get assetFallback {
    final lower = '$make $model'.toLowerCase();
    if (lower.contains('gmc') || lower.contains('yukon')) {
      return 'assets/images/GMC.png';
    } else if (lower.contains('cadillac') || lower.contains('escalade')) {
      return 'assets/images/cadillac.png';
    } else if (lower.contains('ford') || lower.contains('expedition') || lower.contains('lincoln') || lower.contains('navigator')) {
      return 'assets/images/ford.png';
    }
    return 'assets/images/car1.png';
  }

  /// Passenger seating capacity estimate
  int get passengerCapacity {
    final lower = '$make $model'.toLowerCase();
    if (lower.contains('escalade') || lower.contains('yukon') || lower.contains('suburban') || lower.contains('expedition') || lower.contains('navigator')) {
      return 6;
    } else if (lower.contains('sprinter')) {
      return 10;
    }
    return 4;
  }

  /// Luggage capacity estimate
  int get luggageCapacity {
    final lower = '$make $model'.toLowerCase();
    if (lower.contains('escalade') || lower.contains('yukon') || lower.contains('suburban') || lower.contains('expedition') || lower.contains('navigator')) {
      return 5;
    } else if (lower.contains('sprinter')) {
      return 8;
    }
    return 3;
  }

  /// VIP Tier label
  String get tierLabel {
    final lower = '$make $model'.toLowerCase();
    if (lower.contains('escalade') || lower.contains('yukon') || lower.contains('navigator')) {
      return 'First Class VIP SUV';
    } else if (lower.contains('maybach') || lower.contains('s-class') || lower.contains('7-series') || lower.contains('a8')) {
      return 'Executive Flagship Sedan';
    } else if (lower.contains('sprinter')) {
      return 'VIP Executive Jet Van';
    }
    return 'Executive VIP Fleet';
  }
}
