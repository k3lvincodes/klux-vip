import 'package:latlong2/latlong.dart';

class MapMemory {
  static final MapMemory _instance = MapMemory._();
  factory MapMemory() => _instance;
  MapMemory._();

  LatLng? lastPosition;
  double lastZoom = 14.5;
  bool hasMemory = false;

  void save(LatLng position, double zoom) {
    lastPosition = position;
    lastZoom = zoom;
    hasMemory = true;
  }

  void clear() {
    lastPosition = null;
    lastZoom = 14.5;
    hasMemory = false;
  }
}
