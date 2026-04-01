import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/repositories/ride_repository.dart';
import 'package:provider/provider.dart';
import 'package:klux_vip/providers/auth_provider.dart';
import 'package:klux_vip/providers/ride_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0B3), Color(0xFFF3EDEC)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
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
                      icon: const Icon(Icons.menu, color: AppColors.black, size: 28),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    // Tab Bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          labelColor: AppColors.white,
                          unselectedLabelColor: AppColors.black,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
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

  // Completed Tab
  Widget _buildCompletedTab() {
    return const Center(child: Text('No completed rides yet'));
  }

  // Available Tab
  Widget _buildAvailableTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RideRepository().listenToRequestedRides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \${snapshot.error}'));
        }
        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return const Center(child: Text('No available rides right now'));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _buildAvailableRideCard(rides[index]);
          },
        );
      },
    );
  }

  Widget _buildAvailableRideCard(Map<String, dynamic> ride) {
    final pickup = ride['pickup_address'] ?? 'Unknown location';
    final dropoff = ride['dropoff_address'] ?? 'Unknown location';
    final fare = ride['fare_amount'] ?? '0.00';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, size: 30, color: AppColors.black),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'PASSENGER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Location & Fare
          _buildLocationRow(Icons.location_on, Colors.green, 'From', pickup),
          const SizedBox(height: 8),
          _buildLocationRow(Icons.location_on, Colors.red, 'To', dropoff),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated fare',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '\$$fare',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 16),
          // Decline / Accept
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(rideProv.errorMessage ?? 'Failed to accept ride'))
                              );
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
                          fontSize: 14,
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

  Widget _buildLocationRow(
      IconData icon, Color iconColor, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
