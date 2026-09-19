import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/cards/driver_offer_card.dart';
import 'package:kenick_vip/widgets/navigation/drawer_item.dart';
import 'package:kenick_vip/widgets/navigation/premium_drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _userName = 'CHAUFFEUR';
  String? _profileImageUrl;
  bool _isOnline = true;
  double _todayEarnings = 0.0;
  int _totalTrips = 0;
  double _rating = 0.0;
  int _ratingCount = 0;

  final Map<String, String> _passengerNames = {};
  final Set<String> _fetchedPassengerIds = {};
  final Set<String> _declinedRideIds = {};
  final Set<String> _notifiedRideIds = {};
  String _lastRideIds = '';
  Future<List<Ride>>? _completedRidesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfile();
    _loadDeclinedRides();
    _initCompletedRidesFuture();
  }

  void _initCompletedRidesFuture() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _completedRidesFuture = RideRepository().getDriverCompletedRides(user.id).then((rides) {
        if (mounted) {
          final now = DateTime.now();
          double todayTotal = 0;
          for (final r in rides) {
            final isToday = r.createdAt.year == now.year &&
                r.createdAt.month == now.month &&
                r.createdAt.day == now.day;
            if (isToday) {
              todayTotal += r.fareAmount;
            }
          }
          setState(() {
            _todayEarnings = todayTotal;
            _totalTrips = rides.length;
          });
        }
        return rides;
      });
    }
  }

  Future<void> _loadDeclinedRides() async {
    final prefs = await SharedPreferences.getInstance();
    final declined = prefs.getStringList('declined_ride_ids') ?? [];
    if (mounted) setState(() => _declinedRideIds.addAll(declined));
  }

  Future<void> _saveDeclinedRides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('declined_ride_ids', _declinedRideIds.toList());
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await ProfileRepository().getDriverProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _userName = profile.displayName.trim().toUpperCase();
            if (_userName.isEmpty) _userName = 'CHAUFFEUR';
            _profileImageUrl = profile.avatarUrl;
            if (profile.driverDetails != null) {
              _isOnline = profile.driverDetails!['is_online'] as bool? ?? true;
              final rawRating = profile.driverDetails!['rating'];
              final rawCount = profile.driverDetails!['rating_count'];
              if (rawRating != null) {
                _rating = (rawRating as num).toDouble();
              }
              if (rawCount != null) {
                _ratingCount = (rawCount as num).toInt();
              }
            }
          });
        }
      } catch (e) {
        // Best effort
      }
    }
  }

  Future<void> _toggleOnlineStatus() async {
    final nextStatus = !_isOnline;
    setState(() => _isOnline = nextStatus);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('driver_details')
          .update({
            'is_online': nextStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('profile_id', user.id);

      if (mounted) {
        CustomToast.showSuccess(
          context,
          nextStatus ? 'Status: Online Standby (Receiving assignments)' : 'Status: Offline (Standby paused)',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOnline = !nextStatus);
        CustomToast.showError(context, 'Failed to update standby status');
      }
    }
  }

  Future<void> _fetchPassengerNames(List<Map<String, dynamic>> rides) async {
    final uniqIds = <String>{};
    for (final ride in rides) {
      final pid = ride['passenger_id'] as String?;
      if (pid != null) uniqIds.add(pid);
    }
    final newIds = uniqIds.difference(_fetchedPassengerIds).toList();
    if (newIds.isEmpty) return;
    _fetchedPassengerIds.addAll(newIds);
    try {
      final results = await Future.wait(
        newIds.map((id) => Supabase.instance.client
            .from('profiles')
            .select('id, first_name, last_name')
            .eq('id', id)
            .maybeSingle()),
      );
      if (mounted) {
        for (final p in results) {
          if (p == null) continue;
          final pid = p['id'] as String;
          final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
          _passengerNames[pid] = name.isNotEmpty ? name : 'Client';
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        for (final id in newIds) {
          _passengerNames[id] = 'Client';
        }
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: Container(
        width: double.infinity,
        color: cs.surface,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Executive Top Bar
              _buildTopBar(cs, tt),

              // 2. Chauffeur Telemetry Card
              _buildTelemetryCard(cs, tt),

              const SizedBox(height: 10),

              // 3. Segmented Tab Selector
              _buildSegmentedTabSelector(cs, tt),

              const SizedBox(height: 8),

              // 4. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvailableTab(),
                    _buildCompletedTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Drawer menu icon button
          GestureDetector(
            onTap: () {
              _fetchProfile().ignore();
              if (mounted) _scaffoldKey.currentState?.openDrawer();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.menu_rounded, color: cs.onSurface, size: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Chauffeur Identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'VIP CHAUFFEUR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Online / Offline Toggle Pill
          GestureDetector(
            onTap: _toggleOnlineStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isOnline
                    ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                    : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isOnline
                      ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                      : cs.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isOnline ? const Color(0xFF22C55E) : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: _isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isOnline ? const Color(0xFF22C55E) : cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Notifications Button
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined, color: cs.onSurface, size: 20),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // 1. Today's Revenue
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/account'),
              behavior: HitTestBehavior.opaque,
              child: _buildTelemetryItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: cs.primary,
                label: "Today's Fare",
                value: '\$${_todayEarnings.toStringAsFixed(2)}',
                cs: cs,
                tt: tt,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
          // 2. Completed Trips
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/driver-ride-history'),
              behavior: HitTestBehavior.opaque,
              child: _buildTelemetryItem(
                icon: Icons.directions_car_filled_outlined,
                iconColor: const Color(0xFF3B82F6),
                label: 'Trips Logged',
                value: '$_totalTrips',
                cs: cs,
                tt: tt,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
          // 3. Rating
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/driver-performance'),
              behavior: HitTestBehavior.opaque,
              child: _buildTelemetryItem(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'Rating',
                value: (_ratingCount > 0 && _rating > 0) ? '${_rating.toStringAsFixed(1)} ★' : '--',
                cs: cs,
                tt: tt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabSelector(ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_rounded, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Assignments',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Completed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_completedRidesFuture == null) return const SizedBox();

    return FutureBuilder<List<Ride>>(
      future: _completedRidesFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
          );
        }
        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
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
                      shape: BoxShape.circle,
                      color: cs.surfaceContainerHigh,
                    ),
                    child: Icon(Icons.history_rounded, size: 36, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Text('No Completed Trips Yet', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Your finished itineraries will be logged here with complete revenue details.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        final rides = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          itemCount: rides.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ride = rides[index];
            final pickup = ride.pickupAddress.isNotEmpty ? ride.pickupAddress : 'Pickup Location';
            final dropoff = ride.dropoffAddress.isNotEmpty ? ride.dropoffAddress : 'Dropoff Location';
            final fare = '\$${ride.fareAmount.toStringAsFixed(2)}';
            final dateStr = DateFormat('MMM d, h:mm a').format(ride.createdAt);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF22C55E)),
                            SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fare,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Pickup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.my_location_rounded, color: cs.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pickup,
                          style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: SizedBox(
                      height: 10,
                      child: VerticalDivider(
                        width: 2,
                        thickness: 1.5,
                        color: cs.outlineVariant.withValues(alpha: 0.4),
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
                          style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                      Text(
                        'VIP Ride #${ride.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableTab() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RideRepository().listenToRequestedRides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
                ),
                const SizedBox(height: 12),
                Text('Connecting to assignment radar...', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint('Available rides error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: cs.outline),
                const SizedBox(height: 12),
                Text('No available rides right now', style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }
        final fifteenMinsAgo = DateTime.now().subtract(const Duration(minutes: 15));
        final rides = (snapshot.data ?? []).where((r) {
          if (_declinedRideIds.contains(r['id'])) return false;
          final createdAt = r['created_at'] != null ? DateTime.tryParse(r['created_at'].toString()) : null;
          if (createdAt != null && createdAt.isBefore(fifteenMinsAgo)) return false;
          return true;
        }).toList();

        final currentRideIds = rides.map((e) => e['id']).join(',');
        if (currentRideIds != _lastRideIds) {
          _lastRideIds = currentRideIds;
          final newRides = rides.where((r) => !_notifiedRideIds.contains(r['id'])).toList();
          if (newRides.isNotEmpty && _tabController.index == 0) {
            _notifiedRideIds.addAll(newRides.map((r) => r['id'] as String));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRideNotification(newRides.first);
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchPassengerNames(rides);
          });
        }

        return AnimatedSwitcher(
          duration: AppDurations.normal,
          switchInCurve: AppCurves.easeOutCubic,
          switchOutCurve: AppCurves.easeOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: rides.isEmpty ? _buildEmptyState() : _buildRidesList(rides),
        );
      },
    );
  }

  void _showRideNotification(Map<String, dynamic> ride) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_rounded, size: 28, color: cs.primary),
              ),
              const SizedBox(height: 14),
              Text('New Executive Assignment!', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'A VIP booking has been matched to your vehicle',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              _buildNotifRow(Icons.my_location_rounded, 'Pickup', ride['pickup_address'] ?? 'Unknown location', cs),
              const SizedBox(height: 8),
              _buildNotifRow(Icons.location_on_rounded, 'Dropoff', ride['dropoff_address'] ?? 'Unknown location', cs),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money_rounded, size: 20, color: cs.onPrimaryContainer),
                    Text(
                      '${ride['fare_amount'] ?? '0.00'}',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _declinedRideIds.add(ride['id']));
                          _saveDeclinedRides();
                        },
                        child: Text('Decline', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          final auth = context.read<AuthProvider>();
                          if (auth.currentUser == null) return;
                          final rideProv = context.read<RideProvider>();
                          rideProv.acceptRide(rideId: ride['id'], driverId: auth.currentUser!.id).then((success) {
                            if (success && mounted) {
                              context.push('/confirm-arrival');
                            } else if (mounted) {
                              CustomToast.showError(context, rideProv.errorMessage ?? 'Failed to accept ride');
                            }
                          });
                        },
                        child: const Text('Accept Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotifRow(IconData icon, String label, String value, ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: label == 'Pickup' ? cs.primary : const Color(0xFFEF4444)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.sensors_rounded,
                      size: 28,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Assignment Radar Active',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scanning for luxury bookings and VIP client itineraries in your zone...',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(List<Map<String, dynamic>> rides) {
    return RefreshIndicator(
      key: const ValueKey('rides'),
      onRefresh: () async {
        _initCompletedRidesFuture();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          final passengerId = ride['passenger_id'] as String? ?? '';
          return DriverOfferCard(
            passengerName: _passengerNames[passengerId] ?? 'Client',
            passengerCount: ride['passenger_count'] ?? 1,
            pickupAddress: ride['pickup_address'] ?? 'Unknown location',
            dropoffAddress: ride['dropoff_address'] ?? 'Unknown location',
            fare: ride['fare_amount']?.toString() ?? '0.00',
            rideId: ride['id'] ?? '',
            onAccept: () {
              final auth = context.read<AuthProvider>();
              if (auth.currentUser == null) return;
              final rideProv = context.read<RideProvider>();
              rideProv.acceptRide(
                rideId: ride['id'],
                driverId: auth.currentUser!.id,
              ).then((success) {
                if (success && context.mounted) {
                  context.push('/confirm-arrival');
                } else if (context.mounted) {
                  CustomToast.showError(context, rideProv.errorMessage ?? 'Failed to accept ride');
                }
              });
            },
            onDecline: () {
              setState(() => _declinedRideIds.add(ride['id']));
              _saveDeclinedRides();
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final header = GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push('/driver-profile');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _profileImageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(Icons.person, size: 28, color: cs.onSurfaceVariant),
                        errorWidget: (context, url, error) => Icon(Icons.person, size: 28, color: cs.onSurfaceVariant),
                      ),
                    )
                  : Icon(Icons.person, size: 28, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('View Profile', style: tt.labelMedium?.copyWith(color: cs.primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );

    final footer = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: CustomButton(
        title: 'Client mode',
        onPress: () async {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) return;
          try {
            final profile = await ProfileRepository().getPassengerProfile(user.id);
            if (profile == null) {
              if (context.mounted) context.push('/passenger-profile-setup');
            } else {
              if (context.mounted) context.go('/passenger-home');
            }
          } catch (_) {
            if (context.mounted) context.push('/passenger-profile-setup');
          }
        },
        variant: ButtonVariant.primary,
      ),
    );

    return PremiumDrawer(
      isDark: Theme.of(context).brightness == Brightness.dark,
      header: header,
      footer: footer,
      items: [
        DrawerItem(icon: Icons.account_balance_wallet_outlined, title: 'Earnings / Wallet', onTap: () { Navigator.pop(context); context.push('/account'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.history, title: 'Ride History', onTap: () { Navigator.pop(context); context.push('/driver-ride-history'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.directions_car_outlined, title: 'Vehicle Management', onTap: () { Navigator.pop(context); context.push('/vehicle-management'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.verified_user_outlined, title: 'Verification Documents', onTap: () { Navigator.pop(context); context.push('/driver-id-documents'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.star_outline, title: 'Performance & Ratings', onTap: () { Navigator.pop(context); context.push('/driver-performance'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.help_outline, title: 'Support / Help', onTap: () { Navigator.pop(context); context.push('/support'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () { Navigator.pop(context); context.push('/settings'); }, isDark: Theme.of(context).brightness == Brightness.dark),
      ],
    );
  }
}
