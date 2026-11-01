import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/map/vip_google_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class SetPickupLocationScreen extends StatefulWidget {
  const SetPickupLocationScreen({
    super.key,
    this.initialLocation,
    this.title = 'Set pickup location',
    this.label = 'Pickup location',
    this.confirmButtonText = 'Confirm pickup location',
  });

  final LocationSearchResult? initialLocation;
  final String title;
  final String label;
  final String confirmButtonText;

  @override
  State<SetPickupLocationScreen> createState() => _SetPickupLocationScreenState();
}

class _SetPickupLocationScreenState extends State<SetPickupLocationScreen> {
  final GlobalKey<VipGoogleMapState> _mapKey = GlobalKey<VipGoogleMapState>();

  late ll.LatLng _currentCenter;
  final ValueNotifier<String> _addressNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier<bool>(false);
  LocationSearchResult? _resolvedLocation;
  Timer? _debounceTimer;

  // Default coordinate (e.g. New York / current city fallback)
  static const ll.LatLng _defaultCenter = ll.LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null && widget.initialLocation!.hasCoordinates) {
      _currentCenter = ll.LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _addressNotifier.value = widget.initialLocation!.placeName;
      _resolvedLocation = widget.initialLocation;
    } else {
      _currentCenter = _defaultCenter;
      _initUserLocation();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressNotifier.dispose();
    _isSearchingNotifier.dispose();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _reverseGeocode(_currentCenter);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _reverseGeocode(_currentCenter);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final userPt = ll.LatLng(pos.latitude, pos.longitude);
      _currentCenter = userPt;
      _mapKey.currentState?.animateTo(userPt);
      _reverseGeocode(userPt);
    } catch (_) {
      _reverseGeocode(_currentCenter);
    }
  }

  void _onCameraMove(ll.LatLng target) {
    _debounceTimer?.cancel();
    _currentCenter = target;
    if (!_isSearchingNotifier.value) {
      _isSearchingNotifier.value = true;
    }
  }

  void _onCameraIdle() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _reverseGeocode(_currentCenter);
    });
  }

  Future<void> _reverseGeocode(ll.LatLng point) async {
    if (!mounted) return;
    _isSearchingNotifier.value = true;

    try {
      final result = await LocationSearchService.reverseGeocode(point);
      if (mounted) {
        if (result != null && result.placeName.trim().isNotEmpty) {
          _resolvedLocation = result;
          _addressNotifier.value = result.placeName;
        } else {
          final addr =
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
          _resolvedLocation = LocationSearchResult(
            placeName: addr,
            latitude: point.latitude,
            longitude: point.longitude,
          );
          _addressNotifier.value = addr;
        }
        _isSearchingNotifier.value = false;
      }
    } catch (_) {
      if (mounted) {
        final addr =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        _resolvedLocation = LocationSearchResult(
          placeName: addr,
          latitude: point.latitude,
          longitude: point.longitude,
        );
        _addressNotifier.value = addr;
        _isSearchingNotifier.value = false;
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    HapticFeedback.lightImpact();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          CustomToast.showError(context, 'Please enable GPS location services');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final userPt = ll.LatLng(pos.latitude, pos.longitude);
      _mapKey.currentState?.animateTo(userPt);
      _reverseGeocode(userPt);
    } catch (_) {
      if (mounted) {
        CustomToast.showError(context, 'Could not obtain current location');
      }
    }
  }

  void _confirmSelection() {
    if (_isSearchingNotifier.value || _addressNotifier.value.trim().isEmpty) return;

    final result = _resolvedLocation ??
        LocationSearchResult(
          placeName: _addressNotifier.value,
          latitude: _currentCenter.latitude,
          longitude: _currentCenter.longitude,
        );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          // Fullscreen Interactive VipGoogleMap (extends under bottom card)
          Positioned.fill(
            child: VipGoogleMap(
              key: _mapKey,
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              padding: const EdgeInsets.only(bottom: 180),
            ),
          ),

          // Center Pin pointing precisely at visible map center
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -97),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2.5,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Header Overlay: Circle Back Button + Title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
                      (isDark ? Colors.black : Colors.white).withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Row(
                      children: [
                        IgnorePointer(
                          ignoring: false,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating "My Location" GPS crosshairs button (above the translucent card)
          Positioned(
            right: 16,
            bottom: 200,
            child: GestureDetector(
              onTap: _goToCurrentLocation,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.my_location_rounded,
                  color: cs.onSurface,
                  size: 20,
                ),
              ),
            ),
          ),

          // Bottom Sheet: Translucent Frosted Glass Card with Solid Confirm Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_addressNotifier, _isSearchingNotifier]),
                        builder: (context, _) {
                          final isSearching = _isSearchingNotifier.value;
                          final address = _addressNotifier.value;
                          final isConfirmEnabled = !isSearching && address.trim().isNotEmpty;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isSearching ? 'Searching...' : (address.isEmpty ? 'Locating...' : address),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: cs.onSurface,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Thin horizontal underline divider
                              Container(
                                height: 1.0,
                                width: double.infinity,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.12),
                              ),
                              const SizedBox(height: 18),
                              // Confirm pickup location button: SOLID OPAQUE
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isConfirmEnabled ? _confirmSelection : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isConfirmEnabled
                                        ? AppColors.primary
                                        : (isDark
                                            ? const Color(0xFF2C2C30)
                                            : const Color(0xFFB0B3B8)),
                                    foregroundColor: isConfirmEnabled
                                        ? Colors.black
                                        : (isDark ? Colors.white54 : Colors.white),
                                    elevation: isConfirmEnabled ? 2 : 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    disabledBackgroundColor: isDark
                                        ? const Color(0xFF2C2C30)
                                        : const Color(0xFFB0B3B8),
                                    disabledForegroundColor:
                                        isDark ? Colors.white54 : Colors.white,
                                  ),
                                  child: Text(
                                    widget.confirmButtonText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
