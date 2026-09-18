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
    this.mainText,
    this.secondaryText,
  });

  final String placeName;
  final double latitude;
  final double longitude;
  final String? mainText;
  final String? secondaryText;
}

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceKm;
  final double durationSeconds;
}


class LocationSearchService {
  static final http.Client _client = http.Client();
  static final Map<String, List<LocationSearchResult>> _searchCache = {};
  static final Map<String, LocationSearchResult?> _reverseCache = {};
  static final Map<String, Completer<List<LocationSearchResult>>> _inflight = {};

  static Future<Map<String, String>> _headers() async {
    return {
      'User-Agent': 'KenickChauffeur/1.0 (passenger-app)',
      'Accept': 'application/json',
    };
  }

  /// Searches places starting from 1 character query with instant cache lookup.
  static Future<List<LocationSearchResult>> search(String query, {String? countryCode}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final key = '${trimmed.toLowerCase()}_${countryCode ?? ''}';

    // 1. Direct cache match
    final cached = _searchCache[key];
    if (cached != null) return cached;

    // 2. Inflight deduplication
    final inflight = _inflight[key];
    if (inflight != null) return inflight.future;

    // 3. Instant prefix match while fresh query is inflight
    final prefixResults = _filterFromPrefixCache(trimmed.toLowerCase(), countryCode);

    if (prefixResults.isNotEmpty) {
      // Return prefix results immediately for zero UI latency, fetch fresh in background
      _fetchAndCache(trimmed, countryCode);
      return prefixResults;
    }

    return await _fetchAndCache(trimmed, countryCode);
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
      final matchName = r.placeName.toLowerCase().contains(query);
      final matchMain = r.mainText?.toLowerCase().contains(query) ?? false;
      return matchName || matchMain;
    }).toList();
  }

  static Future<List<LocationSearchResult>> _fetchAndCache(String query, String? countryCode) async {
    final key = '${query.toLowerCase()}_${countryCode ?? ''}';

    if (_searchCache.containsKey(key)) return _searchCache[key]!;

    final existing = _inflight[key];
    if (existing != null) return existing.future;

    final completer = Completer<List<LocationSearchResult>>();
    _inflight[key] = completer;

    try {
      final token = EnvConfig.mapboxAccessToken;

      // ── PRIMARY PROVIDER: Mapbox Places Geocoding API (Ultra-Fast 20-50ms worldwide) ──
      if (token.isNotEmpty && token.startsWith('pk.')) {
        try {
          final countryParam = countryCode != null && countryCode.isNotEmpty
              ? '&country=${Uri.encodeComponent(countryCode.toLowerCase())}'
              : '';

          final mapboxUrl = Uri.parse(
            'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
            '?access_token=$token'
            '&autocomplete=true'
            '&types=address,poi,place,neighborhood'
            '&limit=8$countryParam',
          );

          final response = await _client.get(mapboxUrl, headers: await _headers()).timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final features = data['features'] as List? ?? [];

            if (features.isNotEmpty) {
              final results = features.map<LocationSearchResult>((f) {
                final center = f['center'] as List? ?? [0.0, 0.0];
                final lng = (center[0] as num).toDouble();
                final lat = (center[1] as num).toDouble();
                final placeName = f['place_name'] as String? ?? '';
                final text = f['text'] as String? ?? '';
                final contextList = f['context'] as List? ?? [];
                final secondary = contextList.map((c) => c['text'] ?? '').where((s) => s.toString().isNotEmpty).join(', ');

                return LocationSearchResult(
                  placeName: placeName,
                  latitude: lat,
                  longitude: lng,
                  mainText: text.isNotEmpty ? text : placeName.split(',').first.trim(),
                  secondaryText: secondary.isNotEmpty
                      ? secondary
                      : (placeName.contains(',') ? placeName.substring(placeName.indexOf(',') + 1).trim() : null),
                );
              }).toList();

              _searchCache[key] = results;
              completer.complete(results);
              return results;
            }
          }
        } catch (_) {
          // Fall through to Nominatim fallback
        }
      }

      // ── SECONDARY FALLBACK: OpenStreetMap Nominatim ──
      final codes = countryCode != null && countryCode.isNotEmpty
          ? countryCode.toLowerCase()
          : '';
      final countryFilter = codes.isNotEmpty ? '&countrycodes=$codes' : '';

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=8$countryFilter',
      );

      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        completer.complete([]);
        return [];
      }

      final data = jsonDecode(response.body) as List? ?? [];
      final results = data.map<LocationSearchResult>((f) {
        final displayName = f['display_name'] as String? ?? '';
        final parts = displayName.split(',').map((s) => s.trim()).toList();
        final main = parts.isNotEmpty ? parts.first : displayName;
        final secondary = parts.length > 1 ? parts.sublist(1, parts.length > 4 ? 4 : parts.length).join(', ') : null;

        return LocationSearchResult(
          placeName: displayName,
          latitude: double.parse(f['lat'] as String),
          longitude: double.parse(f['lon'] as String),
          mainText: main,
          secondaryText: secondary,
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
      final response = await http.get(url).timeout(const Duration(seconds: 3));
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
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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
    final key = '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    final cached = _reverseCache[key];
    if (cached != null) return cached;

    // ── Primary Reverse Geocode: Mapbox ──
    final token = EnvConfig.mapboxAccessToken;
    if (token.isNotEmpty && token.startsWith('pk.')) {
      try {
        final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${point.longitude},${point.latitude}.json'
          '?access_token=$token'
          '&types=address,poi,place'
          '&limit=1',
        );

        final response = await _client.get(url, headers: await _headers()).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final features = data['features'] as List? ?? [];
          if (features.isNotEmpty) {
            final f = features.first;
            final placeName = f['place_name'] as String? ?? '';
            final text = f['text'] as String? ?? '';

            final result = LocationSearchResult(
              placeName: placeName,
              latitude: point.latitude,
              longitude: point.longitude,
              mainText: text.isNotEmpty ? text : placeName.split(',').first.trim(),
            );
            _reverseCache[key] = result;
            return result;
          }
        }
      } catch (_) {
        // Fall through to Nominatim
      }
    }

    // ── Fallback Reverse Geocode: Nominatim ──
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=${point.latitude}'
      '&lon=${point.longitude}'
      '&format=json'
      '&addressdetails=1',
    );

    try {
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map?;
      if (data == null || data['error'] != null) return null;

      final result = LocationSearchResult(
        placeName: data['display_name'] ?? '',
        latitude: point.latitude,
        longitude: point.longitude,
      );

      _reverseCache[key] = result;
      return result;
    } catch (_) {
      return null;
    }
  }
}

