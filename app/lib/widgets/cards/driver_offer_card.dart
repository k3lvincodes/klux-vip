import 'package:flutter/material.dart';
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
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.close, color: Colors.red, size: 28),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.close, color: Colors.red, size: 28),
        ),
        child: PressScale(
          scale: 0.99,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.grey.shade800
                    : AppColors.primary.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Info
                FadeSlideIn(
                  delay: AppDurations.staggerGap * 0,
                  slideOffset: 0.04,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : const Color(0xFFF5F0EF),
                        backgroundImage: widget.passengerAvatarUrl != null
                            ? NetworkImage(widget.passengerAvatarUrl!)
                            : null,
                        child: widget.passengerAvatarUrl == null
                            ? Icon(Icons.person,
                                size: 26,
                                color: isDark
                                    ? AppColors.white
                                    : Colors.black54)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.passengerName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.people,
                                    size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.passengerCount} passenger${widget.passengerCount == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\$${widget.fare}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Location Details
                FadeSlideIn(
                  delay: AppDurations.staggerGap * 1,
                  slideOffset: 0.04,
                  child: _buildLocationSection(isDark),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                FadeSlideIn(
                  delay: AppDurations.staggerGap * 2,
                  slideOffset: 0.04,
                  child: _buildActionButtons(isDark),
                ),

                // Expandable Detail Section
                if (_isExpanded) ...[
                  const SizedBox(height: 4),
                  _buildExpandedSection(isDark),
                ],

                const SizedBox(height: 4),

                // Expand/Collapse
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Less details' : 'More details',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: AppDurations.fast,
                            child: const Icon(
                              Icons.expand_more,
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
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF9F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            Icons.my_location,
            Colors.green,
            widget.pickupAddress,
            isDark,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: SizedBox(
              height: 14,
              child: VerticalDivider(width: 2, thickness: 2, color: Colors.grey.shade300),
            ),
          ),
          _buildLocationRow(
            Icons.location_on,
            Colors.red,
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
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              height: 1.3,
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
            height: 44,
            child: OutlinedButton(
              onPressed: widget.isLoading ? null : _handleDecline,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Decline',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'Accept',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : const Color(0xFFF9F8F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            _buildInfoRow(Icons.directions_car, 'Distance', '~2.3 miles', isDark),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.timer_outlined, 'Est. time', '~8 min', isDark),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.star_outline,
              'Client rating',
              '4.8',
              isDark,
              trailing: const Icon(Icons.star, size: 12, color: Colors.amber),
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
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        if (trailing != null) ...[
          trailing,
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
      ],
    );
  }
}
