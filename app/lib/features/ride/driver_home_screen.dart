import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/app_animations.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/navigation/drawer_item.dart';
import 'package:kenick_vip/widgets/cards/driver_offer_card.dart';
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

  String _userName = 'Loading...';
  String? _profileImageUrl;
  final Map<String, String> _passengerNames = {};
  final Set<String> _fetchedPassengerIds = {};
  final Set<String> _declinedRideIds = {};
  final Set<String> _notifiedRideIds = {};
  String _lastRideIds = '';
  Future<List<Ride>>? _completedRidesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _fetchProfile();
    _loadDeclinedRides();
    _initCompletedRidesFuture();
  }

  void _initCompletedRidesFuture() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _completedRidesFuture = RideRepository().getDriverCompletedRides(user.id);
    }
  }

  Future<void> _loadDeclinedRides() async {
    final prefs = await SharedPreferences.getInstance();
    final declined = prefs.getStringList('declined_ride_ids') ?? [];
    if (mounted) {
      setState(() => _declinedRideIds.addAll(declined));
    }
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
          });
        }
      } catch (e) {
        // Profile fetch failure is non-critical
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
    if (_completedRidesFuture == null) return const SizedBox();

    return FutureBuilder<List<Ride>>(
      future: _completedRidesFuture!,
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
            final pickup = ride.pickupAddress.isNotEmpty ? ride.pickupAddress : 'Unknown location';
            final dropoff = ride.dropoffAddress.isNotEmpty ? ride.dropoffAddress : 'Unknown location';
            final fare = '\$${ride.fareAmount.toStringAsFixed(2)}';
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
                const SizedBox(
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
          if (newRides.isNotEmpty && _tabController.index == 1) {
            _notifiedRideIds.addAll(newRides.map((r) => r['id'] as String));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRideNotification(newRides.first, isDark);
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
          child: rides.isEmpty
              ? _buildEmptyState(isDark)
              : _buildRidesList(rides, isDark),
        );
      },
    );
  }

  void _showRideNotification(Map<String, dynamic> ride, bool isDark) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.notifications_active, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'New Booking Request!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotifRow(Icons.my_location, 'Pickup', ride['pickup_address'] ?? 'Unknown', isDark),
              const SizedBox(height: 6),
              _buildNotifRow(Icons.location_on, 'Dropoff', ride['dropoff_address'] ?? 'Unknown', isDark),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_money, size: 18, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '\$${ride['fare_amount'] ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _declinedRideIds.add(ride['id']));
                          _saveDeclinedRides();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text('Decline', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: const Text('Accept', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
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
        Icon(icon, size: 16, color: label == 'Pickup' ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
              _saveDeclinedRides();
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
                  const Text('View Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
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


