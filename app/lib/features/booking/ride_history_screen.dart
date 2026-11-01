import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/currency_service.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/feedback/shimmer_loading.dart';
import 'package:kenick_vip/widgets/navigation/kenick_bottom_nav_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  List<Map<String, dynamic>> _allRides = [];
  bool _isLoading = true;
  String? _countryCode;
  StreamSubscription<List<Map<String, dynamic>>>? _ridesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    _initCountryCode();
    _fetchRides();
    _subscribeToRides();
  }

  Future<void> _initCountryCode() async {
    try {
      final code = await LocationSearchService.detectCountryCode(
        const LatLng(37.4279, -122.0857),
      );
      if (mounted) setState(() => _countryCode = code);
    } catch (_) {}
  }

  void _subscribeToRides() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      _ridesSubscription = Supabase.instance.client
          .from('rides')
          .stream(primaryKey: ['id'])
          .eq('passenger_id', user.id)
          .listen((_) {
            _fetchRides();
          }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRides() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _allRides = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 0. Trigger backend auto-cancellation of stale unmatched rides if RPC exists
      try {
        await Supabase.instance.client.rpc('auto_cancel_stale_rides');
      } catch (_) {}

      // 1. Fetch from rides table (where user is passenger or driver)
      final ridesResponse = await Supabase.instance.client
          .from('rides')
          .select()
          .or('passenger_id.eq.${user.id},driver_id.eq.${user.id}')
          .order('created_at', ascending: false);

      final combined = List<Map<String, dynamic>>.from(ridesResponse);

      // 2. Also union with pending / requested ride_requests
      try {
        final requestsResponse = await Supabase.instance.client
            .from('ride_requests')
            .select()
            .eq('passenger_id', user.id)
            .order('created_at', ascending: false);

        final reqList = List<Map<String, dynamic>>.from(requestsResponse);
        final existingIds = combined.map((r) => r['id'].toString()).toSet();
        for (final req in reqList) {
          if (!existingIds.contains(req['id'].toString())) {
            combined.add(req);
          }
        }
      } catch (_) {}

      // 3. Scan and identify stale matching rides (> 30 mins) to auto-cancel in DB
      final staleRidesToCancel = <Map<String, dynamic>>[];
      for (final r in combined) {
        if (_isAutoCancelledStaleRide(r) || _isExpiredScheduledRide(r)) {
          final originalStatus = (r['status'] as String? ?? '').toLowerCase();
          if (originalStatus != 'cancelled' && originalStatus != 'canceled') {
            staleRidesToCancel.add(r);
          }
        }
      }

      if (staleRidesToCancel.isNotEmpty) {
        _cancelStaleRidesInDatabase(staleRidesToCancel);
      }

      // 4. Sort chronologically descending
      combined.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _allRides = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Auto-cancels unmatched rides in Supabase so historical records (e.g. from September)
  /// are permanently marked cancelled in the database.
  Future<void> _cancelStaleRidesInDatabase(List<Map<String, dynamic>> staleList) async {
    for (final r in staleList) {
      final id = r['id']?.toString();
      if (id == null) continue;
      try {
        await Supabase.instance.client
            .from('ride_requests')
            .update({
              'status': 'cancelled',
              'passenger_note': 'Auto-cancelled: No chauffeur matched within 30 minutes',
            })
            .eq('id', id);

        await Supabase.instance.client
            .from('rides')
            .update({
              'status': 'cancelled',
              'cancelled_reason': 'Auto-cancelled: No chauffeur matched within 30 minutes',
            })
            .eq('id', id);
      } catch (_) {}
    }
  }

  /// Determines if a ride was in matching / requested state without a chauffeur match for > 30 minutes.
  bool _isAutoCancelledStaleRide(Map<String, dynamic> ride) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    final isMatching = status == 'pending' || status == 'requested' || status == 'searching';
    if (!isMatching) return false;

    // If a driver was already assigned, it's not an unmatched search
    final driverId = ride['driver_id'];
    if (driverId != null && driverId.toString().trim().isNotEmpty) {
      return false;
    }

    final createdAtStr = ride['created_at']?.toString();
    if (createdAtStr == null) return false;
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return false;

    final age = DateTime.now().toUtc().difference(createdAt.toUtc());
    return age.inMinutes >= 30;
  }

  /// Determines if a scheduled ride without a chauffeur is past its cutoff (+ 30 mins after scheduled pickup).
  bool _isExpiredScheduledRide(Map<String, dynamic> ride) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    if (status == 'completed' || status == 'cancelled' || status == 'canceled') return false;

    final driverId = ride['driver_id'];
    final hasNoDriver = driverId == null || driverId.toString().trim().isEmpty;
    if (!hasNoDriver) return false;

    final scheduledTimeStr = (ride['scheduled_time'] ?? ride['scheduled_pickup_time'])?.toString();
    if (scheduledTimeStr != null && scheduledTimeStr.isNotEmpty) {
      final scheduledTime = DateTime.tryParse(scheduledTimeStr);
      if (scheduledTime != null) {
        final cutoff = scheduledTime.toUtc().add(const Duration(minutes: 30));
        return DateTime.now().toUtc().isAfter(cutoff);
      }
    }

    return false;
  }

  /// Returns true if the ride is cancelled either explicitly in the database,
  /// or dynamically auto-cancelled because it exceeded the 30-minute matching window.
  bool _isCancelledRide(Map<String, dynamic> ride) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    if (status == 'cancelled' || status == 'canceled') return true;
    if (_isAutoCancelledStaleRide(ride)) return true;
    if (_isExpiredScheduledRide(ride)) return true;
    return false;
  }

  List<Map<String, dynamic>> get _upcomingRides {
    return _allRides.where((r) {
      final status = (r['status'] as String? ?? '').toLowerCase();
      if (status == 'completed') return false;
      if (_isCancelledRide(r)) return false;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _pastRides {
    return _allRides.where((r) {
      final status = (r['status'] as String? ?? '').toLowerCase();
      return status == 'completed';
    }).toList();
  }

  List<Map<String, dynamic>> get _canceledRides {
    return _allRides.where((r) => _isCancelledRide(r)).toList();
  }

  List<Map<String, dynamic>> _getRidesForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _upcomingRides;
      case 1:
        return _pastRides;
      case 2:
        return _canceledRides;
      default:
        return [];
    }
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      return DateFormat('h:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  String _formatFare(dynamic fare) {
    final amount = (fare as num?)?.toDouble() ?? 0.0;
    return CurrencyService.format(amount, countryCode: _countryCode);
  }

  String _resolveVehicleName(Map<String, dynamic> ride) {
    // 1. Direct vehicle_type if real value present
    final vt = (ride['vehicle_type'] ?? ride['vehicle_name']) as String?;
    if (vt != null && vt.trim().isNotEmpty && vt != 'VIP Sedan') {
      return vt.trim();
    }

    // 2. Parse from passenger_note
    final note = ride['passenger_note'] as String? ?? '';
    if (note.isNotEmpty) {
      final reqMatch = RegExp(
        r'Requested VIP vehicle:\s*([^\n\r·]+)',
        caseSensitive: false,
      ).firstMatch(note);
      if (reqMatch != null && reqMatch.group(1)?.trim().isNotEmpty == true) {
        return reqMatch.group(1)!.trim();
      }

      final fleetMatch = RegExp(
        r'Fleet:\s*([^\n\r·]+)',
        caseSensitive: false,
      ).firstMatch(note);
      if (fleetMatch != null && fleetMatch.group(1)?.trim().isNotEmpty == true) {
        return fleetMatch.group(1)!.trim();
      }

      final specialMatch = RegExp(
        r'Special Event:\s*([^\n\r·]+)',
        caseSensitive: false,
      ).firstMatch(note);
      if (specialMatch != null &&
          specialMatch.group(1)?.trim().isNotEmpty == true) {
        return specialMatch.group(1)!.trim();
      }
    }

    // 3. Infer from ride type
    final type = (ride['type'] ?? ride['booking_type'] as String?)?.toLowerCase();
    if (type == 'special') {
      return 'Special Event Fleet';
    } else if (type == 'schedule') {
      return 'Scheduled VIP Fleet';
    }

    return 'VIP Fleet Vehicle';
  }

  void _onRideTapped(Map<String, dynamic> ride) {
    _showRideReceipt(ride);
  }

  void _showRideReceipt(Map<String, dynamic> ride) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final pickup = ride['pickup_address'] as String? ?? 'Pickup Location';
    final dropoff = ride['dropoff_address'] as String? ?? 'Drop-off Destination';
    final status = (ride['status'] as String? ?? 'completed').toLowerCase();
    final isCancelled = _isCancelledRide(ride);
    final isUpcoming = !isCancelled && status != 'completed';
    final isStaleAutoCancelled = _isAutoCancelledStaleRide(ride) || _isExpiredScheduledRide(ride);
    final createdAt = ride['created_at']?.toString() ?? '';
    final fare = ride['fare_amount'] ?? ride['estimated_fare'] ?? 0;
    final vehicleName = _resolveVehicleName(ride);
    final rideId = ride['id']?.toString() ?? '';

    final isCompleted = status == 'completed' && !isCancelled;

    Color statusBadgeColor;
    String statusBadgeText;
    if (isCompleted) {
      statusBadgeColor = const Color(0xFF10B981);
      statusBadgeText = 'COMPLETED';
    } else if (isCancelled) {
      statusBadgeColor = const Color(0xFFEF4444);
      statusBadgeText = 'CANCELED';
    } else if (status == 'accepted' || status == 'arriving' || status == 'in_progress') {
      statusBadgeColor = const Color(0xFF3B82F6);
      statusBadgeText = status == 'in_progress' ? 'IN PROGRESS' : 'CHAUFFEUR ASSIGNED';
    } else {
      statusBadgeColor = AppColors.primary;
      statusBadgeText = status == 'pending' || status == 'requested'
          ? 'MATCHING'
          : 'SCHEDULED';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUpcoming ? 'Trip Details' : 'Trip Receipt',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          if (rideId.isNotEmpty)
                            Text(
                              'VIP Trip #${rideId.length > 8 ? rideId.substring(0, 8).toUpperCase() : rideId.toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBadgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusBadgeText,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusBadgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              if (isStaleAutoCancelled) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_off_outlined, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-cancelled: No chauffeur matched within 30 minutes',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Route Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141416)
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickup,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white70 : Colors.black87,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dropoff,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Info rows
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chauffeur Vehicle',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      vehicleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
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
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _formatTime(createdAt).isNotEmpty
                          ? '${_formatDate(createdAt)} at ${_formatTime(createdAt)}'
                          : _formatDate(createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Fare Paid',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    _formatFare(fare),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (isUpcoming) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      try {
                        final rp = context.read<RideProvider>();
                        final rideModel = Ride.fromJson(ride);
                        rp.restoreActiveRide(rideModel.passengerId);

                        final bp = context.read<BookingProvider>();
                        bp.setTripDetails(
                          pickupAddress: rideModel.pickupAddress,
                          dropoffAddress: rideModel.dropoffAddress,
                          pickupLat: rideModel.pickupLat,
                          pickupLng: rideModel.pickupLng,
                          dropoffLat: rideModel.dropoffLat,
                          dropoffLng: rideModel.dropoffLng,
                          passengerNote: rideModel.passengerNote,
                        );
                        bp.setFare(rideModel.fareAmount, null);
                        bp.setVehicle(_resolveVehicleName(ride));
                      } catch (_) {}
                      context.push('/trip-summary');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Track Ride / Live Map',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Close Receipt',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header: Title "Rides" (and back button if pushed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (canPop)
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
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    'Rides',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Tab Bar: Upcoming | Past | Canceled
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  // Baseline divider spanning full width
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 1.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabAlignment: TabAlignment.fill,
                    labelPadding: EdgeInsets.zero,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: cs.onSurface,
                    unselectedLabelColor:
                        cs.onSurfaceVariant.withValues(alpha: 0.65),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Past'),
                      Tab(text: 'Canceled'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Views Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent(0, isDark, cs),
                        _buildTabContent(1, isDark, cs),
                        _buildTabContent(2, isDark, cs),
                      ],
                    ),
            ),

            // Floating Navigation Pill at the bottom
            const KenickBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex, bool isDark, ColorScheme cs) {
    final rides = _getRidesForTab(tabIndex);

    if (rides.isEmpty) {
      return _buildEmptyState(tabIndex, isDark, cs);
    }

    return RefreshIndicator(
      onRefresh: _fetchRides,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        itemCount: rides.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final ride = rides[index];
          return _buildRideCard(ride, isDark, cs);
        },
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex, bool isDark, ColorScheme cs) {
    String heading;
    switch (tabIndex) {
      case 0:
        heading = 'You have no upcoming\nrides';
        break;
      case 1:
        heading = 'You have no past\nrides';
        break;
      case 2:
        heading = 'You have no canceled\nrides';
        break;
      default:
        heading = 'No rides found';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),

          // Illustration: Stylized VIP Car with trailing motion lines
          _buildCarIllustration(isDark),

          const SizedBox(height: 28),

          // Empty state title
          Text(
            heading,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              height: 1.28,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            'As soon as you book a ride, all of your relevant details will be shown here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.45,
            ),
          ),

          const Spacer(flex: 4),

          // Outlined "Book a ride" Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/book-journey');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                foregroundColor: AppColors.primary,
                backgroundColor: isDark
                    ? AppColors.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
              ),
              child: Text(
                'Book a ride',
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primary : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCarIllustration(bool isDark) {
    return SizedBox(
      width: 96,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Trailing horizontal motion lines
          Positioned(
            right: 14,
            top: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 26,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 34,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // Vehicle icon in soft container
          Positioned(
            left: 10,
            child: Container(
              width: 52,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : AppColors.softYellow.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.directions_car_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(
    Map<String, dynamic> ride,
    bool isDark,
    ColorScheme cs,
  ) {
    final pickup = ride['pickup_address'] as String? ?? 'Pickup Location';
    final dropoff = ride['dropoff_address'] as String? ?? 'Destination';
    final status = (ride['status'] as String? ?? 'pending').toLowerCase();
    final createdAt = ride['created_at']?.toString() ?? '';
    final fare = ride['fare_amount'] ?? ride['estimated_fare'] ?? 0;
    final vehicleType = _resolveVehicleName(ride);

    final isCancelled = _isCancelledRide(ride);
    final effectiveStatus = isCancelled ? 'cancelled' : status;

    Color statusBadgeColor;
    String statusText;
    switch (effectiveStatus) {
      case 'completed':
        statusBadgeColor = const Color(0xFF10B981);
        statusText = 'Completed';
        break;
      case 'cancelled':
      case 'canceled':
        statusBadgeColor = const Color(0xFFEF4444);
        statusText = 'Canceled';
        break;
      case 'in_progress':
      case 'started':
        statusBadgeColor = AppColors.primary;
        statusText = 'In Progress';
        break;
      case 'arrived':
        statusBadgeColor = const Color(0xFF3B82F6);
        statusText = 'Chauffeur Arrived';
        break;
      case 'accepted':
        statusBadgeColor = const Color(0xFF3B82F6);
        statusText = 'Chauffeur Assigned';
        break;
      default:
        statusBadgeColor = AppColors.primary;
        statusText = status == 'pending' || status == 'requested'
            ? 'Matching Chauffeur'
            : 'Scheduled';
    }

    return GestureDetector(
      onTap: () => _onRideTapped(ride),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Date/Time + Status Chip
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTime(createdAt).isNotEmpty
                          ? '${_formatDate(createdAt)} • ${_formatTime(createdAt)}'
                          : _formatDate(createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: statusBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: statusBadgeColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Pickup Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              // Dotted vertical line
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 1,
                height: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              ),

              // Dropoff Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white70 : Colors.black87,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dropoff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 12),

              // Bottom Info: Vehicle Type & Fare
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vehicleType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatFare(fare),
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
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

  Widget _buildLoadingSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ShimmerListItem(height: 130, showAvatar: false, avatarSize: 0),
          SizedBox(height: 14),
          ShimmerListItem(height: 130, showAvatar: false, avatarSize: 0),
        ],
      ),
    );
  }
}
