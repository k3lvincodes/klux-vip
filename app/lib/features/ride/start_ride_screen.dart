import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/config/env_config.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class StartRideScreen extends StatefulWidget {
  const StartRideScreen({super.key});

  @override
  State<StartRideScreen> createState() => _StartRideScreenState();
}

class _StartRideScreenState extends State<StartRideScreen> {
  static const LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);
  late LatLng _currentPosition;
  final MapController _mapController = MapController();

  int _waitSeconds = 0;
  Timer? _timer;
  StreamSubscription<Position>? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null) ? mem.lastPosition! : _initialPosition;
    _startGps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentPosition, mem.lastZoom);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _waitSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    if (mounted) setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      if (mounted) setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
    });
  }

  String get _formattedTime {
    final minutes = (_waitSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_waitSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
              if (dropoffPos != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_currentPosition, dropoffPos],
                      color: cs.primary,
                      strokeWidth: 4.0,
                      borderColor: cs.primary.withValues(alpha: 0.3),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  AnimatedMarker.locationDot(point: _currentPosition, color: cs.primary),
                  if (dropoffPos != null) AnimatedMarker.dropoffPin(point: dropoffPos, label: 'Dropoff'),
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
                  color: cs.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, size: 18, color: cs.onSurface),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Waiting time', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Text(_formattedTime, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  Text('You may cancel the offer', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  Consumer<RideProvider>(
                    builder: (context, rideProv, _) {
                      return CustomButton(
                        title: rideProv.isLoading ? 'Starting...' : 'Start the ride',
                        onPress: rideProv.isLoading ? () {} : () async {
                          final success = await rideProv.updateRideStatus('in_progress');
                          if (success && context.mounted) context.push('/active-ride');
                        },
                        variant: ButtonVariant.primary,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
