import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/widgets/feedback/shimmer_loading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<Map<String, dynamic>> _rides = [];
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
      final response = await Supabase.instance.client
          .from('ride_requests')
          .select()
          .eq('passenger_id', user.id)
          .inFilter('status', ['completed', 'cancelled'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _rides = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = 'Failed to load ride history'; });
      }
    }
  }

  String _formatDate(String iso) {
    final date = DateTime.parse(iso);
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTime(String iso) {
    final date = DateTime.parse(iso);
    return DateFormat('h:mm a').format(date);
  }

  String _formatFare(dynamic fare) {
    final amount = (fare as num?)?.toDouble() ?? 0.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'completed':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return isDark ? AppColors.darkText : AppColors.text;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

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
          'Ride History',
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
      return _buildLoadingSkeleton(isDark);
    }

    if (_error != null) {
      return _buildErrorState(isDark);
    }

    if (_rides.isEmpty) {
      return _buildEmptyState(isDark);
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
            child: _RideHistoryCard(
              ride: ride,
              isDark: isDark,
              formatDate: _formatDate,
              formatTime: _formatTime,
              formatFare: _formatFare,
              statusColor: _statusColor,
              statusIcon: _statusIcon,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 120, showAvatar: false, avatarSize: 0),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 120, showAvatar: false, avatarSize: 0),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 120, showAvatar: false, avatarSize: 0),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 120, showAvatar: false, avatarSize: 0),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerListItem(height: 120, showAvatar: false, avatarSize: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkText.withValues(alpha: 0.6) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _fetchRideHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Text(
              'No rides yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed and cancelled trips\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.darkText.withValues(alpha: 0.6) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({
    required this.ride,
    required this.isDark,
    required this.formatDate,
    required this.formatTime,
    required this.formatFare,
    required this.statusColor,
    required this.statusIcon,
  });

  final Map<String, dynamic> ride;
  final bool isDark;
  final String Function(String) formatDate;
  final String Function(String) formatTime;
  final String Function(dynamic) formatFare;
  final Color Function(String, bool) statusColor;
  final IconData Function(String) statusIcon;

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as String? ?? 'unknown';
    final createdAt = ride['created_at'] as String? ?? '';
    final pickup = ride['pickup_address'] as String? ?? 'Unknown pickup';
    final dropoff = ride['dropoff_address'] as String? ?? 'Unknown dropoff';
    final fare = ride['fare_amount'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor(status, isDark).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon(status),
                    size: 20,
                    color: statusColor(status, isDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [pickup, dropoff].join(' → '),
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
                        createdAt.isNotEmpty
                            ? '${formatDate(createdAt)}  •  ${formatTime(createdAt)}'
                            : 'Unknown date',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkText.withValues(alpha: 0.5)
                              : Colors.grey.shade500,
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
                      formatFare(fare),
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
                        color: statusColor(status, isDark).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor(status, isDark),
                        ),
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
