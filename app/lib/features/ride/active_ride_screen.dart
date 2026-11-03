import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/active_trip_chat_sheet.dart';
import 'package:kenick_vip/widgets/cards/active_trip_card.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/vip_google_map.dart';
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
  final GlobalKey<VipGoogleMapState> _mapKey = GlobalKey<VipGoogleMapState>();
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
    MapMemory().save(_currentPosition, 14.5);
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
      _fetchAndDrawRoute();
    }

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _fetchAndDrawRoute();
      }
    });
  }

  Future<void> _fetchAndDrawRoute() async {
    final rideProv = context.read<RideProvider>();
    final ride = rideProv.currentRideDetails;
    if (ride == null) return;

    final dropoffStr = ride['dropoff_location']?.toString() ?? '';
    final regExp = RegExp(r'POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)');
    final match = regExp.firstMatch(dropoffStr);
    if (match == null) return;

    final dropoffLng = double.tryParse(match.group(1) ?? '');
    final dropoffLat = double.tryParse(match.group(2) ?? '');
    if (dropoffLat == null || dropoffLng == null) return;

    final dropoff = LatLng(dropoffLat, dropoffLng);
    final routeResult = await LocationSearchService.getRoute(_currentPosition, dropoff);
    if (routeResult != null && mounted) {
      setState(() => _routePoints = routeResult.points);
    }
  }

  Future<bool> _confirmExit() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Active Ride in Progress',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF18181B),
          ),
        ),
        content: Text(
          'A luxury journey is currently active. Are you sure you want to return to the home screen? The ride will continue running.',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Stay on Map',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Return Home',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
            VipGoogleMap(
              key: _mapKey,
              initialCenter: _currentPosition,
              initialZoom: 14.5,
              driverPosition: _currentPosition,
              dropoffPosition: dropoffPos,
              routePoints: _routePoints.isNotEmpty ? _routePoints : (dropoffPos != null ? [_currentPosition, dropoffPos] : null),
              padding: const EdgeInsets.only(bottom: 240, top: 60),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 18, top: 10),
                child: GestureDetector(
                  onTap: () async {
                    final shouldExit = await _confirmExit();
                    if (shouldExit && context.mounted) {
                      context.pop();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E2026) : Colors.white,
                      border: Border.all(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFD4D4D8),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Text(
                'Contact Passenger',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reach out to $_passengerName regarding this assignment',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_rounded, color: Color(0xFF22C55E), size: 20),
                ),
                title: Text(
                  'Voice Call Client',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                  ),
                ),
                subtitle: Text(
                  'Secured masked call via Kenick VIP',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                  ),
                ),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  'Direct In-App Message',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                  ),
                ),
                subtitle: Text(
                  'Send an update or ETA notification',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ActiveTripChatSheet.show(context, _passengerName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
