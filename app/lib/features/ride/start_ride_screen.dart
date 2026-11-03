import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/vip_google_map.dart';
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
  final GlobalKey<VipGoogleMapState> _mapKey = GlobalKey<VipGoogleMapState>();

  int _waitSeconds = 0;
  Timer? _timer;
  StreamSubscription<Position>? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null) ? mem.lastPosition! : _initialPosition;
    _startGps();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _waitSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          VipGoogleMap(
            key: _mapKey,
            initialCenter: _currentPosition,
            initialZoom: 14.5,
            driverPosition: _currentPosition,
            dropoffPosition: dropoffPos,
            routePoints: dropoffPos != null ? [_currentPosition, dropoffPos] : null,
            padding: const EdgeInsets.only(bottom: 240, top: 60),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 18, top: 10),
              child: GestureDetector(
                onTap: () => context.pop(),
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
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141416) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFD4D4D8),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Waiting time',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF18181B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _formattedTime,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Client has been notified of your arrival',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<RideProvider>(
                      builder: (context, rideProv, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: rideProv.isLoading
                                ? null
                                : () async {
                                    final success = await rideProv.updateRideStatus('in_progress');
                                    if (success && context.mounted) context.push('/active-ride');
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: const Color(0xFF111827),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: rideProv.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFF111827),
                                    ),
                                  )
                                : Text(
                                    'Start the ride',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
