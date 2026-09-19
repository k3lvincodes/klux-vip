import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/config/env_config.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/widgets/cards/active_trip_card.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late Stopwatch _rideTimer;
  late Timer _displayTimer;
  String _elapsedDisplay = '00:00';
  String _passengerName = 'VIP Client';
  String? _passengerAvatarUrl;

  @override
  void initState() {
    super.initState();
    _rideTimer = Stopwatch()..start();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final elapsed = _rideTimer.elapsed;
        setState(() {
          _elapsedDisplay = '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null) ? mem.lastPosition! : _initialPosition;
    _startGps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentPosition, mem.lastZoom);
      _fetchPassengerDetails();
    });
  }

  Future<void> _fetchPassengerDetails() async {
    final rideProv = context.read<RideProvider>();
    final ride = rideProv.currentRideDetails;
    final passengerId = ride?['passenger_id'] as String?;
    if (passengerId == null || passengerId.isEmpty) return;

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, avatar_url')
          .eq('id', passengerId)
          .maybeSingle();

      if (res != null && mounted) {
        final name = '${res['first_name'] ?? ''} ${res['last_name'] ?? ''}'.trim();
        setState(() {
          if (name.isNotEmpty) _passengerName = name;
          _passengerAvatarUrl = res['avatar_url'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _rideTimer.stop();
    _displayTimer.cancel();
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
    final routeResult = await LocationSearchService.getRoute(_currentPosition, dropoff);
    if (routeResult != null && mounted) {
      setState(() => _routePoints = routeResult.points);
    }
  }

  Future<bool> _confirmExit() async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Navigation?'),
        content: const Text(
          'This luxury itinerary is currently in progress. You can safely return to the home screen without ending the ride.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Stay on Map', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Return Home'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
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
                        color: cs.primary,
                        strokeWidth: 4.0,
                        borderColor: cs.primary.withValues(alpha: 0.3),
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: GestureDetector(
                  onTap: () async {
                    final shouldExit = await _confirmExit();
                    if (shouldExit && context.mounted) {
                      context.pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.arrow_back, size: 20, color: cs.onSurface),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ActiveTripCard(
                passengerName: _passengerName,
                passengerAvatarUrl: _passengerAvatarUrl,
                pickupAddress: rideProv.currentRideDetails?['pickup_address'] ?? 'Pickup location',
                dropoffAddress: rideProv.currentRideDetails?['dropoff_address'] ?? 'Dropoff location',
                fare: rideProv.currentRideDetails?['fare_amount']?.toString() ?? '0.00',
                status: 'in_progress',
                timeElapsed: _elapsedDisplay,
                onEndRide: () => context.push('/end-ride-confirmation'),
                onContact: () => _showContactOptions(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Contact Passenger',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Reach out to $_passengerName regarding this assignment',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_rounded, color: Color(0xFF22C55E)),
              ),
              title: const Text('Voice Call Client', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Secured masked call via Kenick VIP', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting secured call to client...')),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chat_bubble_outline_rounded, color: cs.primary),
              ),
              title: const Text('Direct In-App Message', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Send an update or ETA notification', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening secure messenger...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
