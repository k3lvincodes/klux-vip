import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/services/currency_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/feedback/shimmer_loading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverRideHistoryScreen extends StatefulWidget {
  const DriverRideHistoryScreen({super.key});

  @override
  State<DriverRideHistoryScreen> createState() => _DriverRideHistoryScreenState();
}

class _DriverRideHistoryScreenState extends State<DriverRideHistoryScreen> {
  List<Ride> _rides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRideHistory();
  }

  Future<void> _fetchRideHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _isLoading = false; _error = 'Not authenticated'; });
      return;
    }

    try {
      final rides = await RideRepository().getDriverCompletedRides(user.id);
      if (mounted) {
        setState(() {
          _rides = rides;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = 'Failed to load ride history'; });
      }
    }
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('h:mm a').format(date);
  String _formatFare(double fare) => CurrencyService.format(fare);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Circular Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E2026) : Colors.white,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFE4E4E7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                              blurRadius: 8,
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
                  Text(
                    'Ride History',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          children: List.generate(5, (i) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 120, showAvatar: false, avatarSize: 0),
          )),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFEF4444)),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _fetchRideHistory,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                'No completed trips',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your completed chauffeur trips\nwill appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRideHistory,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        itemCount: _rides.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ride = _rides[index];
          return FadeSlideIn(
            delay: Duration(milliseconds: 50 * index),
            child: _DriverRideCard(
              ride: ride,
              formatDate: _formatDate,
              formatTime: _formatTime,
              formatFare: _formatFare,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _DriverRideCard extends StatelessWidget {
  const _DriverRideCard({
    required this.ride,
    required this.formatDate,
    required this.formatTime,
    required this.formatFare,
    required this.isDark,
  });

  final Ride ride;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final String Function(double) formatFare;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const completedGreen = Color(0xFF22C55E);

    final pickup = ride.pickupAddress.isNotEmpty ? ride.pickupAddress : 'Pickup Location';
    final dropoff = ride.dropoffAddress.isNotEmpty ? ride.dropoffAddress : 'Dropoff Location';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showRideReceipt(context, ride),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121316) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: completedGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 12, color: completedGreen),
                        const SizedBox(width: 5),
                        Text(
                          'Completed',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: completedGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatFare(ride.fareAmount),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Pickup
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.my_location_rounded, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pickup,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 7),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(
                    width: 2,
                    thickness: 1.5,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                  ),
                ),
              ),
              // Dropoff
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dropoff,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${formatDate(ride.createdAt)}  •  ${formatTime(ride.createdAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VIP Ride #${ride.id.substring(0, 6).toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRideReceipt(BuildContext context, Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFD4D4D8),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Receipt',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'VIP Ride #${ride.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'COMPLETED',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2026) : const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ride.pickupAddress.isNotEmpty ? ride.pickupAddress : 'Pickup',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white : const Color(0xFF18181B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ride.dropoffAddress.isNotEmpty ? ride.dropoffAddress : 'Dropoff',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white : const Color(0xFF18181B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Fare Earned',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                    ),
                  ),
                  Text(
                    formatFare(ride.fareAmount),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date & Time',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    ),
                  ),
                  Text(
                    '${formatDate(ride.createdAt)} at ${formatTime(ride.createdAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Gold Pill Close Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Close Receipt',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
