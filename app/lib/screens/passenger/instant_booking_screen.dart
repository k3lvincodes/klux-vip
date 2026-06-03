import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/location_search_field.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/services/fare_rate_service.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/auth_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:geolocator/geolocator.dart';

class InstantBookingScreen extends StatefulWidget {
  const InstantBookingScreen({super.key});

  @override
  State<InstantBookingScreen> createState() => _InstantBookingScreenState();
}

class _InstantBookingScreenState extends State<InstantBookingScreen> {
  static const LatLng _initialPosition = LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  LatLng _currentPosition = _initialPosition;
  final MapController _mapController = MapController();


  String? _countryCode;

  final TextEditingController _passengersController = TextEditingController(
    text: '1',
  );
  double _perKmRate = 1.85;
  double _baseFare = 3.50;
  double? _calculatedFare;
  double? _distanceKm;
  double _sheetExtent = 0;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  LocationSearchResult? _pickupLocation;
  LocationSearchResult? _dropoffLocation;

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    if (mem.hasMemory && mem.lastPosition != null) {
      _currentPosition = mem.lastPosition!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(mem.lastPosition!, mem.lastZoom);
      });
    }

    final rideProv = context.read<RideProvider>();
    if (rideProv.pickupLocation != null) {
      _pickupLocation = rideProv.pickupLocation;
      _fromController.text = rideProv.pickupLocation!.placeName;
    }
    if (rideProv.dropoffLocation != null) {
      _dropoffLocation = rideProv.dropoffLocation;
      _toController.text = rideProv.dropoffLocation!.placeName;
    }
    if (_pickupLocation != null && _dropoffLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLocationSelected();
      });
    }

    _getCurrentLocation();
  }

  double _initialChildSize(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    double contentH = 0;
    contentH += 40;           // 16 top pad + 24 drag handle
    contentH += 12;           // spacer
    contentH += 64;           // clients
    contentH += 12 + 48;      // spacer + comments
    contentH += 20 + 116;     // spacer + location inputs
    if (_calculatedFare != null) contentH += 24 + 80;
    contentH += 24 + 52 + 8; // spacer + button + spacer
    return ((contentH + bottomPad) / screenH).clamp(0.08, 0.9);
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
        _mapController.move(_currentPosition, 15.0);
      });
      final code = await LocationSearchService.detectCountryCode(
        LatLng(position.latitude, position.longitude),
      );
      if (mounted) setState(() => _countryCode = code);
    }
  }

  @override
  void dispose() {
    MapMemory().save(_currentPosition, _mapController.camera.zoom);
    _fromController.dispose();
    _toController.dispose();
    _commentController.dispose();
    _passengersController.dispose();
    super.dispose();
  }

  Future<void> _handleFindDriver() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      CustomToast.showError(
        context,
        'Please enter pickup and dropoff locations',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();

    if (auth.currentUser == null) {
      CustomToast.showError(context, 'User not authenticated');
      return;
    }

    final success = await rideProvider.requestInstantRide(
      passengerId: auth.currentUser!.id,
      pickupAddress: _fromController.text,
      dropoffAddress: _toController.text,
      pickupLat: _pickupLocation?.latitude,
      pickupLng: _pickupLocation?.longitude,
      dropoffLat: _dropoffLocation?.latitude,
      dropoffLng: _dropoffLocation?.longitude,
      fareAmount: _calculatedFare,
      passengerNote: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
    );

    if (success && mounted) {
      context.push('/trip-summary');
    } else {
      if (mounted) {
        CustomToast.showError(
          context,
          rideProvider.errorMessage ?? 'Failed to request ride',
        );
      }
    }
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

  Future<void> _handleLocationSelected() async {
    if (_pickupLocation != null && _dropoffLocation != null) {
      final km = const Distance().as(
        LengthUnit.Kilometer,
        LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
        LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
      );
      _distanceKm = km;
      final rate = await FareRateService.getRate(_countryCode ?? 'US');
      _perKmRate = rate.perKmRate;
      _baseFare = rate.baseFare;
      _calculatedFare = _baseFare + (km * _perKmRate);
      _sheetExtent = _initialChildSize(context);
      setState(() {});
    }
  }

  Future<void> _showCommentDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          title: Text(
            'Add a note',
            style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
          ),
          content: TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special instructions for the driver?',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
    if (saved == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
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
                    ? "https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}"
                    : "https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                },
                userAgentPackageName: 'com.kenickvip.app',
                maxZoom: 22,
              ),
              MarkerLayer(
                markers: [
                  if (_pickupLocation != null)
                    AnimatedMarker.pickupPin(point: LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude)),
                  if (_dropoffLocation != null)
                    AnimatedMarker.dropoffPin(point: LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude)),
                  if (_pickupLocation == null && _dropoffLocation == null)
                    AnimatedMarker.locationDot(point: _currentPosition, color: AppColors.primary),
                ],
              ),
            ],
          ),

          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
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
                  Icons.arrow_back,
                  size: 18,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
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
                    Icon(Icons.directions_car, size: 16, color: AppColors.primary),
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

          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _sheetExtent = notification.extent;
              return false;
            },
            child: DraggableScrollableSheet(
            initialChildSize: _initialChildSize(context),
            minChildSize: 0.08,
            maxChildSize: _initialChildSize(context),
            snap: true,
            snapSizes: [0.08, _initialChildSize(context)],
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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  children: [
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



                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF5F0EF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: isDark ? AppColors.white : Colors.black87,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Clients',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                              ),
                            ),
                            Container(
                              width: 52,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 10,
                                ),
                                controller: _passengersController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: _showCommentDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFF5F0EF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment,
                                    color: _commentController.text.isNotEmpty
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.white
                                              : Colors.black87),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _commentController.text.isNotEmpty
                                        ? 'Note added'
                                        : 'Comments',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          _commentController.text.isNotEmpty
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _commentController.text.isNotEmpty
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.white
                                                : AppColors.black),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
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
                                      controller: _fromController,
                                      isDark: isDark,
                                      countryCode: _countryCode,
                                      onSelected: (r) {
                                        _pickupLocation = r;
                                        _handleLocationSelected();
                                      },
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
                                      controller: _toController,
                                      isDark: isDark,
                                      countryCode: _countryCode,
                                      onSelected: (r) {
                                        _dropoffLocation = r;
                                        _handleLocationSelected();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_calculatedFare != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFF5F0EF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '\$${_calculatedFare!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      Consumer<RideProvider>(
                        builder: (context, rideProv, child) {
                          return CustomButton(
                            title: rideProv.isLoading
                                ? 'Requesting...'
                                : 'Find a chauffeur',
                            onPress: rideProv.isLoading
                                ? () {}
                                : _handleFindDriver,
                            variant: ButtonVariant.primary,
                          );
                        },
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
}


