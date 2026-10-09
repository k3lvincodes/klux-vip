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
    this.placeId,
  });

  final String placeName;
  final double latitude;
  final double longitude;
  final String? mainText;
  final String? secondaryText;
  final String? placeId;

  bool get hasCoordinates => latitude != 0.0 || longitude != 0.0;
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
  static String? _currentSessionToken;

  static String getOrCreateSessionToken() {
    _currentSessionToken ??=
        '${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
    return _currentSessionToken!;
  }

  static void resetSessionToken() {
    _currentSessionToken = null;
  }

  /// Decodes Google Directions encoded polyline into `List<LatLng>`
  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

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
      final googleKey = EnvConfig.googleMapsApiKey;

      // ── PRIMARY PROVIDER: Google Places Autocomplete API ──
      if (googleKey.isNotEmpty) {
        try {
          final queryEsc = Uri.encodeComponent(query);
          final countryFilter = countryCode != null && countryCode.isNotEmpty
              ? '&components=country:${countryCode.toLowerCase()}'
              : '';
          final session = getOrCreateSessionToken();
          final googleUrl = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=$queryEsc'
            '&key=$googleKey'
            '$countryFilter'
            '&sessiontoken=$session',
          );

          final response = await _client.get(googleUrl, headers: await _headers()).timeout(const Duration(seconds: 4));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final status = data['status'] as String? ?? '';
            final predictions = data['predictions'] as List? ?? [];

            if ((status == 'OK' || status == 'ZERO_RESULTS') && predictions.isNotEmpty) {
              final results = predictions.map<LocationSearchResult>((p) {
                final desc = p['description'] as String? ?? '';
                final formatting = p['structured_formatting'] as Map? ?? {};
                final main = formatting['main_text'] as String? ?? desc.split(',').first.trim();
                final secondary = formatting['secondary_text'] as String?;
                final placeId = p['place_id'] as String?;

                return LocationSearchResult(
                  placeName: desc,
                  latitude: 0.0,
                  longitude: 0.0,
                  mainText: main,
                  secondaryText: secondary,
                  placeId: placeId,
                );
              }).toList();

              _searchCache[key] = results;
              completer.complete(results);
              return results;
            }
          }
        } catch (_) {
          // Fall through to Mapbox
        }
      }

      final token = EnvConfig.mapboxAccessToken;

      // ── SECONDARY PROVIDER: Mapbox Places Geocoding API ──
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

  static Future<LocationSearchResult> resolvePlace(LocationSearchResult item) async {
    if (item.hasCoordinates || item.placeId == null || item.placeId!.isEmpty) {
      return item;
    }

    final googleKey = EnvConfig.googleMapsApiKey;
    if (googleKey.isEmpty) return item;

    try {
      final session = _currentSessionToken;
      final sessionParam = session != null ? '&sessiontoken=$session' : '';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${item.placeId}'
        '&fields=geometry,name,formatted_address'
        '&key=$googleKey'
        '$sessionParam',
      );

      resetSessionToken();

      final response = await _client.get(url, headers: await _headers()).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'] as Map?;
        if (result != null) {
          final geom = result['geometry'] as Map?;
          final loc = geom?['location'] as Map?;
          if (loc != null) {
            final lat = (loc['lat'] as num).toDouble();
            final lng = (loc['lng'] as num).toDouble();
            final formatted = result['formatted_address'] as String? ?? item.placeName;
            return LocationSearchResult(
              placeName: formatted,
              latitude: lat,
              longitude: lng,
              mainText: item.mainText ?? result['name'] as String?,
              secondaryText: item.secondaryText,
              placeId: item.placeId,
            );
          }
        }
      }
    } catch (_) {}

    return item;
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
    final googleKey = EnvConfig.googleMapsApiKey;

    // ── PRIMARY PROVIDER: Google Directions API ──
    if (googleKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${from.latitude},${from.longitude}'
          '&destination=${to.latitude},${to.longitude}'
          '&mode=driving'
          '&key=$googleKey',
        );

        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final routes = data['routes'] as List? ?? [];
          if (routes.isNotEmpty) {
            final route = routes.first;
            final overviewPolyline = route['overview_polyline']?['points'] as String? ?? '';
            final legs = route['legs'] as List? ?? [];
            double totalDistanceMeters = 0;
            double totalDurationSeconds = 0;

            for (final leg in legs) {
              totalDistanceMeters += (leg['distance']?['value'] as num?)?.toDouble() ?? 0;
              totalDurationSeconds += (leg['duration']?['value'] as num?)?.toDouble() ?? 0;
            }

            final points = decodePolyline(overviewPolyline);
            if (points.isNotEmpty) {
              return RouteResult(
                points: points,
                distanceKm: totalDistanceMeters / 1000.0,
                durationSeconds: totalDurationSeconds,
              );
            }
          }
        }
      } catch (_) {
        // Fall through to Mapbox
      }
    }

    final token = EnvConfig.mapboxAccessToken;
    if (token.isNotEmpty && token.startsWith('pk.')) {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?geometries=geojson'
        '&overview=full'
        '&access_token=$token',
      );

      try {
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final routes = data['routes'] as List? ?? [];
          if (routes.isNotEmpty) {
            final route = routes[0];
            final geometry = route['geometry'] as Map?;
            if (geometry != null) {
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
            }
          }
        }
      } catch (_) {
        // Fall through
      }
    }

    return null;
  }

  static Future<LocationSearchResult?> reverseGeocode(LatLng point) async {
    final key = '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    final cached = _reverseCache[key];
    if (cached != null) return cached;

    final googleKey = EnvConfig.googleMapsApiKey;

    // ── PRIMARY PROVIDER: Google Geocoding API ──
    if (googleKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${point.latitude},${point.longitude}'
          '&key=$googleKey',
        );

        final response = await _client.get(url, headers: await _headers()).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] as List? ?? [];
          if (results.isNotEmpty) {
            final first = results.first;
            final formatted = first['formatted_address'] as String? ?? '';
            final parts = formatted.split(',');
            final main = parts.isNotEmpty ? parts.first.trim() : formatted;
            final secondary = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;

            final result = LocationSearchResult(
              placeName: formatted,
              latitude: point.latitude,
              longitude: point.longitude,
              mainText: main,
              secondaryText: secondary,
            );
            _reverseCache[key] = result;
            return result;
          }
        }
      } catch (_) {
        // Fall through to Mapbox
      }
    }

    // ── SECONDARY PROVIDER: Mapbox ──
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

    // ── FALLBACK PROVIDER: Nominatim ──
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

