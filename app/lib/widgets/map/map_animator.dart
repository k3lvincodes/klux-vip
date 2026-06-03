import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapAnimator {
  static void smoothMove(
    MapController controller,
    LatLng destination, {
    double? zoom,
    double duration = 600,
  }) {
    final startCenter = controller.camera.center;
    final startZoom = controller.camera.zoom;
    final targetZoom = zoom ?? startZoom;

    final startLat = startCenter.latitude;
    final startLng = startCenter.longitude;
    final latDelta = destination.latitude - startLat;
    final lngDelta = destination.longitude - startLng;
    final zoomDelta = targetZoom - startZoom;

    // Use a self-contained Ticker for ultra-smooth 60/120fps animation
    late final Ticker ticker;
    final startTime = DateTime.now();

    ticker = Ticker((elapsed) {
      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      double t = elapsedMs / duration;

      if (t >= 1.0) {
        t = 1.0;
        controller.move(destination, targetZoom);
        ticker.stop();
        ticker.dispose();
      } else {
        // Cubic ease-out curve: f(t) = 1 - (1 - t)^3
        final curveT = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
        final curLat = startLat + latDelta * curveT;
        final curLng = startLng + lngDelta * curveT;
        final curZoom = startZoom + zoomDelta * curveT;

        controller.move(LatLng(curLat, curLng), curZoom);
      }
    });

    ticker.start();
  }

  static void fitBounds(
    MapController controller,
    List<LatLng> points, {
    double padding = 60,
  }) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      smoothMove(controller, points.first, zoom: 15.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    controller.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(padding),
      ),
    );
  }
}

