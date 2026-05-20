import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/location_search_field.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const LatLng _initialPosition = LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  LatLng _currentPosition = _initialPosition;
  final MapController _mapController = MapController();

  String _userName = 'Loading...';
  String? _profileImageUrl;
  final TextEditingController _dialogFromController = TextEditingController();
  final TextEditingController _dialogToController = TextEditingController();
  LocationSearchResult? _pickupLocation;
  LocationSearchResult? _dropoffLocation;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      // Delay map movement slightly to ensure MapController is attached
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _mapController.move(_currentPosition, 14.5);
        }
      });
    }
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await ProfileRepository().getPassengerProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _userName =
                '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                    .trim()
                    .toUpperCase();
            if (_userName.isEmpty) _userName = 'PASSENGER';
            _profileImageUrl = profile['profile_image_url'];
          });
          debugPrint(
            'Drawer Profile Fetched: $_userName, Image: $_profileImageUrl',
          );
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, isDark),
      body: Stack(
        children: [
          // The Mapbox Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
              children: [
                TileLayer(
                  urlTemplate: isDark
                      ? "https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}"
                      : "https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                  },
                  userAgentPackageName: 'com.kenickvip.app',
                  maxZoom: 22,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
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
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 20,
                        ),
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
            child:
                GestureDetector(
                      onTap: () {
                        _fetchProfile().ignore();
                        if (mounted) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    )
                    .animate()
                    .fade(duration: 500.ms, delay: 300.ms)
                    .slideX(begin: -0.5, end: 0, curve: Curves.easeOut),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.08,
            maxChildSize: 0.42,
            snap: true,
            snapSizes: const [0.08, 0.42],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    // Little drag handle indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Search Location Input
                    GestureDetector(
                      onTap: _showLocationDialog,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF5F0EF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.transparent,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _pickupLocation != null && _dropoffLocation != null
                                    ? '${_pickupLocation!.placeName.split(',').first} -> ${_dropoffLocation!.placeName.split(',').first}'
                                    : 'Choose pickup & destination',
                                style: TextStyle(
                                  color: (_pickupLocation != null && _dropoffLocation != null)
                                      ? (isDark ? AppColors.white : AppColors.black)
                                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Select ride title
                    Text(
                      'Select ride',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ride options horizontal list
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final isSelected = index == 0;
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.darkBackground
                                        : AppColors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.directions_car,
                                size: 28,
                                color: isSelected
                                    ? AppColors.black
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade400),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Book ride button
                    GestureDetector(
                      onTap: () {
                        context.push('/booking-selection');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Book ride',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.black.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.black,
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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
                context.push('/passenger-profile');
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : AppColors.primary.withValues(alpha: 0.3),
                  ),
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
                          ),
                        ],
                      ),
                      child:
                          _profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _profileImageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Icon(Icons.person, size: 28, color: Colors.grey),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: 28,
                                  color: isDark
                                      ? AppColors.white
                                      : Colors.black54,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 28,
                              color: isDark ? AppColors.white : Colors.black54,
                            ),
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
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
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
                  _buildDrawerItem(Icons.history, 'My Rides (History)', () {
                    context.push('/ride-history');
                  }, isDark),
                  _buildDrawerItem(Icons.credit_card, 'Payment Methods', () {
                    context.push('/payment-method');
                  }, isDark),
                  _buildDrawerItem(Icons.bookmark_border, 'Saved Places', () {
                    context.push('/saved-places');
                  }, isDark),
                  _buildDrawerItem(
                    Icons.notifications_none,
                    'Notifications',
                    () {
                      context.push('/notifications');
                    },
                    isDark,
                  ),
                  _buildDrawerItem(Icons.help_outline, 'Support / Help', () {
                    context.push('/support');
                  }, isDark),
                  _buildDrawerItem(Icons.settings_outlined, 'Settings', () {
                    context.push('/settings');
                  }, isDark),
                ],
              ),
            ),

            // Driver/Affiliate mode button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: CustomButton(
                title: 'Driver/Affiliate mode',
                onPress: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;
                  try {
                    final profile = await ProfileRepository().getDriverProfile(
                      user.id,
                    );
                    if (profile == null) {
                      if (context.mounted) {
                        context.push('/driver-profile-setup');
                      }
                    } else if (profile['status'] != 'approved') {
                      if (context.mounted) {
                        context.push('/driver-id-verification');
                      }
                    } else {
                      if (context.mounted) {
                        context.go('/driver-home');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.push('/driver-profile-setup');
                    }
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

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isDark, {
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red.withValues(alpha: 0.1)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isLogout
                ? Colors.red
                : (isDark ? AppColors.white : AppColors.black),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isLogout
                ? Colors.red
                : (isDark ? AppColors.white : AppColors.black),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLocationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _dialogFromController.clear();
    _dialogToController.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Plan your ride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : const Color(0xFFF5F0EF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    Positioned(
                      left: 11,
                      top: 25,
                      bottom: 25,
                      child: Container(
                        width: 2,
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 13.0),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LocationSearchField(
                                hint: 'Current Location',
                                controller: _dialogFromController,
                                isDark: isDark,
                                onSelected: (r) => _pickupLocation = r,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 13.0),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LocationSearchField(
                                hint: 'Where to?',
                                controller: _dialogToController,
                                isDark: isDark,
                                onSelected: (r) => _dropoffLocation = r,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                CustomButton(
                  title: 'Confirm Route',
                  onPress: () {
                    Navigator.pop(context);
                    setState(() {});
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
}
