import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

class LocationSearchResult {
  final String placeName;
  final double latitude;
  final double longitude;

  LocationSearchResult({
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationSearchService {
  static final http.Client _client = http.Client();
  static DateTime _lastRequest = DateTime(2000);
  static final Map<String, List<LocationSearchResult>> _searchCache = {};
  static final Map<String, LocationSearchResult?> _reverseCache = {};

  static Future<void> _throttle() async {
    final now = DateTime.now();
    final diff = now.difference(_lastRequest).inMilliseconds;
    if (diff < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - diff));
    }
    _lastRequest = DateTime.now();
  }

  static Future<Map<String, String>> _headers() async {
    return {
      'User-Agent': 'KluxVip/1.0 (passenger-app)',
      'Accept': 'application/json',
    };
  }

  static Future<List<LocationSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final key = query.trim().toLowerCase();
    final cached = _searchCache[key];
    if (cached != null) return cached;

    await _throttle();

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=20'
      '&countrycodes=ng,us,gb,ca,au,br',
    );

    try {
      final response = await _client.get(uri, headers: await _headers());
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List? ?? [];
      final results = data.map((f) {
        return LocationSearchResult(
          placeName: f['display_name'] ?? '',
          latitude: double.parse(f['lat'] as String),
          longitude: double.parse(f['lon'] as String),
        );
      }).toList();

      _searchCache[key] = results;
      return results;
    } catch (_) {
      return [];
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

  static Future<List<LatLng>?> getRoute(LatLng from, LatLng to) async {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
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

      final geometry = routes[0]['geometry'] as Map?;
      if (geometry == null) return null;

      final coords = geometry['coordinates'] as List? ?? [];
      return coords.map((c) {
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();
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
