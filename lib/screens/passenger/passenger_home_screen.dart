import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:klux_vip/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String _userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await ProfileRepository().getPassengerProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _userName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim().toUpperCase();
            if (_userName.isEmpty) _userName = 'PASSENGER';
          });
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // The Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          
          // Menu Button inside a white circle
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu, color: AppColors.black),
              ),
            ),
          ),
          
          // Bottom Sheet / Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFEBE5E4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Location Input
                  GestureDetector(
                    onTap: _showLocationDialog,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Choose pickup and Destination',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Select ride title
                  const Text(
                    'Select ride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Ride options horizontal list
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.directions_car, size: 30, color: AppColors.primary),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Book ride button
                  GestureDetector(
                    onTap: () {
                      context.push('/booking-selection');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Book ride',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.black),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFEBE5E4),
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6D6D6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 40, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.black),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            
            // Menu Items
            _buildDrawerItem(Icons.history, 'Request history', () {}),
            Container(color: AppColors.white, child: _buildDrawerItem(Icons.notifications_none, 'Notifications', () {})),
            _buildDrawerItem(Icons.verified_user_outlined, 'Safety', () {}),
            _buildDrawerItem(Icons.settings_outlined, 'Settings', () {}),
            _buildDrawerItem(Icons.help_outline, 'Support', () {}),
            
            const Spacer(),
            
            // Driver/Affiliate mode button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                title: 'Driver/Affiliate mode',
                onPress: () {
                  // Navigate to Driver Flow
                },
                variant: ButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose pickup and Destination',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
                ),
                const SizedBox(height: 24),
                _buildLocationInput(hint: 'From', icon: Icons.location_on, iconColor: Colors.green),
                const SizedBox(height: 12),
                const Icon(Icons.arrow_downward, color: Colors.black, size: 24),
                const SizedBox(height: 12),
                _buildLocationInput(hint: 'To', icon: Icons.location_on, iconColor: Colors.red),
                const SizedBox(height: 32),
                CustomButton(
                  title: 'Done',
                  onPress: () {
                    Navigator.pop(context);
                  },
                  variant: ButtonVariant.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationInput({required String hint, required IconData icon, required Color iconColor}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
