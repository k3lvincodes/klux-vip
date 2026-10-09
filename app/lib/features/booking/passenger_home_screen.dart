import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/profile_repository.dart';
import 'package:kenick_vip/services/currency_service.dart';
import 'package:kenick_vip/services/fare_rate_service.dart';
import 'package:kenick_vip/services/fleet_service.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/inputs/location_search_field.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/vip_google_map.dart';
import 'package:kenick_vip/widgets/navigation/kenick_navigation_drawer.dart';
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
  final GlobalKey<VipGoogleMapState> _mapKey = GlobalKey<VipGoogleMapState>();

  String _userName = '';
  String? _profileImageUrl;
  String? _countryCode;
  final TextEditingController _dialogFromController = TextEditingController();
  final TextEditingController _dialogToController = TextEditingController();
  LocationSearchResult? _pickupLocation;
  LocationSearchResult? _dropoffLocation;
  List<LatLng>? _routePoints;
  double? _distanceKm;
  double? _durationSeconds;
  double _sheetExtent = 0;
  late AnimationController _routeAnimController;
  late AnimationController _pageTransitionController;
  late Animation<Offset> _discoverySlideAnimation;
  final ScrollController _discoveryScrollController = ScrollController();

  FleetVehicleItem? _selectedVehicle;
  String _bookingMode = 'instant'; // 'instant', 'schedule', 'special'
  double? _estimatedFare;
  bool _isDispatching = false;

  // Track if user is in route/dispatch view vs hero cover view
  bool _showDispatchView = false;

  String get _displayName {
    if (_userName.isNotEmpty) {
      final first = _userName.trim().split(' ').first;
      if (first.isNotEmpty) {
        return '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
      }
    }
    final user = Supabase.instance.client.auth.currentUser;
    final metaName = user?.userMetadata?['first_name'] as String? ??
        user?.userMetadata?['name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) {
      final first = metaName.trim().split(' ').first;
      return '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
    }
    return 'Kelvin';
  }

  @override
  void initState() {
    super.initState();
    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _routeAnimController.addListener(() {
      if (mounted) setState(() {});
    });

    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _discoverySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _pageTransitionController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (_discoveryScrollController.hasClients &&
            _discoveryScrollController.offset > 0) {
          _discoveryScrollController.jumpTo(0);
        }
      }
    });

    final mem = MapMemory();
    if (mem.hasMemory && mem.lastPosition != null) {
      _currentPosition = mem.lastPosition!;
    }
    _fetchProfile();
    _getCurrentLocation();

    final bookingProv = context.read<BookingProvider>();
    if (bookingProv.vehicleType.isNotEmpty &&
        bookingProv.vehicleType != 'GMC Yukon') {
      _selectedVehicle = FleetVehicleItem(
        id: 'selected',
        name: bookingProv.vehicleType,
        make: 'VIP',
        model: 'Fleet',
        year: 2024,
        localAssetPath: bookingProv.vehicleImage ?? 'assets/images/GMC.png',
        imageUrl: bookingProv.vehicleImage?.startsWith('http') == true
            ? bookingProv.vehicleImage
            : null,
        hasDriverAssigned: true,
      );
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.read<RideProvider>().restoreActiveRide(user.id).ignore();
    }
  }

  Future<void> _recalculateFare() async {
    if (_distanceKm == null) return;
    try {
      final country = _countryCode ?? 'US';
      final rate = await FareRateService.getRate(country);
      final minutes =
          (_durationSeconds ?? (_distanceKm! / 40.0 * 3600)) / 60.0;
      double base = rate.baseFare +
          (_distanceKm! * rate.perKmRate) +
          (minutes * rate.perMinuteRate);
      if (_bookingMode == 'special') {
        base += country == 'NG' ? 10000.0 : 50.0;
      }
      if (mounted) {
        setState(() {
          _estimatedFare = base;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_countryCode == 'NG') {
            _estimatedFare = 1500.0 + (_distanceKm! * 250.0);
          } else {
            _estimatedFare = 25.0 + (_distanceKm! * 2.5);
          }
        });
      }
    }
  }

  Widget _buildModeTab(String mode, String label, ColorScheme cs,
      {IconData? icon}) {
    final isSelected = _bookingMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _bookingMode = mode);
          _recalculateFare();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleInstantDispatch(FleetVehicleItem selectedVehicle) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }

    setState(() => _isDispatching = true);
    final bookingProv = context.read<BookingProvider>();
    bookingProv.setRoutePoints(_routePoints);
    MapMemory().save(_currentPosition, 15.0);
    bookingProv.setVehicle(
      selectedVehicle.name,
      selectedVehicle.imageUrl ?? selectedVehicle.localAssetPath,
    );
    final note = selectedVehicle.id == 'any_vip'
        ? 'Any VIP Vehicle (Fastest Pickup)'
        : 'Requested VIP vehicle: ${selectedVehicle.name}';
    bookingProv.setTripDetails(
      pickupAddress: _pickupLocation!.placeName,
      dropoffAddress: _dropoffLocation!.placeName,
      pickupLat: _pickupLocation!.latitude,
      pickupLng: _pickupLocation!.longitude,
      dropoffLat: _dropoffLocation!.latitude,
      dropoffLng: _dropoffLocation!.longitude,
      passengerNote: note,
    );
    if (_estimatedFare != null) {
      bookingProv.setFare(_estimatedFare!, _distanceKm);
    }
    bookingProv.setBookingType('instant');

    final rideProv = context.read<RideProvider>();
    try {
      final success = await rideProv.requestInstantRide(
        passengerId: user.id,
        pickupAddress: _pickupLocation!.placeName,
        dropoffAddress: _dropoffLocation!.placeName,
        pickupLat: _pickupLocation!.latitude,
        pickupLng: _pickupLocation!.longitude,
        dropoffLat: _dropoffLocation!.latitude,
        dropoffLng: _dropoffLocation!.longitude,
        fareAmount: _estimatedFare ?? 50.0,
        passengerNote: note,
      );

      if (!mounted) return;
      if (success) {
        context.push('/trip-summary');
      } else {
        final err = rideProv.errorMessage ?? 'Failed to dispatch';
        CustomToast.showError(context, err);
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Dispatch error: $e');
    } finally {
      if (mounted) setState(() => _isDispatching = false);
    }
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _formatDuration() {
    if (_durationSeconds == null) return '';
    final minutes = (_durationSeconds! / 60).round();
    if (minutes < 60) return '$minutes min';
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hrs}h ${mins}min';
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    _discoveryScrollController.dispose();
    _routeAnimController.dispose();
    _dialogFromController.dispose();
    _dialogToController.dispose();
    MapMemory().save(_currentPosition, 15.0);
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
          _mapKey.currentState?.animateTo(_currentPosition, 15.0);
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
            _userName = profile.displayName.trim();
            _profileImageUrl = profile.avatarUrl;
          });
        }
      } catch (e) {
        // Fallback
      }
    }
  }

  void _openNavigationMenu() {
    _fetchProfile().ignore();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          return KenickNavigationDrawer(
            userName: _displayName,
            avatarUrl: _profileImageUrl,
            isDark: Theme.of(context).brightness == Brightness.dark,
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
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildDiscoveryScreen(BuildContext context, bool isDark) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Pull down bar & Top Header in unified drag gesture detector
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null) {
                  _pageTransitionController.value = (_pageTransitionController.value -
                          details.primaryDelta! / MediaQuery.of(context).size.height)
                      .clamp(0.0, 1.0);
                }
              },
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 250 || _pageTransitionController.value < 0.75) {
                  _pageTransitionController.reverse();
                } else {
                  _pageTransitionController.forward();
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome, $_displayName',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openNavigationMenu,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.menu_rounded,
                          color: cs.onSurface,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (notification.metrics.pixels < -15 &&
                        (notification.scrollDelta ?? 0) <= 0) {
                      if (!_pageTransitionController.isAnimating &&
                          _pageTransitionController.value > 0) {
                        _pageTransitionController.reverse();
                      }
                      return true;
                    }
                  } else if (notification is OverscrollNotification) {
                    if (notification.overscroll < -8) {
                      if (!_pageTransitionController.isAnimating &&
                          _pageTransitionController.value > 0) {
                        _pageTransitionController.reverse();
                      }
                      return true;
                    }
                  } else if (notification is ScrollEndNotification) {
                    if (notification.metrics.pixels < -8) {
                      if (!_pageTransitionController.isAnimating &&
                          _pageTransitionController.value > 0) {
                        _pageTransitionController.reverse();
                      }
                      return true;
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _discoveryScrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Recommended for you
                      Text(
                        'Recommended for you',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Feature Card: Pick up where you left off
                      _buildPickupCard(context, isDark),

                      const SizedBox(height: 28),

                      // Section 2: Ride types
                      Text(
                        'Ride types',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2x2 Grid of Ride Types
                      _buildRideTypesGrid(context, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupCard(BuildContext context, bool isDark) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2026) : const Color(0xFFD6DBE1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.9)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top space (car removed, height increased)
          const SizedBox(height: 195),

          // Bottom Dark Overlay Content with padding to left, right, and bottom of the box
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121316) : const Color(0xFF16181D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick up where you left off',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You started to explore a booking, then paused before adding your destination. Simply set where you're going and let us shape the ride from there.",
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _showLocationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF111827),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.center,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Start a booking',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            height: 1.15,
                          ),
                        ),
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

  Widget _buildRideTypesGrid(BuildContext context, bool isDark) {
    final items = [
      {
        'title': 'Airport transfers',
        'imageUrl':
            'https://images.unsplash.com/photo-1542296332-2e4473faf563?w=500&auto=format&fit=crop&q=80',
        'mode': 'schedule',
        'icon': Icons.flight_takeoff_rounded,
      },
      {
        'title': 'Hourly & full day\nhire',
        'imageUrl':
            'https://images.unsplash.com/photo-1508974239320-0a029497e820?w=500&auto=format&fit=crop&q=80',
        'mode': 'schedule',
        'icon': Icons.access_time_rounded,
      },
      {
        'title': 'City-to-City\nrides',
        'imageUrl':
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=500&auto=format&fit=crop&q=80',
        'mode': 'instant',
        'icon': Icons.location_city_rounded,
      },
      {
        'title': 'Corporate rides',
        'imageUrl':
            'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=500&auto=format&fit=crop&q=80',
        'mode': 'special',
        'icon': Icons.business_center_rounded,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            setState(() => _bookingMode = item['mode'] as String);
            _showLocationDialog();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Photo
                CachedNetworkImage(
                  imageUrl: item['imageUrl'] as String,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? const Color(0xFF1E2026)
                        : const Color(0xFFD6DBE1),
                    child: Center(
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.white38,
                        size: 32,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark
                        ? const Color(0xFF1E2026)
                        : const Color(0xFFD6DBE1),
                    child: Center(
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.white38,
                        size: 32,
                      ),
                    ),
                  ),
                ),

                // Dark Contrast Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),

                // Title Overlay at bottom-left
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Text(
                    item['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _pageTransitionController.value == 0 && !_showDispatchView,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showDispatchView) {
          setState(() => _showDispatchView = false);
        } else if (_pageTransitionController.value > 0) {
          _pageTransitionController.reverse();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background: Hero photo when in cover mode, or live map when dispatching
          if (_showDispatchView && _routePoints != null) ...[
            VipGoogleMap(
              key: _mapKey,
              initialCenter: _currentPosition,
              initialZoom: 14.5,
              pickupPosition: _pickupLocation != null
                  ? LatLng(
                      _pickupLocation!.latitude, _pickupLocation!.longitude)
                  : null,
              dropoffPosition: _dropoffLocation != null
                  ? LatLng(
                      _dropoffLocation!.latitude, _dropoffLocation!.longitude)
                  : null,
              routePoints: _routePoints,
              myLocationEnabled: true,
              padding: const EdgeInsets.only(bottom: 280, top: 80),
            ),
            // Floating Return to Cover button
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () => setState(() => _showDispatchView = false),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: cs.onSurface),
                ),
              ),
            ),
          ] else ...[
            // Cover Hero Screen with swipe up gesture detection
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < 0) {
                    _pageTransitionController.value -=
                        details.primaryDelta! / MediaQuery.of(context).size.height;
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < -250 ||
                      _pageTransitionController.value > 0.2) {
                    _pageTransitionController.forward();
                  } else {
                    _pageTransitionController.reverse();
                  }
                },
                child: Stack(
                  children: [
                    // Full-Screen Luxury Hero Photo with dark tint
                    Positioned.fill(
                      child: Image.asset(
                'assets/images/passenger_hero.jpg',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.28),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF16161A),
                  child: Center(
                    child: Icon(
                      Icons.directions_car_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Top Gradient Overlay (for status bar & header legibility)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Gradient Overlay (for editorial typography & input legibility)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 480,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.35, 0.7, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.82),
                      Colors.black.withValues(alpha: 0.96),
                    ],
                  ),
                ),
              ),
            ),

            // Header Top Bar
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome, $_displayName',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _openNavigationMenu,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 30,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Active Ride Floating Banner (if ongoing ride exists)
            Consumer<RideProvider>(
              builder: (context, rp, child) {
                final ride = rp.currentRide;
                if (ride != null &&
                    ride.status != 'completed' &&
                    ride.status != 'cancelled') {
                  final isPendingSearch = ride.status == 'pending' ||
                      ride.status == 'requested' ||
                      ride.status == 'searching';
                  final bannerTitle = isPendingSearch
                      ? 'Chauffeur Search in Progress'
                      : (ride.status == 'arrived' || ride.status == 'accepted'
                          ? 'Chauffeur is Arriving'
                          : 'Active VIP Trip in Progress');
                  final bannerSubtitle = isPendingSearch
                      ? 'Locating nearest VIP chauffeur · Tap to track'
                      : 'Status: ${ride.status.toUpperCase()} · Tap to track';

                  return Positioned(
                    top: 104,
                    left: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => context.push('/trip-summary'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPendingSearch
                                    ? Icons.radar
                                    : Icons.directions_car,
                                color: cs.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    bannerTitle,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    bannerSubtitle,
                                    style: GoogleFonts.poppins(
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: cs.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Hero Bottom Section (Headline, Destination line, Explore services)
            Positioned(
              left: 24,
              right: 24,
              bottom: 125,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kenick Luxury Headline (Semi-Bold Weight)
                  Text(
                    'The Ride\nYou Deserve',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.18,
                      letterSpacing: -0.3,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 14,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Destination Input Line
                  GestureDetector(
                    onTap: _showLocationDialog,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _dropoffLocation != null
                                    ? _dropoffLocation!.placeName
                                    : 'Enter your destination',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  letterSpacing: 0.1,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1.5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.35),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Explore rides & services Trigger
                  GestureDetector(
                    onTap: () => _pageTransitionController.forward(),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explore rides & services',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),

    // Discovery Screen sliding up from bottom
    Positioned.fill(
      child: SlideTransition(
        position: _discoverySlideAnimation,
        child: _buildDiscoveryScreen(context, isDark),
      ),
    ),
  ],

          // If in dispatch view with a route selected, display the dispatch bottom sheet
          if (_showDispatchView && _routePoints != null)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if ((_sheetExtent - notification.extent).abs() > 0.002) {
                  setState(() => _sheetExtent = notification.extent);
                }
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.48,
                minChildSize: 0.12,
                maxChildSize: 0.52,
                snap: true,
                snapSizes: const [0.12, 0.48],
                builder: (sheetContext, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showLocationDialog,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.search,
                                      color: cs.primary, size: 16),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _pickupLocation != null &&
                                            _dropoffLocation != null
                                        ? '${_pickupLocation!.placeName.split(',').first} -> ${_dropoffLocation!.placeName.split(',').first}'
                                        : 'Choose pickup & destination',
                                    style: TextStyle(
                                      color: (_pickupLocation != null &&
                                              _dropoffLocation != null)
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Segmented Mode Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildModeTab('instant', 'Instant Booking', cs,
                                  icon: Icons.flash_on_rounded),
                              _buildModeTab('schedule', 'Schedule', cs,
                                  icon: Icons.calendar_today_rounded),
                              _buildModeTab('special', 'Special Event', cs,
                                  icon: Icons.stars_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chauffeur Vehicle',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                if (_distanceKm != null)
                                  Text(
                                    '${_formatDistance(_distanceKm!)}${_durationSeconds != null ? ' · ${_formatDuration()}' : ''}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            if (_estimatedFare != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Est. ${CurrencyService.format(_estimatedFare, countryCode: _countryCode)}',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Select Car Card
                        GestureDetector(
                          onTap: () async {
                            final result =
                                await context.push<FleetVehicleItem?>(
                                    '/fleet-selection');
                            if (result != null && mounted) {
                              setState(() {
                                _selectedVehicle = result;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _selectedVehicle?.imageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                _selectedVehicle!.imageUrl!,
                                            fit: BoxFit.contain,
                                            errorWidget:
                                                (context, url, error) =>
                                                    Image.asset(
                                              _selectedVehicle
                                                      ?.localAssetPath ??
                                                  'assets/images/GMC.png',
                                              fit: BoxFit.contain,
                                            ),
                                          )
                                        : Image.asset(
                                            _selectedVehicle?.localAssetPath ??
                                                'assets/images/GMC.png',
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedVehicle?.name ??
                                            'Any VIP Vehicle',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _selectedVehicle != null
                                            ? 'Chauffeur Ready • Tap to change'
                                            : 'Tap to view fleet & select vehicle',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedVehicle != null
                                        ? 'Change'
                                        : 'Select',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (_pickupLocation != null &&
                                    _dropoffLocation != null &&
                                    !_isDispatching)
                                ? () async {
                                    final selectedVehicle = _selectedVehicle ??
                                        FleetVehicleItem(
                                          id: 'any_vip',
                                          name: 'Any VIP Vehicle',
                                          make: 'VIP',
                                          model: 'Fleet',
                                          year: 2024,
                                          localAssetPath:
                                              'assets/images/GMC.png',
                                          hasDriverAssigned: true,
                                        );

                                    final bookingProv =
                                        context.read<BookingProvider>();
                                    bookingProv.setRoutePoints(_routePoints);
                                    MapMemory().save(_currentPosition, 15.0);
                                    bookingProv.setVehicle(
                                      selectedVehicle.name,
                                      selectedVehicle.imageUrl ??
                                          selectedVehicle.localAssetPath,
                                    );
                                    final note = selectedVehicle.id == 'any_vip'
                                        ? 'Any VIP Vehicle (Fastest Pickup)'
                                        : 'Requested VIP vehicle: ${selectedVehicle.name}';
                                    bookingProv.setTripDetails(
                                      pickupAddress: _pickupLocation!.placeName,
                                      dropoffAddress:
                                          _dropoffLocation!.placeName,
                                      pickupLat: _pickupLocation!.latitude,
                                      pickupLng: _pickupLocation!.longitude,
                                      dropoffLat: _dropoffLocation!.latitude,
                                      dropoffLng: _dropoffLocation!.longitude,
                                      passengerNote: note,
                                    );
                                    if (_estimatedFare != null) {
                                      bookingProv.setFare(
                                          _estimatedFare!, _distanceKm);
                                    }

                                    if (_bookingMode == 'schedule') {
                                      bookingProv.setBookingType('schedule');
                                      context.push('/schedule-booking');
                                      return;
                                    }

                                    if (_bookingMode == 'special') {
                                      bookingProv.setBookingType('special');
                                      context.push('/special-booking');
                                      return;
                                    }

                                    await _handleInstantDispatch(
                                        selectedVehicle);
                                  }
                                : null,
                            child: _isDispatching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _bookingMode == 'instant'
                                            ? 'Request Instant Chauffeur${_estimatedFare != null ? ' · ${CurrencyService.format(_estimatedFare, countryCode: _countryCode)}' : ''}'
                                            : _bookingMode == 'schedule'
                                                ? 'Configure Schedule Time'
                                                : 'Configure Special Event',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 12),
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

          // Floating Bottom Navigation Bar + Circular Quick-Book Car FAB
          if (!_showDispatchView)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Row(
                    children: [
                      // Navigation Pill
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface.withValues(alpha: 0.96)
                                : Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSurface.withValues(alpha: 0.9)
                                  : AppColors.softYellow.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.35 : 0.16),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Tab 1: Home
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_pageTransitionController.value > 0) {
                                        _pageTransitionController.reverse();
                                      }
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.08)
                                              : AppColors.softYellow
                                                  .withValues(alpha: 0.07),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const FaIcon(
                                              FontAwesomeIcons.house,
                                              size: 21,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Home',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Tab 2: Rides
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.push('/ride-history'),
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons.route,
                                              size: 21,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Rides',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Tab 3: Help
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.push('/support'),
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.help_outline_rounded,
                                              size: 24,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Help',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Circular Car Quick-Book FAB (Only shown when swiped up into 2nd screen)
                      AnimatedBuilder(
                        animation: _pageTransitionController,
                        builder: (context, child) {
                          final t = CurvedAnimation(
                            parent: _pageTransitionController,
                            curve: Curves.easeOutCubic,
                          ).value;
                          if (t <= 0.01) return const SizedBox.shrink();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 10 * t),
                              Transform.scale(
                                scale: (0.5 + 0.5 * t).clamp(0.0, 1.0),
                                child: Opacity(
                                  opacity: t.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              ),
                            ],
                          );
                        },
                        child: GestureDetector(
                          onTap: _showLocationDialog,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: Color(0xFF111827),
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  void _showLocationDialog() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    _dialogFromController.text = _pickupLocation?.placeName ?? '';
    _dialogToController.text = _dropoffLocation?.placeName ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Plan your ride',
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
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
                      child: Container(width: 2, color: cs.outlineVariant),
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
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.my_location,
                                    size: 12, color: cs.onPrimaryContainer),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LocationSearchField(
                                hint: 'Current Location',
                                controller: _dialogFromController,
                                isDark: Theme.of(context).brightness ==
                                    Brightness.dark,
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
                                  color: cs.errorContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on,
                                    size: 12, color: cs.onErrorContainer),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LocationSearchField(
                                hint: 'Where to?',
                                controller: _dialogToController,
                                isDark: Theme.of(context).brightness ==
                                    Brightness.dark,
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
                    final bookingProv = context.read<BookingProvider>();
                    final pickup = _pickupLocation;
                    final dropoff = _dropoffLocation;
                    if (pickup != null && dropoff != null) {
                      final pickupLatLng =
                          LatLng(pickup.latitude, pickup.longitude);
                      final dropoffLatLng =
                          LatLng(dropoff.latitude, dropoff.longitude);
                      Navigator.pop(context);
                      _routeAnimController.reset();
                      setState(() {
                        _routePoints = null;
                        _distanceKm = null;
                        _durationSeconds = null;
                        _sheetExtent = 0.48;
                        _showDispatchView = true;
                      });

                      final routeResult = await LocationSearchService.getRoute(
                          pickupLatLng, dropoffLatLng);
                      if (!mounted) return;
                      if (routeResult != null &&
                          routeResult.points.length >= 2) {
                        setState(() {
                          _routePoints = routeResult.points;
                          _distanceKm = routeResult.distanceKm;
                          _durationSeconds = routeResult.durationSeconds;
                        });
                        bookingProv.setRoutePoints(routeResult.points);
                        _recalculateFare();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _mapKey.currentState?.fitRouteBounds();
                        });
                        _routeAnimController.forward();
                      } else {
                        setState(() {
                          _routePoints = [pickupLatLng, dropoffLatLng];
                          _distanceKm = const Distance().as(
                              LengthUnit.Kilometer, pickupLatLng, dropoffLatLng);
                          _durationSeconds = null;
                        });
                        bookingProv
                            .setRoutePoints([pickupLatLng, dropoffLatLng]);
                        _recalculateFare();
                        _routeAnimController.forward();
                      }
                    } else {
                      Navigator.pop(context);
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
