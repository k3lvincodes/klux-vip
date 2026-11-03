import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/cards/driver_offer_card.dart';
import 'package:kenick_vip/widgets/navigation/kenick_navigation_drawer.dart';
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

  String _userName = 'CHAUFFEUR';
  String? _profileImageUrl;
  bool _isOnline = true;
  double _todayEarnings = 0.0;
  int _totalTrips = 0;
  double _rating = 0.0;
  int _ratingCount = 0;
  bool _isAffiliate = false;
  String _organizationName = '';
  String _contactPerson = '';
  int _fleetVehicleCount = 0;

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
      _completedRidesFuture =
          RideRepository().getDriverCompletedRides(user.id).then((rides) {
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
      final role = (user.userMetadata?['role'] as String?)?.toLowerCase();
      final orgName = (user.userMetadata?['organization_name'] as String?) ?? '';
      final isOrg = user.userMetadata?['is_organization'] == true;
      final contact = (user.userMetadata?['contact_person'] as String?) ?? '';
      final bool isAff = role == 'affiliate' || isOrg;

      if (mounted) {
        setState(() {
          _isAffiliate = isAff;
          _organizationName = orgName;
          _contactPerson = contact;
        });
      }

      try {
        final profile = await ProfileRepository().getDriverProfile(user.id);
        if (profile != null && mounted) {
          final d = profile.driverDetails;
          final rc = (d?['rating_count'] as num?)?.toInt() ?? 0;
          final r = (d?['rating'] as num?)?.toDouble() ?? 0.0;
          setState(() {
            if (_isAffiliate && _organizationName.isNotEmpty) {
              _userName = _organizationName;
            } else {
              final name = '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
              _userName = name.isNotEmpty ? name : 'CHAUFFEUR';
            }
            _profileImageUrl = profile.avatarUrl;
            _ratingCount = rc;
            _rating = r;
          });
        }
      } catch (_) {}

      if (_isAffiliate) {
        try {
          final cars = await Supabase.instance.client
              .from('fleet_cars')
              .select('id')
              .eq('organization_id', user.id);
          if (mounted) {
            setState(() {
              _fleetVehicleCount = (cars as List).length;
            });
          }
        } catch (_) {}
      }
    }
  }

  void _toggleOnlineStatus() {
    setState(() => _isOnline = !_isOnline);
    final statusMsg = _isOnline
        ? (_isAffiliate ? 'Fleet activated for dispatches' : 'You are now online and ready for VIP rides')
        : (_isAffiliate ? 'Fleet status set to standby' : 'You are now offline');
    CustomToast.showSuccess(context, statusMsg);
  }

  void _openNavigationDrawer() {
    _fetchProfile().ignore();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          return KenickNavigationDrawer(
            userName: _userName,
            avatarUrl: _profileImageUrl,
            isDark: Theme.of(context).brightness == Brightness.dark,
            isDriver: true,
            isAffiliate: _isAffiliate,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _fetchPassengerNames(List<Map<String, dynamic>> rides) async {
    final newIds = rides
        .map((r) => r['passenger_id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty && !_fetchedPassengerIds.contains(id))
        .toSet();

    if (newIds.isEmpty) return;
    _fetchedPassengerIds.addAll(newIds);

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, first_name, last_name')
          .filter('id', 'in', newIds.toList());

      if (mounted) {
        for (final row in (res as List)) {
          final id = row['id'] as String;
          final first = row['first_name'] as String? ?? '';
          final last = row['last_name'] as String? ?? '';
          final name = '$first $last'.trim();
          _passengerNames[id] = name.isNotEmpty ? name : 'VIP Client';
        }
        for (final id in newIds) {
          _passengerNames.putIfAbsent(id, () => 'VIP Client');
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        for (final id in newIds) {
          _passengerNames[id] = 'VIP Client';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Executive Top Bar
            _buildTopBar(cs, isDark),

            // 2. Performance Metrics Card (Two-Tier Stage Blueprint)
            _buildMetricsCard(cs, isDark),

            const SizedBox(height: 12),

            // 3. Segmented Tab Selector (Section 2.3)
            _buildSegmentedTabSelector(cs, isDark),

            const SizedBox(height: 8),

            // 4. Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableTab(isDark),
                  _buildCompletedTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, bool isDark) {
    final statusText = _isAffiliate
        ? (_isOnline ? 'FLEET ACTIVE' : 'FLEET STANDBY')
        : (_isOnline ? 'ONLINE' : 'OFFLINE');

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          // Drawer menu icon button (42x42 tap target)
          GestureDetector(
            onTap: _openNavigationDrawer,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2026) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE4E4E7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.menu_rounded,
                color: isDark ? Colors.white : const Color(0xFF18181B),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Identity (Chauffeur or Affiliate Organization)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAffiliate) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_outlined, size: 10, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'AFFILIATE PARTNER',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_isAffiliate && _contactPerson.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      'Rep: $_contactPerson',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Online / Offline / Fleet Active Toggle Pill
          GestureDetector(
            onTap: _toggleOnlineStatus,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _isOnline
                    ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1E2026) : const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isOnline
                      ? const Color(0xFF22C55E).withValues(alpha: 0.45)
                      : (isDark ? const Color(0xFF27272A) : const Color(0xFFD4D4D8)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.5,
                    height: 7.5,
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
                  const SizedBox(width: 7),
                  Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isOnline
                          ? const Color(0xFF22C55E)
                          : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A)),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Notifications Button (42x42)
          GestureDetector(
            onTap: () => context.push('/driver-notifications'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2026) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE4E4E7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                    size: 21,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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

  Widget _buildMetricsCard(ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2026) : const Color(0xFFE4E4E7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? const Color(0xFF27272A)
              : const Color(0xFFD4D4D8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121316) : Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              // 1. Revenue
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/account'),
                  behavior: HitTestBehavior.opaque,
                  child: _buildMetricItem(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.primary,
                    label: _isAffiliate ? 'Fleet Revenue' : "Today's Fare",
                    value: '\$${_todayEarnings.toStringAsFixed(2)}',
                    isDark: isDark,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              ),
              // 2. Completed Trips / Bookings
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/driver-ride-history'),
                  behavior: HitTestBehavior.opaque,
                  child: _buildMetricItem(
                    icon: Icons.directions_car_filled_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    label: _isAffiliate ? 'Fleet Bookings' : 'Trips Logged',
                    value: '$_totalTrips',
                    isDark: isDark,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              ),
              // 3. Rating or Fleet Vehicles
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(_isAffiliate ? '/vehicle-management' : '/driver-performance'),
                  behavior: HitTestBehavior.opaque,
                  child: _buildMetricItem(
                    icon: _isAffiliate ? Icons.directions_car_outlined : Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: _isAffiliate ? 'Vehicles' : 'Rating',
                    value: _isAffiliate
                        ? (_fleetVehicleCount > 0 ? '$_fleetVehicleCount' : 'Active')
                        : ((_ratingCount > 0 && _rating > 0) ? '${_rating.toStringAsFixed(1)} ★' : '--'),
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF18181B),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabSelector(ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 46,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2026) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFD4D4D8),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        dividerHeight: 0.0,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF111827),
        unselectedLabelColor: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_rounded, size: 16),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    _isAffiliate
                        ? (_isOnline ? 'Fleet Dispatch' : 'Fleet (Inactive)')
                        : (_isOnline ? 'Assignments Radar' : 'Radar (Inactive)'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 16),
                SizedBox(width: 7),
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

  Widget _buildCompletedTab(bool isDark) {
    if (_completedRidesFuture == null) return const SizedBox();

    return FutureBuilder<List<Ride>>(
      future: _completedRidesFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
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
                      color: isDark ? const Color(0xFF1E2026) : const Color(0xFFE5E7EB),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 36,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Completed Trips Yet',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your finished luxury itineraries will be logged here with complete revenue details.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final rides = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
          itemCount: rides.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ride = rides[index];
            final pickup = ride.pickupAddress.isNotEmpty ? ride.pickupAddress : 'Pickup Location';
            final dropoff = ride.dropoffAddress.isNotEmpty ? ride.dropoffAddress : 'Dropoff Location';
            final fare = '\$${ride.fareAmount.toStringAsFixed(2)}';
            final dateStr = DateFormat('MMM d, h:mm a').format(ride.createdAt);

            return Container(
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
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF22C55E)),
                            const SizedBox(width: 5),
                            Text(
                              'Completed',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fare,
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
                          maxLines: 2,
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
                          maxLines: 2,
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
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                        ),
                      ),
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
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableTab(bool isDark) {
    if (!_isOnline) {
      return _buildInactiveRadarState(isDark);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RideRepository().listenToRequestedRides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
                const SizedBox(height: 14),
                Text(
                  'Connecting to assignment radar...',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                  ),
                ),
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
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
                const SizedBox(height: 12),
                Text(
                  'No available rides right now',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF18181B),
                  ),
                ),
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
          child: rides.isEmpty ? _buildEmptyState(isDark) : _buildRidesList(rides),
        );
      },
    );
  }

  void _showRideNotification(Map<String, dynamic> ride) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, size: 28, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'New Executive Assignment!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A VIP booking has been matched to your vehicle',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 18),
              _buildNotifRow(Icons.my_location_rounded, 'Pickup', ride['pickup_address'] ?? 'Unknown location', isDark),
              const SizedBox(height: 10),
              _buildNotifRow(Icons.location_on_rounded, 'Dropoff', ride['dropoff_address'] ?? 'Unknown location', isDark),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${ride['fare_amount'] ?? '0.00'}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _declinedRideIds.add(ride['id']));
                          _saveDeclinedRides();
                        },
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
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF111827),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
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
                        child: Text(
                          'Accept Trip',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: const Color(0xFF111827),
                          ),
                        ),
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

  Widget _buildNotifRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: label == 'Pickup' ? AppColors.primary : const Color(0xFFEF4444)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $value',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF18181B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveRadarState(bool isDark) {
    final textMuted = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Center(
      key: const ValueKey('inactive_radar'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Inactive Radar Icon Container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E2026) : const Color(0xFFEFEFEF),
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF16181D) : const Color(0xFFE4E4E7),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.sensors_off_rounded,
                      size: 30,
                      color: textMuted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Inactive Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'RADAR INACTIVE',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              _isAffiliate ? 'Fleet Dispatch Inactive' : 'Assignment Radar Inactive',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF18181B),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              _isAffiliate
                  ? 'Your fleet is currently offline and not receiving VIP assignments. Go online to activate live dispatching.'
                  : 'You are currently offline. Go online to activate the assignment radar and receive incoming VIP booking offers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),

            // Signature Gold Pill CTA: Go Online
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _toggleOnlineStatus,
                icon: const Icon(
                  Icons.power_settings_new_rounded,
                  size: 18,
                  color: Color(0xFF111827),
                ),
                label: Text(
                  'Go Online',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF111827),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sensors_rounded,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _isAffiliate ? 'Fleet Dispatch Active' : 'Assignment Radar Active',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF18181B),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isAffiliate
                  ? 'Scanning for luxury corporate bookings and VIP itineraries for your fleet...'
                  : 'Scanning for luxury bookings and VIP client itineraries in your zone...',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                height: 1.45,
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
      color: AppColors.primary,
      onRefresh: () async {
        _initCompletedRidesFuture();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          final passengerId = ride['passenger_id'] as String? ?? '';
          return DriverOfferCard(
            passengerName: _passengerNames[passengerId] ?? 'VIP Client',
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
}
