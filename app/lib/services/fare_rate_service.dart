import 'package:supabase_flutter/supabase_flutter.dart';

class FareRate {
  final String id;
  final String countryCode;
  final String? stateOrRegion;
  final double perKmRate;
  final double baseFare;
  final double perMinuteRate;

  FareRate({
    required this.id,
    required this.countryCode,
    this.stateOrRegion,
    required this.perKmRate,
    required this.baseFare,
    required this.perMinuteRate,
  });

  factory FareRate.fromMap(Map<String, dynamic> map) {
    return FareRate(
      id: map['id'] as String,
      countryCode: map['country_code'] as String,
      stateOrRegion: map['state_or_region'] as String?,
      perKmRate: (map['per_km_rate'] as num).toDouble(),
      baseFare: (map['base_fare'] as num).toDouble(),
      perMinuteRate: (map['per_minute_rate'] as num).toDouble(),
    );
  }
}

class FareRateService {
  static final _supabase = Supabase.instance.client;

  static FareRate? _cached;
  static double get _defaultPerKmRate => 1.85;
  static double get _defaultBaseFare => 3.50;
  static double get _defaultPerMinuteRate => 0.45;

  static Future<FareRate> getRate(String countryCode) async {
    if (_cached != null && _cached!.countryCode == countryCode) {
      return _cached!;
    }

    try {
      final data = await _supabase
          .from('fare_rates')
          .select()
          .eq('country_code', countryCode)
          .isFilter('state_or_region', null)
          .maybeSingle();

      if (data != null) {
        _cached = FareRate.fromMap(data);
        return _cached!;
      }
    } catch (_) {}

    return FareRate(
      id: 'default',
      countryCode: countryCode,
      perKmRate: _defaultPerKmRate,
      baseFare: _defaultBaseFare,
      perMinuteRate: _defaultPerMinuteRate,
    );
  }
}
