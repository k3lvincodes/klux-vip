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
  static String? _token;

  static String get _accessToken {
    _token ??= dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    return _token!;
  }

  static Future<List<LocationSearchResult>> search(String query) async {
    if (query.trim().length < 3) return [];

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
      '?access_token=$_accessToken'
      '&types=address,place,locality,neighborhood,poi'
      '&limit=5'
      '&country=US',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final features = data['features'] as List? ?? [];

      return features.map((f) {
        final coords = f['center'] as List;
        return LocationSearchResult(
          placeName: f['place_name'] ?? '',
          latitude: (coords[1] as num).toDouble(),
          longitude: (coords[0] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<LocationSearchResult?> reverseGeocode(LatLng point) async {
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/${point.longitude},${point.latitude}.json'
      '?access_token=$_accessToken'
      '&types=address,place,locality,neighborhood'
      '&limit=1',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final features = data['features'] as List? ?? [];
      if (features.isEmpty) return null;

      final f = features[0];
      final coords = f['center'] as List;
      return LocationSearchResult(
        placeName: f['place_name'] ?? '',
        latitude: (coords[1] as num).toDouble(),
        longitude: (coords[0] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
