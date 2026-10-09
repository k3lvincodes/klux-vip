import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:latlong2/latlong.dart' as ll;

/// Ultra-Luxury VIP Google Map Widget with custom Dark/Light JSON styling
class VipGoogleMap extends StatefulWidget {
  const VipGoogleMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.pickupPosition,
    this.dropoffPosition,
    this.driverPosition,
    this.routePoints,
    this.isStationary = false,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.padding = EdgeInsets.zero,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
  });

  final ll.LatLng initialCenter;
  final double initialZoom;
  final ll.LatLng? pickupPosition;
  final ll.LatLng? dropoffPosition;
  final ll.LatLng? driverPosition;
  final List<ll.LatLng>? routePoints;
  final bool isStationary;
  final ValueChanged<gmaps.GoogleMapController>? onMapCreated;
  final ValueChanged<ll.LatLng>? onCameraMove;
  final VoidCallback? onCameraIdle;
  final EdgeInsets padding;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;

  @override
  State<VipGoogleMap> createState() => VipGoogleMapState();
}

class VipGoogleMapState extends State<VipGoogleMap> {
  gmaps.GoogleMapController? _controller;

  // Ultra-Luxury Obsidian Dark Map Style
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#121214"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a93"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#121214"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#333338"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#b0b0b8"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#1a1a1f"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6e6e76"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#131a15"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#202026"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#7a7a85"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{"color": "#282832"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#353542"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f1f24"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#1b1b22"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#09090c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#4a4a55"}]
  }
]
''';

  // Minimalist Luxury Light Map Style
  static const String _lightMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f8f8fa"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f8f8fa"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#bdbdbd"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#e5f2e8"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#eaeaea"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#e0e0e0"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#d8e5ed"}]
  }
]
''';

  @override
  void didUpdateWidget(covariant VipGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pickupPosition != oldWidget.pickupPosition ||
        widget.dropoffPosition != oldWidget.dropoffPosition ||
        widget.routePoints != oldWidget.routePoints) {
      fitRouteBounds();
    }
  }

  void fitRouteBounds() {
    if (_controller == null) return;
    final points = <ll.LatLng>[];
    if (widget.pickupPosition != null) points.add(widget.pickupPosition!);
    if (widget.dropoffPosition != null) points.add(widget.dropoffPosition!);
    if (widget.driverPosition != null) points.add(widget.driverPosition!);
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      points.addAll(widget.routePoints!);
    }

    if (points.length >= 2) {
      double south = points.first.latitude;
      double north = points.first.latitude;
      double west = points.first.longitude;
      double east = points.first.longitude;

      for (final pt in points) {
        if (pt.latitude < south) south = pt.latitude;
        if (pt.latitude > north) north = pt.latitude;
        if (pt.longitude < west) west = pt.longitude;
        if (pt.longitude > east) east = pt.longitude;
      }

      _controller?.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            southwest: gmaps.LatLng(south, west),
            northeast: gmaps.LatLng(north, east),
          ),
          80.0,
        ),
      );
    } else if (points.length == 1) {
      animateTo(points.first);
    }
  }

  void animateTo(ll.LatLng position, [double zoom = 15.5]) {
    _controller?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(position.latitude, position.longitude),
        zoom,
      ),
    );
  }

  Set<gmaps.Marker> _buildMarkers() {
    final markers = <gmaps.Marker>{};

    if (widget.pickupPosition != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: gmaps.LatLng(widget.pickupPosition!.latitude, widget.pickupPosition!.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange),
          infoWindow: const gmaps.InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (widget.dropoffPosition != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('dropoff'),
          position: gmaps.LatLng(widget.dropoffPosition!.latitude, widget.dropoffPosition!.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
          infoWindow: const gmaps.InfoWindow(title: 'Destination'),
        ),
      );
    }

    if (widget.driverPosition != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('driver'),
          position: gmaps.LatLng(widget.driverPosition!.latitude, widget.driverPosition!.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueYellow),
          infoWindow: const gmaps.InfoWindow(title: 'VIP Chauffeur'),
        ),
      );
    }

    return markers;
  }

  Set<gmaps.Polyline> _buildPolylines() {
    final polylines = <gmaps.Polyline>{};

    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      final googleCoords = widget.routePoints!
          .map((pt) => gmaps.LatLng(pt.latitude, pt.longitude))
          .toList();

      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('vip_route'),
          points: googleCoords,
          color: AppColors.primary,
          width: 5,
          startCap: gmaps.Cap.roundCap,
          endCap: gmaps.Cap.roundCap,
          jointType: gmaps.JointType.round,
        ),
      );
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
        zoom: widget.initialZoom,
      ),
      style: isDark ? _darkMapStyle : null,
      onMapCreated: (ctrl) {
        _controller = ctrl;
        widget.onMapCreated?.call(ctrl);
        if (widget.pickupPosition != null && widget.dropoffPosition != null) {
          fitRouteBounds();
        }
      },
      onCameraMove: (pos) {
        widget.onCameraMove?.call(ll.LatLng(pos.target.latitude, pos.target.longitude));
      },
      onCameraIdle: widget.onCameraIdle,
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      padding: widget.padding,
    );
  }
}
