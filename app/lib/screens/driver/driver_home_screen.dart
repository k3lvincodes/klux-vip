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
            if (_userName.isEmpty) _userName = 'DRIVER';
            _profileImageUrl = profile['profile_image_url'];
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
              .from('passenger_profiles')
              .select('first_name, last_name')
              .eq('user_id', passengerId)
              .maybeSingle();
          if (profile != null && mounted) {
            final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
            setState(() => _passengerNames[passengerId] = name.isNotEmpty ? name : 'Passenger');
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

  // Available Tab
  Widget _buildAvailableTab(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RideRepository().listenToRequestedRides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
        final rides = snapshot.data ?? [];
        if (rides.isNotEmpty) {
          _fetchPassengerNames(rides);
        }
        if (rides.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.airline_seat_recline_normal, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No available rides right now',
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New ride requests will appear here',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              return _buildAvailableRideCard(rides[index], isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildAvailableRideCard(Map<String, dynamic> ride, bool isDark) {
    final pickup = ride['pickup_address'] ?? 'Unknown location';
    final dropoff = ride['dropoff_address'] ?? 'Unknown location';
    final fare = ride['fare_amount'] ?? '0.00';
    final passengerCount = ride['passenger_count'] ?? 1;
    final passengerId = ride['passenger_id'] as String? ?? '';
    final passengerName = _passengerNames[passengerId] ?? 'Passenger';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFF5F0EF),
                child: Icon(Icons.person, size: 24, color: isDark ? AppColors.white : Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '$passengerCount passenger${passengerCount == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$$fare',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Location details
          _buildLocationDetail(Icons.my_location, Colors.green, pickup, isDark),
          const Padding(
            padding: EdgeInsets.only(left: 9),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(width: 2, thickness: 2, color: Colors.grey),
            ),
          ),
          _buildLocationDetail(Icons.location_on, Colors.red, dropoff, isDark),
          const SizedBox(height: 16),
          // Decline / Accept
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer<RideProvider>(
                  builder: (context, rideProv, _) {
                    return ElevatedButton(
                      onPressed: rideProv.isLoading 
                        ? null 
                        : () async {
                            final auth = context.read<AuthProvider>();
                            if (auth.currentUser == null) return;
                            
                            final success = await rideProv.acceptRide(
                              rideId: ride['id'], 
                              driverId: auth.currentUser!.id,
                            );
                            
                            if (success && context.mounted) {
                              context.push('/confirm-arrival');
                            } else if (context.mounted) {
                              CustomToast.showError(context, rideProv.errorMessage ?? 'Failed to accept ride');
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        rideProv.isLoading ? '...' : 'Accept',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ],
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
    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
                context.push('/driver-profile');
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _profileImageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Icon(Icons.person, size: 28, color: Colors.grey),
                                errorWidget: (context, url, error) => Icon(Icons.person, size: 28, color: isDark ? AppColors.white : Colors.black54),
                              ),
                            )
                          : Icon(Icons.person, size: 28, color: isDark ? AppColors.white : Colors.black54),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: isDark ? AppColors.white : AppColors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.account_balance_wallet_outlined, 'Earnings / Wallet', () {
                    context.push('/account');
                  }, isDark),
                  _buildDrawerItem(Icons.history, 'Ride History', () { context.push('/driver-ride-history'); }, isDark),
                  _buildDrawerItem(Icons.directions_car_outlined, 'Vehicle Management', () { context.push('/vehicle-management'); }, isDark),
                  _buildDrawerItem(Icons.star_outline, 'Performance & Ratings', () { context.push('/driver-performance'); }, isDark),
                  _buildDrawerItem(Icons.help_outline, 'Support / Help', () { context.push('/support'); }, isDark),
                  _buildDrawerItem(Icons.settings_outlined, 'Settings', () { context.push('/settings'); }, isDark),
                ],
              ),
            ),
            
            // Passenger/Affiliate mode button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: CustomButton(
                title: 'Passenger mode',
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
                  } catch (e) {
                    if (context.mounted) context.push('/passenger-profile-setup');
                  }
                },
                variant: ButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, bool isDark, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLogout ? Colors.red.withValues(alpha: 0.1) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isLogout ? Colors.red : (isDark ? AppColors.white : AppColors.black), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.red : (isDark ? AppColors.white : AppColors.black),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}


