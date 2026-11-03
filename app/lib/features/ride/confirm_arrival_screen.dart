import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/vip_google_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ConfirmArrivalScreen extends StatefulWidget {
  const ConfirmArrivalScreen({super.key});

  @override
  State<ConfirmArrivalScreen> createState() => _ConfirmArrivalScreenState();
}

class _ConfirmArrivalScreenState extends State<ConfirmArrivalScreen> {
  static const LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);
  late LatLng _currentPosition;
  final GlobalKey<VipGoogleMapState> _mapKey = GlobalKey<VipGoogleMapState>();
  StreamSubscription<Position>? _gpsSubscription;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null) ? mem.lastPosition! : _initialPosition;
    _startGps();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    MapMemory().save(_currentPosition, 15.5);
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

    final pickupStr = ride['pickup_location']?.toString() ?? '';
    final regExp = RegExp(r'POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)');
    final match = regExp.firstMatch(pickupStr);
    if (match == null) return;

    final pickupLng = double.tryParse(match.group(1) ?? '');
    final pickupLat = double.tryParse(match.group(2) ?? '');
    if (pickupLat == null || pickupLng == null) return;

    final pickup = LatLng(pickupLat, pickupLng);
    final routeResult = await LocationSearchService.getRoute(_currentPosition, pickup);
    if (routeResult != null && mounted) {
      setState(() => _routePoints = routeResult.points);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rideProv = context.watch<RideProvider>();
    final ride = rideProv.currentRideDetails;
    final pickupStr = ride?['pickup_location']?.toString() ?? '';
    final regExp = RegExp(r'POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)');
    final match = regExp.firstMatch(pickupStr);
    LatLng? pickupPosition;
    if (match != null) {
      final lng = double.tryParse(match.group(1) ?? '');
      final lat = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) pickupPosition = LatLng(lat, lng);
    }
    pickupPosition ??= LatLng(_currentPosition.latitude + 0.002, _currentPosition.longitude + 0.001);

    return Scaffold(
      body: Stack(
        children: [
          VipGoogleMap(
            key: _mapKey,
            initialCenter: _currentPosition,
            initialZoom: 15.5,
            pickupPosition: pickupPosition,
            driverPosition: _currentPosition,
            routePoints: _routePoints,
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
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Confirmation of Arrival',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF18181B),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 17),
                      child: Text(
                        'Executive assignment in progress',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Consumer<RideProvider>(
                      builder: (context, rideProv, _) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF121316) : const Color(0xFFF9F8F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.my_location_rounded,
                                AppColors.primary,
                                rideProv.currentRideDetails?['pickup_address'] ?? 'Pickup location',
                                isDark,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 7),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 2,
                                    height: 14,
                                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                  ),
                                ),
                              ),
                              _buildInfoRow(
                                Icons.location_on_rounded,
                                const Color(0xFFEF4444),
                                rideProv.currentRideDetails?['dropoff_address'] ?? 'Dropoff location',
                                isDark,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Consumer<RideProvider>(
                      builder: (context, rideProv, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: rideProv.isLoading
                                ? null
                                : () async {
                                    final success = await rideProv.updateRideStatus('arriving');
                                    if (success && context.mounted) context.push('/start-ride');
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
                                    'Confirm Arrival',
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
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: Text(
                                'Cancel Assignment?',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF18181B),
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to cancel this executive assignment? It will return to the radar for other chauffeurs.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(
                                    'Keep Assignment',
                                    style: GoogleFonts.poppins(
                                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(
                                    'Cancel Assignment',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await context.read<RideProvider>().cancelCurrentRide(reason: 'Chauffeur cancelled before arrival');
                            if (context.mounted) context.go('/driver-home');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          'Cancel Assignment',
                          style: GoogleFonts.poppins(
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ).animate().slideY(begin: 0.15, end: 0, duration: 450.ms, curve: Curves.easeOutCubic).fadeIn(duration: 350.ms),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color iconColor, String address, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            address,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF18181B),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
