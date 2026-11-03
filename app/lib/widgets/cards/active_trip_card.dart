import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class ActiveTripCard extends StatelessWidget {
  const ActiveTripCard({
    super.key,
    this.passengerName,
    this.passengerAvatarUrl,
    this.subtitle,
    this.rating,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fare,
    required this.status,
    this.timeElapsed,
    this.onEndRide,
    this.onContact,
    this.contactButtonText = 'Contact',
    this.onSecondaryAction,
    this.secondaryActionText,
  });

  final String? passengerName;
  final String? passengerAvatarUrl;
  final String? subtitle;
  final String? rating;
  final String pickupAddress;
  final String dropoffAddress;
  final String fare;
  final String status;
  final String? timeElapsed;
  final VoidCallback? onEndRide;
  final VoidCallback? onContact;
  final String contactButtonText;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArriving = status == 'arriving';

    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141416) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
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
            // Drag Handle
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

            // Status header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isArriving ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isArriving ? const Color(0xFFF59E0B) : const Color(0xFF22C55E)).withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  isArriving ? 'Arriving at pickup' : 'Trip in progress',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                if (timeElapsed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                      ),
                    ),
                    child: Text(
                      timeElapsed!,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Chauffeur / Passenger info row
            if (passengerName != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark ? const Color(0xFF1E2026) : const Color(0xFFF4F4F5),
                    backgroundImage: passengerAvatarUrl != null
                        ? NetworkImage(passengerAvatarUrl!)
                        : null,
                    child: passengerAvatarUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 22,
                            color: isDark ? Colors.white70 : Colors.black54,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                passengerName!,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF18181B),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (rating != null && rating!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded, size: 15, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                rating!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '\$$fare',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // Location details (VIP container styling)
            Container(
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
                  _buildLocationRow(Icons.my_location_rounded, AppColors.primary, pickupAddress, isDark),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 12,
                        child: VerticalDivider(
                          width: 2,
                          thickness: 1.5,
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                        ),
                      ),
                    ),
                  ),
                  _buildLocationRow(Icons.location_on_rounded, const Color(0xFFEF4444), dropoffAddress, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                if (onContact != null)
                  Expanded(
                    child: PressScale(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: onContact,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                          label: Text(
                            contactButtonText,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onContact != null && (onSecondaryAction != null || onEndRide != null))
                  const SizedBox(width: 12),
                if (onSecondaryAction != null)
                  Expanded(
                    child: PressScale(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: onSecondaryAction,
                          icon: Icon(Icons.shield_outlined, size: 16, color: isDark ? Colors.white70 : const Color(0xFF18181B)),
                          label: Text(
                            secondaryActionText ?? 'Safety',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF18181B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onEndRide != null)
                  Expanded(
                    child: PressScale(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: onEndRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'End trip',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
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
