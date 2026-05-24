import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';

class EndRideConfirmationScreen extends StatelessWidget {
  const EndRideConfirmationScreen({super.key});

  static const LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          FlutterMap(
            options: const MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.5,
              interactionOptions: InteractionOptions(
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
            ],
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
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

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF5EFEE),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ride completed?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please confirm that you\'ve completed the ride',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // From / To
                  Consumer<RideProvider>(
                    builder: (context, rideProv, _) {
                      final pickup = rideProv.currentRideDetails?['pickup_address'] ?? 'Unknown';
                      final dropoff = rideProv.currentRideDetails?['dropoff_address'] ?? 'Unknown';
                      return Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text('From', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                              const Spacer(),
                              Text(pickup, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.white : AppColors.black)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text('To', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                              const Spacer(),
                              Text(dropoff, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.white : AppColors.black)),
                            ],
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 24),

                  Consumer<RideProvider>(
                    builder: (context, rideProv, _) {
                      return CustomButton(
                        title: rideProv.isLoading ? 'Completing...' : 'Yes',
                        onPress: rideProv.isLoading ? () {} : () async {
                          final success = await rideProv.updateRideStatus('completed');
                          if (success && context.mounted) {
                            rideProv.clearRide();
                            context.push('/ride-payment-received');
                          }
                        },
                        variant: ButtonVariant.primary,
                      );
                    }
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

