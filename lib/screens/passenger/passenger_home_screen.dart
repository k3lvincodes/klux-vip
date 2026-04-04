import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';
import 'package:klux_vip/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  static const LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);
  final MapController _mapController = MapController();

  String _userName = 'Loading...';
  String? _profileImageUrl;

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
            _profileImageUrl = profile['profile_image_url'];
          });
          debugPrint('Drawer Profile Fetched: $_userName, Image: $_profileImageUrl');
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
          // The Mapbox Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.5,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                },
                userAgentPackageName: 'com.kluxvip.app',
                maxZoom: 22,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _initialPosition,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Menu Button inside a white circle
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () async {
                await _fetchProfile();
                if (mounted) {
                  _scaffoldKey.currentState?.openDrawer();
                }
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
            ).animate().fade(duration: 500.ms, delay: 300.ms).slideX(begin: -0.5, end: 0, curve: Curves.easeOut),
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
                              style: TextStyle(color: Colors.grey, fontSize: 12),
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
                      fontSize: 12,
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.black),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ].animate(interval: 50.ms).fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
              ),
            ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
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
                    child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _profileImageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Image.network failed to load: $error');
                                return const Icon(Icons.person, size: 40, color: Colors.black54);
                              },
                            ),
                          )
                        : const Icon(Icons.person, size: 40, color: Colors.black54),
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
            _buildDrawerItem(Icons.notifications_none, 'Notifications', () {}),
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
          fontSize: 12,
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.black),
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
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: AppColors.white,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
