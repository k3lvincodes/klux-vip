import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/features/booking/add_guest_screen.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/airport_detection_service.dart';
import 'package:kenick_vip/services/booking_draft_service.dart';
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
  String _rideType = 'One way'; // 'One way', 'Round trip', 'By-the-hour', 'Event', 'Out of state'
  int _byTheHourDuration = 2; // Default 2 hours
  bool _isDurationDropdownOpen = false;
  String _passengerMode = 'For myself'; // 'For myself' or guest name
  String? _guestName;
  String? _guestPhone;

  // Schedule options (available for ALL ride types)
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(minutes: 30)),
  );
  // Round trip return schedule
  DateTime _returnDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _returnTime = const TimeOfDay(hour: 18, minute: 0);

  // Event options
  String _selectedEventType = 'Wedding';
  final TextEditingController _customEventController = TextEditingController();
  final FocusNode _customEventFocusNode = FocusNode();
  final List<String> _eventOptions = const [
    'Wedding',
    'Corporate Event / Gala',
    'Concert & Festival',
    'Sporting Event',
    'Birthday / Anniversary',
    'Prom & Graduation',
    'VIP Night Out',
    'Airport Delegation',
    'Other',
  ];

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

    // Restore scheduled time if previously set
    final initialTime = bookingProv.scheduledTime ??
        DateTime.now().add(const Duration(minutes: 30));
    _selectedDate = DateTime(initialTime.year, initialTime.month, initialTime.day);
    _selectedTime = TimeOfDay.fromDateTime(initialTime);

    if (bookingProv.returnTime != null) {
      final ret = bookingProv.returnTime!;
      _returnDate = DateTime(ret.year, ret.month, ret.day);
      _returnTime = TimeOfDay.fromDateTime(ret);
    }

    if (bookingProv.rideType.isNotEmpty) {
      _rideType = bookingProv.rideType;
    } else if (bookingProv.bookingType == 'schedule') {
      _rideType = 'By-the-hour';
    }

    if (bookingProv.eventType != null && bookingProv.eventType!.startsWith('Event: ')) {
      final evName = bookingProv.eventType!.replaceFirst('Event: ', '').trim();
      if (_eventOptions.contains(evName)) {
        _selectedEventType = evName;
      } else {
        _selectedEventType = 'Other';
        _customEventController.text = evName;
      }
    }

    _customEventFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

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
        scheduledTime: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        returnTime: _rideType == 'Round trip'
            ? DateTime(
                _returnDate.year,
                _returnDate.month,
                _returnDate.day,
                _returnTime.hour,
                _returnTime.minute,
              )
            : null,
        eventType: _rideType == 'Event' ? _selectedEventType : null,
        customEventType: _rideType == 'Event' && _selectedEventType == 'Other'
            ? _customEventController.text.trim()
            : null,
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
    _customEventFocusNode.dispose();
    _customEventController.dispose();
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

    if (_rideType != 'By-the-hour' && _dropoffLocation == null) {
      if (_dropoffController.text.trim().isNotEmpty) {
        _dropoffLocation = LocationSearchResult(
          placeName: _dropoffController.text.trim(),
          latitude: 37.42796,
          longitude: -122.08574,
        );
      } else {
        final destLabel = _rideType == 'Round trip'
            ? 'destination for your return trip'
            : (_rideType == 'Event'
                ? 'event venue location'
                : (_rideType == 'Out of state'
                    ? 'out-of-state destination'
                    : 'drop-off destination'));
        CustomToast.showError(context, 'Please enter a $destLabel');
        _dropoffFocusNode.requestFocus();
        return;
      }
    }

    if (_rideType == 'Event' &&
        _selectedEventType == 'Other' &&
        _customEventController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Please specify your event type');
      return;
    }

    final rideProv = context.read<RideProvider>();
    final bookingProv = context.read<BookingProvider>();

    rideProv.setPickupDropoff(_pickupLocation, _dropoffLocation);

    final pickupLat = _pickupLocation!.latitude;
    final pickupLng = _pickupLocation!.longitude;
    final dropoffLat = _dropoffLocation?.latitude ?? pickupLat;
    final dropoffLng = _dropoffLocation?.longitude ?? pickupLng;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final returnDateTime = _rideType == 'Round trip'
        ? DateTime(
            _returnDate.year,
            _returnDate.month,
            _returnDate.day,
            _returnTime.hour,
            _returnTime.minute,
          )
        : null;

    String dropoffText = _dropoffLocation?.placeName ?? '';
    if (_rideType == 'By-the-hour') {
      dropoffText = 'Hourly Service ($_byTheHourDuration hrs)';
    } else if (_rideType == 'Round trip') {
      dropoffText = '${_dropoffLocation?.placeName ?? 'Destination'} (Round Trip)';
    }

    String? effectiveEventType;
    if (_rideType == 'Event') {
      effectiveEventType = _selectedEventType == 'Other' &&
              _customEventController.text.trim().isNotEmpty
          ? 'Event: ${_customEventController.text.trim()}'
          : 'Event: $_selectedEventType';
    } else if (_rideType == 'By-the-hour') {
      effectiveEventType = 'Hourly Hire ($_byTheHourDuration h)';
    } else if (_rideType == 'Out of state') {
      effectiveEventType = 'Out of State Travel';
    } else if (_rideType == 'Round trip') {
      effectiveEventType = 'Round Trip';
    }

    bookingProv.setTripDetails(
      pickupAddress: _pickupLocation!.placeName,
      dropoffAddress: dropoffText,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      passengerNote: _guestName != null ? 'Guest: $_guestName ($_guestPhone)' : null,
    );

    bookingProv.setBookingType(
      'schedule',
      scheduledTime: scheduledDateTime,
      eventType: effectiveEventType,
      rideType: _rideType,
      returnTime: returnDateTime,
    );

    _saveDraft();

    // Auto Airport Transfer detection
    final pickupName = _pickupLocation!.placeName;
    final isDropoffAirport = AirportDetectionService.isAirport(dropoffText);
    final isPickupAirport = AirportDetectionService.isAirport(pickupName);

    if (isDropoffAirport) {
      final code = AirportDetectionService.extractAirportCode(dropoffText);
      bookingProv.setAirportTransfer(
        isAirportTransfer: true,
        airportTransferType: 'dropoff',
        airportCode: code,
      );
      context.push('/airport-transfer', extra: {
        'isDropoff': true,
        'airportName': dropoffText,
        'airportCode': code,
      });
      return;
    } else if (isPickupAirport) {
      final code = AirportDetectionService.extractAirportCode(pickupName);
      bookingProv.setAirportTransfer(
        isAirportTransfer: true,
        airportTransferType: 'pickup',
        airportCode: code,
      );
      context.push('/airport-transfer', extra: {
        'isDropoff': false,
        'airportName': pickupName,
        'airportCode': code,
      });
      return;
    } else {
      bookingProv.setAirportTransfer(isAirportTransfer: false);
    }

    context.push('/fleet-selection');
  }

  // --- Bottom Sheet: Ride Type Selection ---
  void _showRideTypeModal() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select ride service',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kenick luxury chauffeur options for every journey',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildRideTypeOption(
                    context: ctx,
                    icon: Icons.arrow_forward_rounded,
                    title: 'One way',
                    subtitle: 'Point A to Point B direct luxury transit.',
                    isSelected: _rideType == 'One way',
                    onTap: () {
                      setState(() => _rideType = 'One way');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildRideTypeOption(
                    context: ctx,
                    icon: Icons.sync_alt_rounded,
                    title: 'Round trip',
                    subtitle: 'Two-way journey with scheduled return pickup.',
                    isSelected: _rideType == 'Round trip',
                    onTap: () {
                      setState(() => _rideType = 'Round trip');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildRideTypeOption(
                    context: ctx,
                    icon: Icons.access_time_rounded,
                    title: 'By-the-hour',
                    subtitle: 'Dedicated chauffeur at your disposal. Min 2h, max 24h.',
                    isSelected: _rideType == 'By-the-hour',
                    onTap: () {
                      setState(() {
                        _rideType = 'By-the-hour';
                        _isDurationDropdownOpen = false;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildRideTypeOption(
                    context: ctx,
                    icon: Icons.celebration_rounded,
                    title: 'Event',
                    subtitle: 'VIP transport for weddings, galas & celebrations.',
                    isSelected: _rideType == 'Event',
                    onTap: () {
                      setState(() => _rideType = 'Event');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildRideTypeOption(
                    context: ctx,
                    icon: Icons.alt_route_rounded,
                    title: 'Out of state',
                    subtitle: 'Interstate & long-distance executive travel.',
                    isSelected: _rideType == 'Out of state',
                    onTap: () {
                      setState(() => _rideType = 'Out of state');
                      Navigator.pop(ctx);
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

  // --- Bottom Sheet: Event Type Selection ---
  void _showEventTypeModal() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select event type',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose the occasion for tailored chauffeur presentation',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._eventOptions.map((opt) {
                    final isSelected = _selectedEventType == opt;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEventType = opt;
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.09)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getEventIcon(opt),
                                size: 20,
                                color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opt,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? AppColors.primary : cs.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate({bool isReturn = false}) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = isReturn ? _returnDate : _selectedDate;
    final first = isReturn ? _selectedDate : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: AppColors.primary,
              onPrimary: const Color(0xFF111827),
              surface: isDark ? AppColors.darkSurface : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF111827),
              secondary: AppColors.primary,
              onSecondary: const Color(0xFF111827),
              error: Colors.redAccent,
              onError: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnDate = picked;
        } else {
          _selectedDate = picked;
          if (_returnDate.isBefore(_selectedDate)) {
            _returnDate = _selectedDate.add(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _pickTime({bool isReturn = false}) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = isReturn ? _returnTime : _selectedTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: AppColors.primary,
              onPrimary: const Color(0xFF111827),
              surface: isDark ? AppColors.darkSurface : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF111827),
              secondary: AppColors.primary,
              onSecondary: const Color(0xFF111827),
              error: Colors.redAccent,
              onError: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnTime = picked;
        } else {
          _selectedTime = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (diff == 1) {
      return 'Tomorrow, ${DateFormat('MMM d').format(date)}';
    } else {
      return DateFormat('EEE, MMM d').format(date);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  IconData _getRideTypeIcon(String type) {
    switch (type) {
      case 'Round trip':
        return Icons.sync_alt_rounded;
      case 'By-the-hour':
        return Icons.access_time_rounded;
      case 'Event':
        return Icons.celebration_rounded;
      case 'Out of state':
        return Icons.alt_route_rounded;
      case 'One way':
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'Wedding':
        return Icons.favorite_rounded;
      case 'Corporate Event / Gala':
        return Icons.business_center_rounded;
      case 'Concert & Festival':
        return Icons.music_note_rounded;
      case 'Sporting Event':
        return Icons.sports_soccer_rounded;
      case 'Birthday / Anniversary':
      case 'Birthday / Celebration':
        return Icons.cake_rounded;
      case 'Prom & Graduation':
        return Icons.school_rounded;
      case 'VIP Night Out':
        return Icons.nightlife_rounded;
      case 'Airport Delegation':
        return Icons.flight_takeoff_rounded;
      case 'Other':
      default:
        return Icons.stars_rounded;
    }
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

    final hasPickup = _pickupLocation != null ||
        _pickupController.text.trim().isNotEmpty;
    final hasDropoff = _dropoffLocation != null ||
        _dropoffController.text.trim().isNotEmpty;
    final showContinue = hasPickup &&
        (_rideType == 'By-the-hour' || hasDropoff);

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
                                      _getRideTypeIcon(_rideType),
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _rideType,
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

                                    // Drop-off / Destination Location
                                    Text(
                                      _rideType == 'Round trip'
                                          ? 'Turnaround destination'
                                          : (_rideType == 'Event'
                                              ? 'Event venue or destination'
                                              : (_rideType == 'Out of state'
                                                  ? 'Out of state destination'
                                                  : 'Drop-off location')),
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
                                              hintText: _rideType == 'Round trip'
                                                  ? 'Where are you traveling to?'
                                                  : (_rideType == 'Event'
                                                      ? 'Ballroom, hotel, estate, stadium...'
                                                      : (_rideType == 'Out of state'
                                                          ? 'City, State or address (e.g. Chicago, IL)'
                                                          : 'Where to?')),
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

                      // Event Type Dropdown & Custom Field (when Event is selected)
                      if (_rideType == 'Event')
                        _buildEventSection(isDark, cs, subtleBorder, cardColor),

                      // Out of State Logistics Info Banner
                      if (_rideType == 'Out of state')
                        _buildOutOfStateBadge(isDark, cs, subtleBorder, cardColor),

                      // Schedule (Date & Time) Section - Applicable for ALL ride types!
                      _buildDateTimeSection(isDark, cs, subtleBorder, cardColor),

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

            // Bottom CTA (Sticky for all ride types)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : subtleBorder,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: showContinue ? _confirmAndProceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF111827),
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF2C2C32)
                        : const Color(0xFFB0B3B8),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _getCtaButtonText(showContinue),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
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

  String _getCtaButtonText(bool canContinue) {
    if (!canContinue) {
      if (_pickupLocation == null && _pickupController.text.trim().isEmpty) {
        return 'Enter pickup location';
      }
      if (_rideType != 'By-the-hour' && _dropoffLocation == null && _dropoffController.text.trim().isEmpty) {
        return 'Enter destination';
      }
    }
    switch (_rideType) {
      case 'By-the-hour':
        return 'Select $_byTheHourDuration-hour ride';
      case 'Round trip':
        return 'Continue Round Trip';
      case 'Event':
        final ev = _selectedEventType == 'Other' && _customEventController.text.trim().isNotEmpty
            ? _customEventController.text.trim()
            : _selectedEventType;
        return 'Continue for $ev';
      case 'Out of state':
        return 'Continue Out of State';
      case 'One way':
      default:
        return 'Continue';
    }
  }

  Widget _buildDateTimeSection(
    bool isDark,
    ColorScheme cs,
    Color subtleBorder,
    Color cardColor,
  ) {
    if (_rideType == 'Round trip') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Text(
            'Schedule Departure & Return',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildDateTimeDualBox(
            label: 'DEPARTURE PICKUP',
            dateText: _formatDate(_selectedDate),
            timeText: _formatTime(_selectedTime),
            onDateTap: _pickDate,
            onTimeTap: _pickTime,
            isDark: isDark,
            cs: cs,
            subtleBorder: subtleBorder,
            cardColor: cardColor,
          ),
          const SizedBox(height: 10),
          _buildDateTimeDualBox(
            label: 'RETURN PICKUP',
            dateText: _formatDate(_returnDate),
            timeText: _formatTime(_returnTime),
            onDateTap: () => _pickDate(isReturn: true),
            onTimeTap: () => _pickTime(isReturn: true),
            isDark: isDark,
            cs: cs,
            subtleBorder: subtleBorder,
            cardColor: cardColor,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Date & Pickup Time',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _buildDateTimeDualBox(
          label: _rideType == 'Event'
              ? 'EVENT DATE & TIME'
              : (_rideType == 'By-the-hour'
                  ? 'SERVICE START SCHEDULE'
                  : 'PICKUP SCHEDULE'),
          dateText: _formatDate(_selectedDate),
          timeText: _formatTime(_selectedTime),
          onDateTap: _pickDate,
          onTimeTap: _pickTime,
          isDark: isDark,
          cs: cs,
          subtleBorder: subtleBorder,
          cardColor: cardColor,
        ),
      ],
    );
  }

  Widget _buildDateTimeDualBox({
    required String label,
    required String dateText,
    required String timeText,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
    required bool isDark,
    required ColorScheme cs,
    required Color subtleBorder,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Date picker
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: onDateTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: subtleBorder,
              ),
              // Time picker
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: onTimeTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            timeText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventSection(
    bool isDark,
    ColorScheme cs,
    Color subtleBorder,
    Color cardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Type of event',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _showEventTypeModal,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _getEventIcon(_selectedEventType),
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedEventType,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_selectedEventType == 'Other') ...[
          const SizedBox(height: 16),
          Text(
            'Describe your event',
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
                  controller: _customEventController,
                  focusNode: _customEventFocusNode,
                  onChanged: (val) => setState(() {}),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Charity Gala, Film Premiere, Fashion Show...',
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
                    suffixIcon: _customEventController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _customEventController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          // Bottom underline line matching Pickup location (highlighted in gold on focus)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _customEventFocusNode.hasFocus ? 2.0 : 1.5,
            width: double.infinity,
            color: _customEventFocusNode.hasFocus
                ? AppColors.primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.15)),
          ),
        ],
      ],
    );
  }

  Widget _buildOutOfStateBadge(
    bool isDark,
    ColorScheme cs,
    Color subtleBorder,
    Color cardColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.alt_route_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Interstate Travel: Long-distance chauffeur itinerary, highway toll passes and driver rotation included.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: cs.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
