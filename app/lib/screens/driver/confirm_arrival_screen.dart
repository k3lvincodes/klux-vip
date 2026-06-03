import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';

class ConfirmArrivalScreen extends StatefulWidget {
  const ConfirmArrivalScreen({super.key});

  @override
  State<ConfirmArrivalScreen> createState() => _ConfirmArrivalScreenState();
}

class _ConfirmArrivalScreenState extends State<ConfirmArrivalScreen> {
  static const LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);
  late LatLng _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null) ? mem.lastPosition! : _initialPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentPosition, mem.lastZoom);
    });
  }

  @override
  void dispose() {
    MapMemory().save(_currentPosition, _mapController.camera.zoom);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simulated pickup position (slightly offset from driver)
    final pickupPosition = LatLng(
      _currentPosition.latitude + 0.002,
      _currentPosition.longitude + 0.001,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? "https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}"
                    : "https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                },
                userAgentPackageName: 'com.kenickvip.app',
                maxZoom: 22,
              ),
              // Route line from chauffeur to pickup
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_currentPosition, pickupPosition],
                    color: AppColors.primary,
                    strokeWidth: 4.0,
                    borderColor: AppColors.primary.withValues(alpha: 0.3),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Chauffeur car marker (approaching pickup)
                  AnimatedMarker.driverCar(
                    point: _currentPosition,
                    isStationary: false,
                  ),
                  // Pickup pin at destination
                  AnimatedMarker.pickupPin(
                    point: pickupPosition,
                    label: 'Pickup',
                  ),
                ],
              ),
            ],
          ),

          // Glassmorphic Back Button
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.arrow_back, size: 18, color: isDark ? AppColors.white : AppColors.black),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Sheet - Arrival Confirmation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Confirmation of arrival',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      'You may cancel the offer',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Trip info preview
                  Consumer<RideProvider>(
                    builder: (context, rideProv, _) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161316) : const Color(0xFFFAF9F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.my_location, Colors.green, rideProv.currentRideDetails?['pickup_address'] ?? 'Pickup', isDark),
                            Padding(
                              padding: const EdgeInsets.only(left: 7),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 2,
                                  height: 18,
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            _buildInfoRow(Icons.location_on, Colors.red, rideProv.currentRideDetails?['dropoff_address'] ?? 'Dropoff', isDark),
                          ],
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 22),

                  Consumer<RideProvider>(
                    builder: (context, rideProv, _) {
                      return PressScale(
                        onTap: rideProv.isLoading ? null : () async {
                          final success = await rideProv.updateRideStatus('arriving');
                          if (success && context.mounted) {
                            context.push('/start-ride');
                          }
                        },
                        child: CustomButton(
                          title: rideProv.isLoading ? 'Updating...' : 'Confirm arrival',
                          onPress: rideProv.isLoading ? () {} : () async {
                            final success = await rideProv.updateRideStatus('arriving');
                            if (success && context.mounted) {
                              context.push('/start-ride');
                            }
                          },
                          variant: ButtonVariant.primary,
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 12),
                  PressScale(
                    onTap: () => context.pop(),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: isDark ? Colors.grey.shade700 : AppColors.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? AppColors.white : AppColors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ).animate()
              .slideY(begin: 0.15, end: 0, duration: 450.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 350.ms),
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
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              height: 1.4,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}
