import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kenick_vip/config/env_config.dart';
import 'package:latlong2/latlong.dart';

class LocationSearchResult {

  LocationSearchResult({
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });
  final String placeName;
  final double latitude;
  final double longitude;
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
  });
}

class LocationSearchService {
  static final http.Client _client = http.Client();
  static DateTime _lastRequest = DateTime(2000);
  static final Map<String, List<LocationSearchResult>> _searchCache = {};
  static final Map<String, LocationSearchResult?> _reverseCache = {};
  static final Map<String, Completer<List<LocationSearchResult>>> _inflight = {};

  static Future<void> _throttle() async {
    final now = DateTime.now();
    final diff = now.difference(_lastRequest).inMilliseconds;
    if (diff < 300) {
      await Future.delayed(Duration(milliseconds: 300 - diff));
    }
    _lastRequest = DateTime.now();
  }

  static Future<Map<String, String>> _headers() async {
    return {
      'User-Agent': 'KluxVip/1.0 (passenger-app)',
      'Accept': 'application/json',
    };
  }

  static Future<List<LocationSearchResult>> search(String query, {String? countryCode}) async {
    if (query.trim().isEmpty) return [];

    final key = '${query.trim().toLowerCase()}_${countryCode ?? ''}';

    final cached = _searchCache[key];
    if (cached != null) return cached;

    final inflight = _inflight[key];
    if (inflight != null) return inflight.future;

    final prefixResults = _filterFromPrefixCache(query.trim().toLowerCase(), countryCode);

    if (prefixResults.isNotEmpty) {
      _fetchAndCacheAsync(query.trim(), countryCode);
      return prefixResults;
    }

    return await _fetchAndCache(query.trim(), countryCode);
  }

  static List<LocationSearchResult> _filterFromPrefixCache(String query, String? countryCode) {
    final suffix = '_${countryCode ?? ''}';
    String? longestPrefixKey;
    int longestPrefixLength = 0;

    for (final cachedKey in _searchCache.keys) {
      if (!cachedKey.endsWith(suffix)) continue;
      final cachedQuery = cachedKey.substring(0, cachedKey.length - suffix.length);
      if (query.startsWith(cachedQuery) && cachedQuery.length > longestPrefixLength) {
        longestPrefixKey = cachedKey;
        longestPrefixLength = cachedQuery.length;
      }
    }

    if (longestPrefixKey == null) return [];

    final parentResults = _searchCache[longestPrefixKey]!;
    return parentResults.where((r) {
      return r.placeName.toLowerCase().contains(query);
    }).toList();
  }

  static void _fetchAndCacheAsync(String query, String? countryCode) {
    _fetchAndCache(query, countryCode);
  }

  static Future<List<LocationSearchResult>> _fetchAndCache(String query, String? countryCode) async {
    final key = '${query.trim().toLowerCase()}_${countryCode ?? ''}';

    if (_searchCache.containsKey(key)) return _searchCache[key]!;

    final existing = _inflight[key];
    if (existing != null) return existing.future;

    final completer = Completer<List<LocationSearchResult>>();
    _inflight[key] = completer;

    try {
      await _throttle();

      final codes = countryCode != null && countryCode.isNotEmpty
          ? countryCode.toLowerCase()
          : 'ng,us,gb,ca,au,br';

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=20'
        '&countrycodes=$codes',
      );

      final response = await _client.get(uri, headers: await _headers());
      if (response.statusCode != 200) {
        completer.complete([]);
        return [];
      }

      final data = jsonDecode(response.body) as List? ?? [];
      final results = data.map((f) {
        return LocationSearchResult(
          placeName: f['display_name'] ?? '',
          latitude: double.parse(f['lat'] as String),
          longitude: double.parse(f['lon'] as String),
        );
      }).toList();

      _searchCache[key] = results;
      completer.complete(results);
      return results;
    } catch (_) {
      completer.complete([]);
      return [];
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<String?> detectCountryCodeByIP() async {
    try {
      final url = Uri.parse('http://ip-api.com/json');
      final response = await http.get(url);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map?;
      if (data == null || data['status'] != 'success') return null;
      return data['countryCode'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> detectCountryCode(LatLng point) async {
    final code = await detectCountryCodeByIP();
    if (code != null) return code;

    final result = await reverseGeocode(point);
    if (result == null) return null;

    final parts = result.placeName.split(', ');
    return parts.isNotEmpty ? parts.last : null;
  }

  static Future<RouteResult?> getRoute(LatLng from, LatLng to) async {
    final token = EnvConfig.mapboxAccessToken;
    if (token.isEmpty) return null;

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?geometries=geojson'
      '&overview=full'
      '&access_token=$token',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final routes = data['routes'] as List? ?? [];
      if (routes.isEmpty) return null;

      final route = routes[0];
      final geometry = route['geometry'] as Map?;
      if (geometry == null) return null;

      final coords = geometry['coordinates'] as List? ?? [];
      final points = coords.map((c) {
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();

      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

      return RouteResult(
        points: points,
        distanceKm: distanceMeters / 1000.0,
        durationSeconds: durationSeconds,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<LocationSearchResult?> reverseGeocode(LatLng point) async {
    final key = '${point.latitude},${point.longitude}';
    final cached = _reverseCache[key];
    if (cached != null) return cached;

    await _throttle();

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=${point.latitude}'
      '&lon=${point.longitude}'
      '&format=json'
      '&addressdetails=1',
    );

    try {
      final response = await _client.get(uri, headers: await _headers());
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map?;
      if (data == null || data['error'] != null) return null;

      final result = LocationSearchResult(
        placeName: data['display_name'] ?? '',
        latitude: double.parse(data['lat'] as String),
        longitude: double.parse(data['lon'] as String),
      );

      _reverseCache[key] = result;
      return result;
    } catch (_) {
      return null;
    }
  }
}
