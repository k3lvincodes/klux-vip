import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/driver_offer_card.dart';
import 'package:kenick_vip/widgets/premium_drawer.dart';
import 'package:kenick_vip/widgets/drawer_item.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _userName = 'Loading...';
  String? _profileImageUrl;
  final Map<String, String> _passengerNames = {};
  final Set<String> _declinedRideIds = {};
  String _lastRideIds = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await ProfileRepository().getDriverProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _userName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim().toUpperCase();
            if (_userName.isEmpty) _userName = 'CHAUFFEUR';
            _profileImageUrl = profile['avatar_url'];
          });
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
  }

  Future<void> _fetchPassengerNames(List<Map<String, dynamic>> rides) async {
    for (final ride in rides) {
      final passengerId = ride['passenger_id'] as String?;
      if (passengerId != null && !_passengerNames.containsKey(passengerId)) {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('first_name, last_name')
              .eq('id', passengerId)
              .maybeSingle();
          if (profile != null && mounted) {
            final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
            setState(() => _passengerNames[passengerId] = name.isNotEmpty ? name : 'Client');
          }
        } catch (_) {}
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, isDark),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Menu icon
                    IconButton(
                      icon: Icon(Icons.menu, color: isDark ? AppColors.white : AppColors.black, size: 28),
                      onPressed: () {
                        _fetchProfile().ignore();
                        if (mounted) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // Tab Bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: AppColors.white,
                          unselectedLabelColor: isDark ? AppColors.white : AppColors.black,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          dividerHeight: 0,
                          tabs: const [
                            Tab(text: 'Completed'),
                            Tab(text: 'Available'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCompletedTab(isDark),
                    _buildAvailableTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Completed Tab
  Widget _buildCompletedTab(bool isDark) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const SizedBox();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: RideRepository().getDriverCompletedRides(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No completed rides yet',
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        final rides = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            final pickup = ride['pickup_address'] ?? 'Unknown location';
            final dropoff = ride['dropoff_address'] ?? 'Unknown location';
            final fare = ride['fare_amount'] ?? '0.00';
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Completed Ride', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$$fare', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLocationDetail(Icons.my_location, Colors.green, pickup, isDark),
                  const Padding(
                    padding: EdgeInsets.only(left: 9),
                    child: SizedBox(height: 8, child: VerticalDivider(width: 2, thickness: 2, color: Colors.grey)),
                  ),
                  _buildLocationDetail(Icons.location_on, Colors.red, dropoff, isDark),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Available Tab
  Widget _buildAvailableTab(bool isDark) {
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Finding available rides...',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
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
                Icon(Icons.cloud_off, size: 48, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No available rides right now',
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        final rides = (snapshot.data ?? []).where((r) => !_declinedRideIds.contains(r['id'])).toList();
        
        final currentRideIds = rides.map((e) => e['id']).join(',');
        if (currentRideIds != _lastRideIds) {
          _lastRideIds = currentRideIds;
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
          child: rides.isEmpty
              ? _buildEmptyState(isDark)
              : _buildRidesList(rides, isDark),
        );
      },
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
            Icon(
              Icons.airline_seat_recline_normal,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No available rides right now',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New ride requests will appear here',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(List<Map<String, dynamic>> rides, bool isDark) {
    return RefreshIndicator(
      key: const ValueKey('rides'),
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
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
                  CustomToast.showError(
                    context,
                    rideProv.errorMessage ?? 'Failed to accept ride',
                  );
                }
              });
            },
            onDecline: () {
              setState(() {
                _declinedRideIds.add(ride['id']);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLocationDetail(IconData icon, Color iconColor, String address, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final header = GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push('/driver-profile');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.grey.shade800 : AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? ClipOval(child: CachedNetworkImage(imageUrl: _profileImageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(Icons.person, size: 28, color: Colors.grey),
                      errorWidget: (context, url, error) => Icon(Icons.person, size: 28, color: isDark ? AppColors.white : Colors.black54),
                    ))
                  : Icon(Icons.person, size: 28, color: isDark ? AppColors.white : Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.black)),
                  const SizedBox(height: 2),
                  Text('View Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? AppColors.white : AppColors.black),
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
      isDark: isDark,
      header: header,
      footer: footer,
      items: [
        DrawerItem(icon: Icons.account_balance_wallet_outlined, title: 'Earnings / Wallet', onTap: () { Navigator.pop(context); context.push('/account'); }, isDark: isDark),
        DrawerItem(icon: Icons.history, title: 'Ride History', onTap: () { Navigator.pop(context); context.push('/driver-ride-history'); }, isDark: isDark),
        DrawerItem(icon: Icons.directions_car_outlined, title: 'Vehicle Management', onTap: () { Navigator.pop(context); context.push('/vehicle-management'); }, isDark: isDark),
        DrawerItem(icon: Icons.star_outline, title: 'Performance & Ratings', onTap: () { Navigator.pop(context); context.push('/driver-performance'); }, isDark: isDark),
        DrawerItem(icon: Icons.help_outline, title: 'Support / Help', onTap: () { Navigator.pop(context); context.push('/support'); }, isDark: isDark),
        DrawerItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () { Navigator.pop(context); context.push('/settings'); }, isDark: isDark),
      ],
    );
  }
}


