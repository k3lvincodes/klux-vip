import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/config/env_config.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/drawer_item.dart';
import 'package:kenick_vip/widgets/location_search_field.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/premium_drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const LatLng _initialPosition = LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  LatLng _currentPosition = _initialPosition;
  final MapController _mapController = MapController();

  String _userName = 'Loading...';
  String? _profileImageUrl;
  String? _countryCode;
  final TextEditingController _dialogFromController = TextEditingController();
  final TextEditingController _dialogToController = TextEditingController();
  LocationSearchResult? _pickupLocation;
  LocationSearchResult? _dropoffLocation;
  int? _selectedRideIndex;
  List<LatLng>? _routePoints;
  bool _isRouteLoading = false;
  double? _distanceKm;
  double _sheetExtent = 0;
  late AnimationController _routeAnimController;
  late Animation<double> _routeAnimation;

  @override
  void initState() {
    super.initState();
    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _routeAnimation = CurvedAnimation(
      parent: _routeAnimController,
      curve: Curves.easeInOut,
    );
    _routeAnimController.addListener(() {
      if (mounted) setState(() {});
    });
    final mem = MapMemory();
    if (mem.hasMemory && mem.lastPosition != null) {
      _currentPosition = mem.lastPosition!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(mem.lastPosition!, mem.lastZoom);
      });
    }
    _fetchProfile();
    _getCurrentLocation();
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _formatDuration(double km) {
    final minutes = (km / 30 * 60).round();
    if (minutes < 60) return '$minutes min';
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hrs}h ${mins}min';
  }

  @override
  void dispose() {
    _routeAnimController.dispose();
    MapMemory().save(_currentPosition, _mapController.camera.zoom);
    super.dispose();
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
      final code = await LocationSearchService.detectCountryCode(
        LatLng(position.latitude, position.longitude),
      );
      if (mounted) setState(() => _countryCode = code);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _mapController.move(_currentPosition, 15.0);
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
                profile.displayName.trim().toUpperCase();
            if (_userName.isEmpty) _userName = 'CLIENT';
            _profileImageUrl = profile.avatarUrl;
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
      resizeToAvoidBottomInset: false,
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
                        ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}'
                        : 'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                  additionalOptions: {
                    'accessToken': EnvConfig.mapboxAccessToken,
                  },
                  userAgentPackageName: 'com.kenickvip.app',
                  maxZoom: 22,
                ),
                MarkerLayer(
                  markers: [
                    AnimatedMarker.pulse(
                      point: _currentPosition,
                      color: AppColors.primary,
                    ),
                    AnimatedMarker.locationDot(
                      point: _currentPosition,
                      color: AppColors.primary,
                    ),
                    if (_pickupLocation != null)
                      Marker(
                        point: LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
                        child: const Icon(Icons.location_on, color: Colors.green, size: 30),
                      ),
                    if (_dropoffLocation != null)
                      Marker(
                        point: LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
                        child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                      ),
                  ],
                ),
                if (_routePoints != null && _routePoints!.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints!,
                        color: AppColors.primary.withValues(alpha: 0.2),
                        strokeWidth: 6,
                      ),
                      Polyline(
                        points: _routePoints!.sublist(
                          0,
                          (_routePoints!.length * _routeAnimation.value)
                              .round()
                              .clamp(2, _routePoints!.length),
                        ),
                        color: AppColors.primary,
                        strokeWidth: 6,
                      ),
                    ],
                  ),
                if (_isRouteLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
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

          if (_pickupLocation != null && _dropoffLocation != null && _distanceKm != null)
            Positioned(
              bottom: MediaQuery.of(context).size.height * _sheetExtent + 10,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : const Color(0xFFF5F0EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDistance(_distanceKm!)} · ${_formatDuration(_distanceKm!)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Draggable Bottom Sheet
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _sheetExtent = notification.extent;
              return false;
            },
            child: DraggableScrollableSheet(
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
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedRideIndex == index;
                          final images = [
                            'assets/images/GMC.png',
                            'assets/images/cadillac.png',
                            'assets/images/ford.png',
                            'assets/images/GMC.png',
                          ];
                          final labels = [
                            'GMC Yukon',
                            'Cadillac',
                            'Ford Expedition',
                            'GMC Yukon VIP',
                          ];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRideIndex = index;
                              });
                            },
                            child: Container(
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 4,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        images[index],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      labels[index],
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.white : AppColors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
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
                        context.read<RideProvider>().setPickupDropoff(
                          _pickupLocation,
                          _dropoffLocation,
                        );
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
        ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final header = GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push('/passenger-profile');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : AppColors.primary.withValues(alpha: 0.3),
          ),
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
                  ? ClipOval(child: CachedNetworkImage(
                      imageUrl: _profileImageUrl!, width: 50, height: 50, fit: BoxFit.cover,
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
        title: 'Chauffeur/Affiliate mode',
        onPress: () async {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) return;
          try {
            final profile = await ProfileRepository().getDriverProfile(user.id);
            if (profile == null) {
              if (context.mounted) context.push('/driver-profile-setup');
            } else if (profile.verificationStatus != 'approved') {
              if (context.mounted) context.push('/driver-id-verification');
            } else {
              if (context.mounted) context.go('/driver-home');
            }
          } catch (_) {
            if (context.mounted) context.push('/driver-profile-setup');
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
        DrawerItem(icon: Icons.history, title: 'My Rides (History)', onTap: () { Navigator.pop(context); context.push('/ride-history'); }, isDark: isDark),
        DrawerItem(icon: Icons.bookmark_border, title: 'Saved Places', onTap: () { Navigator.pop(context); context.push('/saved-places'); }, isDark: isDark),
        DrawerItem(icon: Icons.notifications_none, title: 'Notifications', onTap: () { Navigator.pop(context); context.push('/notifications'); }, isDark: isDark),
        DrawerItem(icon: Icons.help_outline, title: 'Support / Help', onTap: () { Navigator.pop(context); context.push('/support'); }, isDark: isDark),
        DrawerItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () { Navigator.pop(context); context.push('/settings'); }, isDark: isDark),
      ],
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
                                countryCode: _countryCode,
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
                                countryCode: _countryCode,
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
                  onPress: () async {
                    final pickup = _pickupLocation;
                    final dropoff = _dropoffLocation;
                    if (pickup != null && dropoff != null) {
                      final pickupLatLng = LatLng(pickup.latitude, pickup.longitude);
                      final dropoffLatLng = LatLng(dropoff.latitude, dropoff.longitude);
                      final km = const Distance().as(
                        LengthUnit.Kilometer,
                        pickupLatLng,
                        dropoffLatLng,
                      );
                      Navigator.pop(context);
                      _routeAnimController.reset();
                      setState(() {
                        _routePoints = null;
                        _distanceKm = km;
                        _sheetExtent = 0.42;
                        _isRouteLoading = true;
                      });
                      final route = await LocationSearchService.getRoute(
                        pickupLatLng,
                        dropoffLatLng,
                      );
                      if (!mounted) return;
                      if (route != null && route.length >= 2) {
                        setState(() {
                          _routePoints = route;
                          _isRouteLoading = false;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _mapController.fitCamera(
                            CameraFit.bounds(
                              bounds: LatLngBounds(
                                LatLng(
                                  pickupLatLng.latitude < dropoffLatLng.latitude
                                      ? pickupLatLng.latitude
                                      : dropoffLatLng.latitude,
                                  pickupLatLng.longitude < dropoffLatLng.longitude
                                      ? pickupLatLng.longitude
                                      : dropoffLatLng.longitude,
                                ),
                                LatLng(
                                  pickupLatLng.latitude > dropoffLatLng.latitude
                                      ? pickupLatLng.latitude
                                      : dropoffLatLng.latitude,
                                  pickupLatLng.longitude > dropoffLatLng.longitude
                                      ? pickupLatLng.longitude
                                      : dropoffLatLng.longitude,
                                ),
                              ),
                              padding: const EdgeInsets.all(60),
                            ),
                          );
                        });
                        _routeAnimController.forward();
                      } else {
                        setState(() {
                          _routePoints = [pickupLatLng, dropoffLatLng];
                          _isRouteLoading = false;
                        });
                        _routeAnimController.forward();
                      }
                    } else {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
