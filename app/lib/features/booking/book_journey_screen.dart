import 'package:kenick_vip/services/booking_draft_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kenick_vip/features/booking/add_guest_screen.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookJourneyScreen extends StatefulWidget {
  const BookJourneyScreen({super.key});

  @override
  State<BookJourneyScreen> createState() => _BookJourneyScreenState();
}

class _BookJourneyScreenState extends State<BookJourneyScreen> {
  // Booking options
  String _rideType = 'One way'; // 'One way' or 'By-the-hour'
  int _byTheHourDuration = 2; // Default 2 hours
  bool _isDurationDropdownOpen = false;
  String _passengerMode = 'For myself'; // 'For myself' or guest name
  String? _guestName;
  String? _guestPhone;

  // Controllers and Focus Nodes
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropoffFocusNode = FocusNode();

  bool _isPickupActive = true;
  LocationSearchResult? _pickupLocation;
  LocationSearchResult? _dropoffLocation;

  // Autocomplete search
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<LocationSearchResult> _searchResults = [];

  // Saved / Frequent places cache
  String? _savedHome;
  String? _savedWork;

  @override
  void initState() {
    super.initState();

    // Initialize from providers if available
    final rideProv = context.read<RideProvider>();
    final bookingProv = context.read<BookingProvider>();

    if (rideProv.pickupLocation != null) {
      _pickupLocation = rideProv.pickupLocation;
      _pickupController.text = _pickupLocation!.placeName;
    } else if (bookingProv.pickupAddress != null && bookingProv.pickupAddress!.isNotEmpty) {
      _pickupLocation = LocationSearchResult(
        placeName: bookingProv.pickupAddress!,
        latitude: bookingProv.pickupLat ?? 37.42796,
        longitude: bookingProv.pickupLng ?? -122.08574,
      );
      _pickupController.text = _pickupLocation!.placeName;
    }

    if (rideProv.dropoffLocation != null) {
      _dropoffLocation = rideProv.dropoffLocation;
      _dropoffController.text = _dropoffLocation!.placeName;
    } else if (bookingProv.dropoffAddress != null &&
        bookingProv.dropoffAddress!.isNotEmpty &&
        !bookingProv.dropoffAddress!.contains('Hourly Service')) {
      _dropoffLocation = LocationSearchResult(
        placeName: bookingProv.dropoffAddress!,
        latitude: bookingProv.dropoffLat ?? 37.42796,
        longitude: bookingProv.dropoffLng ?? -122.08574,
      );
      _dropoffController.text = _dropoffLocation!.placeName;
    }

    if (bookingProv.bookingType == 'schedule') {
      _rideType = 'By-the-hour';
    }

    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus) {
        setState(() {
          _isPickupActive = true;
          _searchResults = [];
        });
        if (_pickupController.text.trim().isNotEmpty) {
          _onSearchQueryChanged(_pickupController.text);
        }
      }
    });

    _dropoffFocusNode.addListener(() {
      if (_dropoffFocusNode.hasFocus) {
        setState(() {
          _isPickupActive = false;
          _searchResults = [];
        });
        if (_dropoffController.text.trim().isNotEmpty) {
          _onSearchQueryChanged(_dropoffController.text);
        }
      }
    });

    _loadSavedPlaces();
  }

  void _saveDraft() {
    final pText = _pickupLocation?.placeName ?? _pickupController.text.trim();
    final dText = _dropoffLocation?.placeName ?? _dropoffController.text.trim();
    if (pText.isNotEmpty || dText.isNotEmpty) {
      final draft = BookingDraft(
        pickupAddress: pText.isNotEmpty ? pText : null,
        dropoffAddress: dText.isNotEmpty ? dText : null,
        pickupLat: _pickupLocation?.latitude,
        pickupLng: _pickupLocation?.longitude,
        dropoffLat: _dropoffLocation?.latitude,
        dropoffLng: _dropoffLocation?.longitude,
        rideType: _rideType,
        byTheHourDuration: _byTheHourDuration,
        passengerMode: _passengerMode,
        guestName: _guestName,
        guestPhone: _guestPhone,
        createdAt: DateTime.now(),
      );
      BookingDraftService.saveDraft(draft);
    }
  }

  @override
  void dispose() {
    _saveDraft();
    _debounceTimer?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_frequent_addresses');
      if (cached != null) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _savedHome = (map['home'] as String?)?.trim().isNotEmpty == true
                ? map['home']
                : null;
            _savedWork = (map['work'] as String?)?.trim().isNotEmpty == true
                ? map['work']
                : null;
          });
        }
      }
    } catch (_) {}
  }

  void _onSearchQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      try {
        final results = await LocationSearchService.search(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectSearchResult(LocationSearchResult result) {
    if (_isPickupActive) {
      setState(() {
        _pickupLocation = result;
        _pickupController.text = result.placeName;
        _searchResults = [];
      });
      // Automatically shift focus to dropoff if not set
      if (_dropoffLocation == null) {
        _dropoffFocusNode.requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      setState(() {
        _dropoffLocation = result;
        _dropoffController.text = result.placeName;
        _searchResults = [];
      });
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          CustomToast.showError(context, 'Please enable location services');
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

      final reverse = await LocationSearchService.reverseGeocode(
        LatLng(pos.latitude, pos.longitude),
      );

      final result = reverse ??
          LocationSearchResult(
            placeName: 'Current Location',
            latitude: pos.latitude,
            longitude: pos.longitude,
          );

      if (mounted) {
        setState(() {
          _pickupLocation = result;
          _pickupController.text = result.placeName;
        });
        if (_dropoffLocation == null) {
          _dropoffFocusNode.requestFocus();
        }
      }
    } catch (_) {
      if (mounted) {
        CustomToast.showError(context, 'Could not retrieve current location');
      }
    }
  }

  Future<void> _openMapLocationScreen({required bool isPickup}) async {
    HapticFeedback.lightImpact();
    final result = await context.push<LocationSearchResult>(
      '/set-pickup-location',
      extra: {
        'initialLocation': isPickup ? _pickupLocation : _dropoffLocation,
        'title': isPickup ? 'Set pickup location' : 'Set drop-off location',
        'label': isPickup ? 'Pickup location' : 'Drop-off location',
        'confirmButtonText': isPickup ? 'Confirm pickup location' : 'Confirm drop-off location',
      },
    );
    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupLocation = result;
          _pickupController.text = result.placeName;
          if (_dropoffLocation == null) {
            _dropoffFocusNode.requestFocus();
          } else {
            FocusScope.of(context).unfocus();
          }
        } else {
          _dropoffLocation = result;
          _dropoffController.text = result.placeName;
          FocusScope.of(context).unfocus();
        }
        _searchResults = [];
      });
    }
  }

  void _swapLocations() {
    HapticFeedback.lightImpact();
    setState(() {
      final tempLoc = _pickupLocation;
      final tempText = _pickupController.text;

      _pickupLocation = _dropoffLocation;
      _pickupController.text = _dropoffController.text;

      _dropoffLocation = tempLoc;
      _dropoffController.text = tempText;
    });
  }

  void _confirmAndProceed() {
    if (_pickupLocation == null) {
      if (_pickupController.text.trim().isNotEmpty) {
        _pickupLocation = LocationSearchResult(
          placeName: _pickupController.text.trim(),
          latitude: 37.42796,
          longitude: -122.08574,
        );
      } else {
        CustomToast.showError(context, 'Please enter a pickup location');
        _pickupFocusNode.requestFocus();
        return;
      }
    }
    if (_rideType == 'One way' && _dropoffLocation == null) {
      CustomToast.showError(context, 'Please enter a drop-off destination');
      _dropoffFocusNode.requestFocus();
      return;
    }

    final rideProv = context.read<RideProvider>();
    final bookingProv = context.read<BookingProvider>();

    rideProv.setPickupDropoff(_pickupLocation, _dropoffLocation);

    final pickupLat = _pickupLocation!.latitude;
    final pickupLng = _pickupLocation!.longitude;
    final dropoffLat = _dropoffLocation?.latitude ?? pickupLat;
    final dropoffLng = _dropoffLocation?.longitude ?? pickupLng;

    bookingProv.setTripDetails(
      pickupAddress: _pickupLocation!.placeName,
      dropoffAddress: _dropoffLocation?.placeName ?? 'Hourly Service ($_byTheHourDuration hrs)',
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      passengerNote: _guestName != null ? 'Guest: $_guestName ($_guestPhone)' : null,
    );

    bookingProv.setBookingType(
      _rideType == 'By-the-hour' ? 'schedule' : 'instant',
      eventType: _rideType == 'By-the-hour' ? 'Hourly Hire ($_byTheHourDuration h)' : null,
    );

    context.push('/fleet-selection');
  }

  // --- Bottom Sheet: Ride Type Selection ---
  void _showRideTypeModal() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want to take a one way or\nby-the-hour ride?',
                  style: GoogleFonts.poppins(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),
                _buildRideTypeOption(
                  context: ctx,
                  icon: Icons.directions_rounded,
                  title: 'One way',
                  subtitle: 'One direction from A to B.',
                  isSelected: _rideType == 'One way',
                  onTap: () {
                    setState(() => _rideType = 'One way');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
                _buildRideTypeOption(
                  context: ctx,
                  icon: Icons.access_time_rounded,
                  title: 'By-the-hour',
                  subtitle: 'Time-based ride. Min 2h, max 24h.',
                  isSelected: _rideType == 'By-the-hour',
                  onTap: () {
                    setState(() {
                      _rideType = 'By-the-hour';
                      _isDurationDropdownOpen = false;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideTypeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26262B) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : cs.onSurface, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Sheet: Passenger Selection ---
  Future<void> _showPassengerModal() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final savedGuests = await GuestStorageService.getSavedGuests();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book for another passenger',
                    style: GoogleFonts.poppins(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Arrange their ride in a few taps, and we'll keep them informed every step of the way.",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPassengerOption(
                    context: ctx,
                    icon: Icons.person_outline_rounded,
                    title: 'Book for myself',
                    isSelected: _passengerMode == 'For myself',
                    onTap: () {
                      setState(() {
                        _passengerMode = 'For myself';
                        _guestName = null;
                        _guestPhone = null;
                      });
                      final bookingProv = context.read<BookingProvider>();
                      bookingProv.setTripDetails(
                        pickupAddress: _pickupController.text.trim(),
                        dropoffAddress: _dropoffController.text.trim(),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                  ...savedGuests.map((g) {
                    final fullName = (g['full_name'] as String? ?? '').isNotEmpty
                        ? g['full_name'] as String
                        : '${g['first_name'] ?? ''} ${g['last_name'] ?? ''}'.trim();
                    final firstName = g['first_name'] as String? ?? fullName;
                    final fullPhone = g['full_phone'] as String? ?? '';
                    final isCurrent = _guestName == fullName;

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _buildPassengerOption(
                        context: ctx,
                        icon: Icons.person_rounded,
                        title: 'Guest: $fullName',
                        subtitle: fullPhone.isNotEmpty ? fullPhone : null,
                        isSelected: isCurrent,
                        onTap: () {
                          setState(() {
                            _guestName = fullName;
                            _guestPhone = fullPhone;
                            _passengerMode = firstName.isNotEmpty ? firstName : fullName;
                          });
                          final bookingProv = context.read<BookingProvider>();
                          bookingProv.setTripDetails(
                            pickupAddress: _pickupController.text.trim(),
                            dropoffAddress: _dropoffController.text.trim(),
                            passengerNote: 'Guest: $fullName ($fullPhone)',
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildPassengerOption(
                    context: ctx,
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Add a new guest',
                    isSelected: false,
                    showChevron: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      _openAddGuestScreen();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddGuestScreen() async {
    final result = await context.push<Map<String, dynamic>>('/add-guest');
    if (result != null && mounted) {
      final firstName = result['first_name'] as String? ?? '';
      final lastName = result['last_name'] as String? ?? '';
      final fullName = result['full_name'] as String? ?? '$firstName $lastName'.trim();
      final fullPhone = result['full_phone'] as String? ?? '';

      setState(() {
        _guestName = fullName;
        _guestPhone = fullPhone;
        _passengerMode = firstName.isNotEmpty ? firstName : fullName;
      });

      final bookingProv = context.read<BookingProvider>();
      bookingProv.setTripDetails(
        pickupAddress: _pickupController.text.trim(),
        dropoffAddress: _dropoffController.text.trim(),
        passengerNote: 'Guest: $fullName ($fullPhone)',
      );
    }
  }

  Widget _buildPassengerOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isSelected,
    bool showChevron = false,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26262B) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : cs.onSurface, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20)
            else if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final showContinue = _pickupLocation != null &&
        (_rideType == 'By-the-hour' || _dropoffLocation != null);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Back circle button + Centered Title "Book a ride"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardColor,
                          border: Border.all(color: subtleBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
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
                  Text(
                    'Book a ride',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Pills Row: [One way v]  [For myself v]
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Ride Type Pill
                            GestureDetector(
                              onTap: _showRideTypeModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: subtleBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _rideType == 'One way'
                                          ? Icons.directions_rounded
                                          : Icons.access_time_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _rideType == 'By-the-hour'
                                          ? 'By-the-hour'
                                          : 'One way',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Passenger Pill
                            GestureDetector(
                              onTap: _showPassengerModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: subtleBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 140),
                                      child: Text(
                                        _passengerMode,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Location Input Block
                      if (_rideType == 'By-the-hour') ...[
                        // ── By-the-hour layout (Images 2, 4, 5) ──
                        Theme(
                          data: theme.copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pickup Location
                              Text(
                                'Pickup location',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _pickupController,
                                      focusNode: _pickupFocusNode,
                                      onTap: () {
                                        if (!_isPickupActive) {
                                          setState(() => _isPickupActive = true);
                                        }
                                      },
                                      onChanged: _onSearchQueryChanged,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: cs.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Airport, address, hotel, ...',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                        isDense: true,
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        suffixIcon: _pickupController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.close_rounded, size: 18),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() {
                                                    _pickupController.clear();
                                                    _pickupLocation = null;
                                                    _searchResults = [];
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _openMapLocationScreen(isPickup: true),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8, right: 2),
                                      child: Icon(
                                        Icons.map_outlined,
                                        color: cs.onSurface,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Bottom underline line for Pickup
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 1.5,
                                width: double.infinity,
                                color: _pickupFocusNode.hasFocus
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.15)),
                              ),

                              const SizedBox(height: 22),

                              // Duration Dropdown Selector
                              Text(
                                'Duration',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _isDurationDropdownOpen = !_isDurationDropdownOpen);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$_byTheHourDuration hours (${_byTheHourDuration * 40} km)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      Icon(
                                        _isDurationDropdownOpen
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: cs.onSurface,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: _isDurationDropdownOpen ? 2.0 : 1.5,
                                width: double.infinity,
                                color: _isDurationDropdownOpen
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.15)),
                              ),

                              // Inline Dropdown List (Image 5)
                              if (_isDurationDropdownOpen)
                                _buildDurationDropdownCard(isDark, cs),
                            ],
                          ),
                        ),
                      ] else ...[
                        // ── One way layout (Existing flow) ──
                        Theme(
                          data: theme.copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Pickup Location
                                    Text(
                                      'Pickup location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
    
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _pickupController,
                                            focusNode: _pickupFocusNode,
                                            onTap: () {
                                              if (!_isPickupActive) {
                                                setState(() => _isPickupActive = true);
                                              }
                                            },
                                            onChanged: _onSearchQueryChanged,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: cs.onSurface,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Airport, address, hotel, ...',
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 15,
                                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                              ),
                                              isDense: true,
                                              filled: false,
                                              fillColor: Colors.transparent,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder: InputBorder.none,
                                              suffixIcon: _pickupController.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.close_rounded, size: 18),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        setState(() {
                                                          _pickupController.clear();
                                                          _pickupLocation = null;
                                                          _searchResults = [];
                                                        });
                                                      },
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (_isPickupActive)
                                          GestureDetector(
                                            onTap: () => _openMapLocationScreen(isPickup: true),
                                            behavior: HitTestBehavior.opaque,
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 8, right: 2),
                                              child: Icon(
                                                Icons.map_outlined,
                                                color: cs.onSurface,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Bottom underline line for Pickup (highlighted when active)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: _isPickupActive ? 2.0 : 1.5,
                                      width: double.infinity,
                                      color: _isPickupActive
                                          ? AppColors.primary
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.18)
                                              : Colors.black.withValues(alpha: 0.15)),
                                    ),

                                    const SizedBox(height: 20),

                                    // Drop-off Location
                                    Text(
                                      'Drop-off location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
    
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _dropoffController,
                                            focusNode: _dropoffFocusNode,
                                            onTap: () {
                                              if (_isPickupActive) {
                                                setState(() => _isPickupActive = false);
                                              }
                                            },
                                            onChanged: _onSearchQueryChanged,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: cs.onSurface,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Where to?',
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 15,
                                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                              ),
                                              isDense: true,
                                              filled: false,
                                              fillColor: Colors.transparent,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder: InputBorder.none,
                                              suffixIcon: _dropoffController.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.close_rounded, size: 18),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        setState(() {
                                                          _dropoffController.clear();
                                                          _dropoffLocation = null;
                                                          _searchResults = [];
                                                        });
                                                      },
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (!_isPickupActive)
                                          GestureDetector(
                                            onTap: () => _openMapLocationScreen(isPickup: false),
                                            behavior: HitTestBehavior.opaque,
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 8, right: 2),
                                              child: Icon(
                                                Icons.map_outlined,
                                                color: cs.onSurface,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Bottom underline line for Drop-off (highlighted when active)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: !_isPickupActive ? 2.0 : 1.5,
                                      width: double.infinity,
                                      color: !_isPickupActive
                                          ? AppColors.primary
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.18)
                                              : Colors.black.withValues(alpha: 0.15)),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Swap Button on right
                              GestureDetector(
                                onTap: _swapLocations,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF26262B) : const Color(0xFFECEEF1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.swap_vert_rounded,
                                    size: 20,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Search Results (if user is actively typing) OR Suggested section
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      else if (_searchResults.isNotEmpty) ...[
                        Text(
                          'Results',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF24242A) : const Color(0xFFF3F4F6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                item.mainText ?? item.placeName.split(',').first,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              subtitle: item.secondaryText != null
                                  ? Text(
                                      item.secondaryText!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              onTap: () => _selectSearchResult(item),
                            );
                          },
                        ),
                      ] else if (_rideType == 'By-the-hour') ...[
                        // 3 Bullet Information Items (Image 2)
                        const SizedBox(height: 28),
                        _buildHourlyInfoItem(
                          icon: Icons.access_time_rounded,
                          title: 'Min. 2 hours and max. 24 hours',
                          subtitle:
                              'For long rides, your chauffeur may need to stop to refuel and take breaks',
                          cs: cs,
                        ),
                        const SizedBox(height: 20),
                        _buildHourlyInfoItem(
                          icon: Icons.alt_route_rounded,
                          title: '40 km per hour included',
                          subtitle: 'Extra distance or time incurs extra charges',
                          cs: cs,
                        ),
                        const SizedBox(height: 20),
                        _buildHourlyInfoItem(
                          icon: Icons.location_city_rounded,
                          title: 'In-city rides',
                          subtitle:
                              'By-the-hour rides must end in the same city as the pickup, or an extra charge applies',
                          cs: cs,
                        ),
                      ] else ...[
                        // Default "Suggested" state matching the reference screenshot
                        Text(
                          'Suggested',
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Suggestions and favorite locations will appear here as you use our service',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Quick Suggested Location Chips
                        _buildSuggestedItem(
                          icon: Icons.my_location_rounded,
                          title: 'Current Location',
                          subtitle: 'Use GPS device coordinates',
                          onTap: _useCurrentLocation,
                        ),
                        if (_savedHome != null) ...[
                          const SizedBox(height: 10),
                          _buildSuggestedItem(
                            icon: Icons.home_rounded,
                            title: 'Home',
                            subtitle: _savedHome!,
                            onTap: () {
                              _onSearchQueryChanged(_savedHome!);
                            },
                          ),
                        ],
                        if (_savedWork != null) ...[
                          const SizedBox(height: 10),
                          _buildSuggestedItem(
                            icon: Icons.work_rounded,
                            title: 'Work',
                            subtitle: _savedWork!,
                            onTap: () {
                              _onSearchQueryChanged(_savedWork!);
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildSuggestedItem(
                          icon: Icons.local_airport_rounded,
                          title: 'Indianapolis International Airport (IND)',
                          subtitle: 'Col. H. Weir Cook Terminal, Indianapolis, IN',
                          onTap: () async {
                            final results = await LocationSearchService.search(
                              'Indianapolis International Airport IND',
                            );
                            if (results.isNotEmpty) {
                              _selectSearchResult(results.first);
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom CTA
            if (_rideType == 'By-the-hour') ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_pickupLocation != null ||
                            _pickupController.text.trim().isNotEmpty)
                        ? _confirmAndProceed
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF2C2C32)
                          : const Color(0xFFB0B3B8),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Select $_byTheHourDuration-hour ride',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (showContinue)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: subtleBorder)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _confirmAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue to Fleet',
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
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

  Widget _buildHourlyInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme cs,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: cs.onSurface,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDropdownCard(bool isDark, ColorScheme cs) {
    final durations = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 24];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          itemCount: durations.length,
          itemBuilder: (context, index) {
            final hours = durations[index];
            final isSelected = hours == _byTheHourDuration;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _byTheHourDuration = hours;
                  _isDurationDropdownOpen = false;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : const Color(0xFFD6E8FD))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$hours hours (${hours * 40} km)',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (isDark ? AppColors.primary : const Color(0xFF0F172A))
                        : cs.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuggestedItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222328) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.north_west_rounded, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
