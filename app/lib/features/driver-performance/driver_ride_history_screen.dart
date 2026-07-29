import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
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
  String _formatFare(double fare) => '\$${fare.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppColors.white : AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chauffeur Ride History',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
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
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFEF4444)),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.white : AppColors.text)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkText.withValues(alpha: 0.6) : Colors.grey.shade600)),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _fetchRideHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_car_filled_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.7)),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text('No completed trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.white : AppColors.text)),
              const SizedBox(height: 8),
              Text(
                'Your completed chauffeur trips\nwill appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? AppColors.darkText.withValues(alpha: 0.6) : Colors.grey.shade600),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _rides.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ride = _rides[index];
          return FadeSlideIn(
            delay: Duration(milliseconds: 50 * index),
            child: _DriverRideCard(
              ride: ride,
              isDark: isDark,
              formatDate: _formatDate,
              formatTime: _formatTime,
              formatFare: _formatFare,
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
    required this.isDark,
    required this.formatDate,
    required this.formatTime,
    required this.formatFare,
  });

  final Ride ride;
  final bool isDark;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final String Function(double) formatFare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF22C55E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [ride.pickupAddress, ride.dropoffAddress].join(' → '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: isDark ? AppColors.white : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDate(ride.createdAt)}  •  ${formatTime(ride.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkText.withValues(alpha: 0.5) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatFare(ride.fareAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
