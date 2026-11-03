import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';

class DriverOfferCard extends StatefulWidget {
  const DriverOfferCard({
    super.key,
    required this.passengerName,
    this.passengerAvatarUrl,
    required this.passengerCount,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fare,
    required this.rideId,
    this.isLoading = false,
    this.onAccept,
    this.onDecline,
  });

  final String passengerName;
  final String? passengerAvatarUrl;
  final int passengerCount;
  final String pickupAddress;
  final String dropoffAddress;
  final String fare;
  final String rideId;
  final bool isLoading;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  State<DriverOfferCard> createState() => _DriverOfferCardState();
}

class _DriverOfferCardState extends State<DriverOfferCard> {
  bool _isExpanded = false;
  bool _isRejected = false;

  void _handleDecline() {
    setState(() => _isRejected = true);
    widget.onDecline?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRejected) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeSlideIn(
      slideOffset: 0.1,
      child: Dismissible(
        key: ValueKey(widget.rideId),
        confirmDismiss: (direction) async {
          _handleDecline();
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.red, size: 28),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.red, size: 28),
        ),
        child: PressScale(
          scale: 0.99,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121316) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE4E4E7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Info + Fare Pill
                FadeSlideIn(
                  delay: AppDurations.staggerGap * 0,
                  slideOffset: 0.04,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isDark
                            ? const Color(0xFF1E2026)
                            : const Color(0xFFF4F4F5),
                        backgroundImage: widget.passengerAvatarUrl != null
                            ? NetworkImage(widget.passengerAvatarUrl!)
                            : null,
                        child: widget.passengerAvatarUrl == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 24,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF71717A),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.passengerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF18181B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 13,
                                  color: isDark
                                      ? const Color(0xFFA1A1AA)
                                      : const Color(0xFF71717A),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${widget.passengerCount} passenger${widget.passengerCount == 1 ? '' : 's'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? const Color(0xFFA1A1AA)
                                          : const Color(0xFF71717A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '\$${widget.fare}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Location Details (Inset container)
                FadeSlideIn(
                  delay: AppDurations.staggerGap * 1,
                  slideOffset: 0.04,
                  child: _buildLocationSection(isDark),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                FadeSlideIn(
                  delay: AppDurations.staggerGap * 2,
                  slideOffset: 0.04,
                  child: _buildActionButtons(isDark),
                ),

                // Expandable Detail Section
                if (_isExpanded) ...[
                  const SizedBox(height: 8),
                  _buildExpandedSection(isDark),
                ],

                const SizedBox(height: 4),

                // Expand/Collapse
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Less details' : 'More details',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: AppDurations.fast,
                            child: const Icon(
                              Icons.expand_more_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            Icons.my_location_rounded,
            AppColors.primary,
            widget.pickupAddress,
            isDark,
          ),
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
          _buildLocationRow(
            Icons.location_on_rounded,
            const Color(0xFFEF4444),
            widget.dropoffAddress,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, Color iconColor, String address, bool isDark) {
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

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: widget.isLoading ? null : _handleDecline,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
              child: Text(
                'Decline',
                style: GoogleFonts.poppins(
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF111827),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF111827),
                      ),
                    )
                  : Text(
                      'Accept Trip',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSection(bool isDark) {
    return FadeSlideIn(
      slideOffset: 0.03,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF9F8F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
          ),
        ),
        child: Column(
          children: [
            _buildInfoRow(Icons.directions_car_outlined, 'Distance', '~2.3 miles', isDark),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.timer_outlined, 'Est. arrival', '~8 min', isDark),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.star_rounded,
              'Client rating',
              '5.0',
              isDark,
              trailing: const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isDark,
      {Widget? trailing}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
          ),
        ),
        const Spacer(),
        if (trailing != null) ...[
          trailing,
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF18181B),
          ),
        ),
      ],
    );
  }
}
