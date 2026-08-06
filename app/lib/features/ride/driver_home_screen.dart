import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
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
          });
        }
      } catch (e) {}
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: cs.onSurface, size: 28),
                      onPressed: () {
                        _fetchProfile().ignore();
                        if (mounted) _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: cs.onPrimary,
                          unselectedLabelColor: cs.onSurface,
                          labelStyle: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                          unselectedLabelStyle: tt.labelSmall,
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCompletedTab(),
                    _buildAvailableTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: cs.outline),
                  const SizedBox(height: 16),
                  Text('No completed rides yet', style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
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
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Completed Ride', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text(fare, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLocationDetail(Icons.my_location, cs.tertiary, pickup),
                    Padding(
                      padding: const EdgeInsets.only(left: 9),
                      child: SizedBox(height: 8, child: VerticalDivider(width: 2, thickness: 2, color: cs.outline)),
                    ),
                    _buildLocationDetail(Icons.location_on, cs.error, dropoff),
                  ],
                ),
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
                  width: 32, height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
                ),
                const SizedBox(height: 12),
                Text('Finding available rides...', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
          if (newRides.isNotEmpty && _tabController.index == 1) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_active, size: 48, color: cs.primary),
              const SizedBox(height: 16),
              Text('New Booking Request!', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildNotifRow(Icons.my_location, 'Pickup', ride['pickup_address'] ?? 'Unknown', cs),
              const SizedBox(height: 6),
              _buildNotifRow(Icons.location_on, 'Dropoff', ride['dropoff_address'] ?? 'Unknown', cs),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money, size: 18, color: cs.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      '\$${ride['fare_amount'] ?? '0.00'}',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
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
                        child: Text('Decline', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
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
                        child: const Text('Accept'),
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
        Icon(icon, size: 16, color: label == 'Pickup' ? cs.tertiary : cs.error),
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
            Icon(Icons.airline_seat_recline_normal, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text('No available rides right now', style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('New ride requests will appear here', style: tt.bodySmall?.copyWith(color: cs.outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(List<Map<String, dynamic>> rides) {
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

  Widget _buildLocationDetail(IconData icon, Color iconColor, String address) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(address, style: tt.bodySmall)),
      ],
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
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _profileImageUrl!,
                        width: 50, height: 50, fit: BoxFit.cover,
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
        DrawerItem(icon: Icons.star_outline, title: 'Performance & Ratings', onTap: () { Navigator.pop(context); context.push('/driver-performance'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.help_outline, title: 'Support / Help', onTap: () { Navigator.pop(context); context.push('/support'); }, isDark: Theme.of(context).brightness == Brightness.dark),
        DrawerItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () { Navigator.pop(context); context.push('/settings'); }, isDark: Theme.of(context).brightness == Brightness.dark),
      ],
    );
  }
}
