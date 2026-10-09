import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/vip_google_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class EndRideConfirmationScreen extends StatefulWidget {
  const EndRideConfirmationScreen({super.key});

  @override
  State<EndRideConfirmationScreen> createState() => _EndRideConfirmationScreenState();
}

class _EndRideConfirmationScreenState extends State<EndRideConfirmationScreen> {
  static const LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);
  late LatLng _currentPosition;
  final GlobalKey<VipGoogleMapState> _mapKey = GlobalKey<VipGoogleMapState>();

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null) ? mem.lastPosition! : _initialPosition;
  }

  @override
  void dispose() {
    MapMemory().save(_currentPosition, 14.5);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          VipGoogleMap(
            key: _mapKey,
            initialCenter: _currentPosition,
            initialZoom: 14.5,
            dropoffPosition: _currentPosition,
            driverPosition: _currentPosition,
            isStationary: true,
            padding: const EdgeInsets.only(bottom: 240, top: 60),
          ),

          // Glassmorphic Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Confirmation Sheet with slide-up + fadeIn
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF5EFEE),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title row with green checkmark
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ride completed?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 38),
                      child: Text(
                        'Please confirm that you\'ve completed the ride',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // From / To with styled dot indicators
                    Consumer<RideProvider>(
                      builder: (context, rideProv, _) {
                        final pickup = rideProv.currentRideDetails?['pickup_address'] ?? 'Unknown location';
                        final dropoff = rideProv.currentRideDetails?['dropoff_address'] ?? 'Unknown location';
                        return Column(
                          children: [
                            _buildAddressRow(
                              isDark: isDark,
                              label: 'From',
                              address: pickup,
                              dotColor: Colors.green,
                            ),
                            const SizedBox(height: 10),
                            _buildAddressRow(
                              isDark: isDark,
                              label: 'To',
                              address: dropoff,
                              dotColor: Colors.red,
                            ),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 24),

                    // Complete Trip button with single action trigger
                    Consumer<RideProvider>(
                      builder: (context, rideProv, _) {
                        return CustomButton(
                          title: rideProv.isLoading ? 'Completing...' : 'Complete Trip',
                          onPress: rideProv.isLoading ? () {} : () async {
                            final success = await rideProv.updateRideStatus('completed');
                            if (success && context.mounted) {
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
            )
                .animate()
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required bool isDark,
    required String label,
    required String address,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Colored dot indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.35),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              address,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
