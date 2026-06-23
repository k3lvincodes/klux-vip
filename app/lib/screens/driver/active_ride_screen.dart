import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/config/env_config.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/active_trip_card.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  static const LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);
  late LatLng _currentPosition;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _gpsSubscription;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null) ? mem.lastPosition! : _initialPosition;
    _startGps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentPosition, mem.lastZoom);
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    MapMemory().save(_currentPosition, _mapController.camera.zoom);
    super.dispose();
  }

  Future<void> _startGps() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
      _fetchRoute();
    }

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      if (mounted) {
        setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
      }
    });
  }

  Future<void> _fetchRoute() async {
    final rideProv = context.read<RideProvider>();
    final ride = rideProv.currentRideDetails;
    if (ride == null) return;

    final dropoffStr = ride['dropoff_location']?.toString() ?? '';
    final regExp = RegExp(r'POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)');
    final match = regExp.firstMatch(dropoffStr);
    if (match == null) return;

    final lng = double.tryParse(match.group(1) ?? '');
    final lat = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) return;

    final dropoff = LatLng(lat, lng);
    final route = await LocationSearchService.getRoute(_currentPosition, dropoff);
    if (route != null && mounted) {
      setState(() => _routePoints = route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideProv = context.watch<RideProvider>();
    final ride = rideProv.currentRideDetails;
    final dropoffStr = ride?['dropoff_location']?.toString() ?? '';
    final regExp = RegExp(r'POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)');
    final match = regExp.firstMatch(dropoffStr);
    LatLng? dropoffPos;
    if (match != null) {
      final lng = double.tryParse(match.group(1) ?? '');
      final lat = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) dropoffPos = LatLng(lat, lng);
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}'
                    : 'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                additionalOptions: {
                  'accessToken': EnvConfig.mapboxAccessToken,
                },
                userAgentPackageName: 'com.kenickvip.app',
                maxZoom: 22,
              ),
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primary,
                      strokeWidth: 4.0,
                      borderColor: AppColors.primary.withValues(alpha: 0.3),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  AnimatedMarker.driverCar(point: _currentPosition),
                  if (dropoffPos != null)
                    AnimatedMarker.dropoffPin(point: dropoffPos, label: 'Dropoff'),
                ],
              ),
            ],
          ),

          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, size: 18, color: isDark ? AppColors.white : AppColors.black),
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ActiveTripCard(
              passengerName: 'Client',
              pickupAddress: rideProv.currentRideDetails?['pickup_address'] ?? 'Pickup location',
              dropoffAddress: rideProv.currentRideDetails?['dropoff_address'] ?? 'Dropoff location',
              fare: rideProv.currentRideDetails?['fare_amount']?.toString() ?? '0.00',
              status: 'in_progress',
              timeElapsed: '12:30',
              onEndRide: () => context.push('/end-ride-confirmation'),
            ),
          ),
        ],
      ),
    );
  }
}
