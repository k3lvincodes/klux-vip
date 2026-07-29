import 'package:flutter/material.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class ActiveTripCard extends StatelessWidget {

  const ActiveTripCard({
    super.key,
    this.passengerName,
    this.passengerAvatarUrl,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fare,
    required this.status,
    this.timeElapsed,
    this.onEndRide,
    this.onContact,
  });
  final String? passengerName;
  final String? passengerAvatarUrl;
  final String pickupAddress;
  final String dropoffAddress;
  final String fare;
  final String status;
  final String? timeElapsed;
  final VoidCallback? onEndRide;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArriving = status == 'arriving';

    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, -8),
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
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Status header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isArriving ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isArriving ? Colors.orange : Colors.green).withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isArriving ? 'Arriving at pickup' : 'Trip in progress',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (timeElapsed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : const Color(0xFFF9F8F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      timeElapsed!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Client info row
            if (passengerName != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFF5F0EF),
                    backgroundImage: passengerAvatarUrl != null
                        ? NetworkImage(passengerAvatarUrl!)
                        : null,
                    child: passengerAvatarUrl == null
                        ? Icon(Icons.person, size: 20, color: isDark ? AppColors.white : Colors.black54)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    passengerName!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '\$$fare',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Location details (VIP container styling)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161316) : const Color(0xFFFAF9F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
              ),
              child: Column(
                children: [
                  _buildLocationRow(Icons.my_location, Colors.green, pickupAddress, isDark),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 20,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  _buildLocationRow(Icons.location_on, Colors.red, dropoffAddress, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons with PressScale tactile micro-animations
            Row(
              children: [
                if (onContact != null) ...[
                  Expanded(
                    child: PressScale(
                      onTap: onContact,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: onContact,
                          icon: const Icon(Icons.message, size: 15, color: AppColors.primary),
                          label: const Text(
                            'Contact',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (onEndRide != null)
                  Expanded(
                    child: PressScale(
                      onTap: onEndRide,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: onEndRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text(
                            'End ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color iconColor, String address, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
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

