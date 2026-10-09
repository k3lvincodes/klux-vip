import 'package:kenick_vip/services/currency_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FareRate {
  FareRate({
    required this.id,
    required this.countryCode,
    this.stateOrRegion,
    required this.perKmRate,
    required this.baseFare,
    required this.perMinuteRate,
    required this.currencyCode,
    required this.currencySymbol,
  });

  factory FareRate.fromMap(Map<String, dynamic> map) {
    final country = (map['country_code'] as String?)?.toUpperCase() ?? 'US';
    final currency = CurrencyService.getCurrency(country);

    double base = (map['base_fare'] as num).toDouble();
    double perKm = (map['per_km_rate'] as num).toDouble();
    double perMin = (map['per_minute_rate'] as num).toDouble();

    // If database has placeholder USD-scale values for Nigeria (e.g. 1.20, 2.00)
    // sanitize to proper NGN rates
    if (country == 'NG' && base < 50) {
      base = 500.0;
      perKm = 250.0;
      perMin = 80.0;
    }

    return FareRate(
      id: map['id'] as String,
      countryCode: country,
      stateOrRegion: map['state_or_region'] as String?,
      perKmRate: perKm,
      baseFare: base,
      perMinuteRate: perMin,
      currencyCode: currency.code,
      currencySymbol: currency.symbol,
    );
  }

  final String id;
  final String countryCode;
  final String? stateOrRegion;
  final double perKmRate;
  final double baseFare;
  final double perMinuteRate;
  final String currencyCode;
  final String currencySymbol;
}

class FareRateService {
  static final _supabase = Supabase.instance.client;

  static final Map<String, _CachedRate> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  static const Map<String, Map<String, double>> _countryDefaults = {
    'NG': {'baseFare': 500.0, 'perKmRate': 250.0, 'perMinuteRate': 80.0},
    'US': {'baseFare': 3.50, 'perKmRate': 1.85, 'perMinuteRate': 0.45},
    'GB': {'baseFare': 2.80, 'perKmRate': 1.45, 'perMinuteRate': 0.35},
    'CA': {'baseFare': 4.50, 'perKmRate': 2.45, 'perMinuteRate': 0.60},
    'AU': {'baseFare': 5.00, 'perKmRate': 2.75, 'perMinuteRate': 0.65},
    'DE': {'baseFare': 3.20, 'perKmRate': 1.70, 'perMinuteRate': 0.42},
    'FR': {'baseFare': 3.20, 'perKmRate': 1.70, 'perMinuteRate': 0.42},
  };

  static Future<FareRate> getRate(String countryCode) async {
    final upperCountry = countryCode.toUpperCase();
    final cached = _cache[upperCountry];
    if (cached != null && !cached.isExpired) {
      return cached.rate;
    }

    try {
      final data = await _supabase
          .from('fare_rates')
          .select()
          .eq('country_code', upperCountry)
          .isFilter('state_or_region', null)
          .maybeSingle();

      if (data != null) {
        final rate = FareRate.fromMap(data);
        _cache[upperCountry] = _CachedRate(rate);
        return rate;
      }
    } catch (_) {}

    final defaults = _countryDefaults[upperCountry] ?? _countryDefaults['US']!;
    final currency = CurrencyService.getCurrency(upperCountry);

    final fallback = FareRate(
      id: 'default',
      countryCode: upperCountry,
      perKmRate: defaults['perKmRate']!,
      baseFare: defaults['baseFare']!,
      perMinuteRate: defaults['perMinuteRate']!,
      currencyCode: currency.code,
      currencySymbol: currency.symbol,
    );
    _cache[upperCountry] = _CachedRate(fallback);
    return fallback;
  }
}

class _CachedRate {
  _CachedRate(this.rate) : cachedAt = DateTime.now();
  final FareRate rate;
  final DateTime cachedAt;
  bool get isExpired => DateTime.now().difference(cachedAt) > FareRateService._cacheTtl;
}
