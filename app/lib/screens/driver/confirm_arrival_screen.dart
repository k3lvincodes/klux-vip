import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';

class ConfirmArrivalScreen extends StatelessWidget {
  const ConfirmArrivalScreen({super.key});

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
                    ? "https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}"
                    : "https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
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
                    'Confirmation of arrival',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You may cancel the offer',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer<RideProvider>(
                    builder: (context, rideProv, _) {
                      return CustomButton(
                        title: rideProv.isLoading ? 'Updating...' : 'Confirm arrival',
                        onPress: rideProv.isLoading ? () {} : () async {
                          final success = await rideProv.updateRideStatus('arriving');
                          if (success && context.mounted) {
                            context.push('/start-ride');
                          }
                        },
                        variant: ButtonVariant.primary,
                      );
                    }
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
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
                      child:  Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? AppColors.white : AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }
}

