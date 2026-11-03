import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/theme/app_colors.dart';
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

          // Circular Back Button
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

          // Bottom Confirmation Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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

                    // Title row with green checkmark
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF22C55E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ride completed?',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF18181B),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 35),
                      child: Text(
                        'Please confirm that you\'ve completed the luxury ride',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // From / To with styled dot indicators
                    Consumer<RideProvider>(
                      builder: (context, rideProv, _) {
                        final pickup = rideProv.currentRideDetails?['pickup_address'] ?? 'Unknown location';
                        final dropoff = rideProv.currentRideDetails?['dropoff_address'] ?? 'Unknown location';
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
                              _buildAddressRow(
                                isDark: isDark,
                                label: 'From',
                                address: pickup,
                                dotColor: AppColors.primary,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                ),
                              ),
                              _buildAddressRow(
                                isDark: isDark,
                                label: 'To',
                                address: dropoff,
                                dotColor: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Complete Trip Signature Gold Pill button
                    Consumer<RideProvider>(
                      builder: (context, rideProv, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: rideProv.isLoading
                                ? null
                                : () async {
                                    final success = await rideProv.updateRideStatus('completed');
                                    if (success && context.mounted) {
                                      context.push('/ride-payment-received');
                                    }
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
                                    'Complete Trip',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
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
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF18181B),
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
