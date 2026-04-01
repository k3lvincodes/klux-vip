import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/ride_provider.dart';

class EndRideConfirmationScreen extends StatelessWidget {
  const EndRideConfirmationScreen({super.key});

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 11,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          const GoogleMap(
            initialCameraPosition: _initialPosition,
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
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
                  color: AppColors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.black),
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
              decoration: const BoxDecoration(
                color: Color(0xFFF5EFEE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride completed?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please confirm that you\'ve completed the ride',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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
                              const Text('From', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const Spacer(),
                              Text(pickup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.black)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              const Text('To', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const Spacer(),
                              Text(dropoff, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.black)),
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
