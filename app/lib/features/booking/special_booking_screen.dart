import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kenick_vip/config/env_config.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/services/fare_rate_service.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/inputs/location_search_field.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class SpecialBookingScreen extends StatefulWidget {
  const SpecialBookingScreen({super.key});

  @override
  State<SpecialBookingScreen> createState() => _SpecialBookingScreenState();
}

class _SpecialBookingScreenState extends State<SpecialBookingScreen> {
  static const LatLng _initialPosition = LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  late LatLng _currentPosition;
  final MapController _mapController = MapController();
  final bool _isSearching = false;
  String? _countryCode;
  List<LatLng>? _routePoints;

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null)
        ? mem.lastPosition!
        : _initialPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mem.hasMemory && mem.lastPosition != null) {
        _mapController.move(mem.lastPosition!, mem.lastZoom);
      }
      final code = await LocationSearchService.detectCountryCode(
        _currentPosition,
      );
      if (mounted) setState(() => _countryCode = code);
    });

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
  }

  double _initialChildSize(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    double contentH = 0;
    contentH += 40;           // 16 top pad + 24 drag handle
    contentH += 12;           // spacer
    contentH += 64;           // clients (12 pad + 40 textfield + 12 pad)
    contentH += 12 + 48;      // spacer + date/time (14 pad + 20 icon + 14 pad)
    contentH += 12 + 48;      // spacer + event type
    contentH += 12 + 48 + 20; // spacer + comments + spacer
    contentH += 116;          // location inputs (50 field + 16 gap + 50 field)
    if (_calculatedFare != null) contentH += 24 + 80;
    contentH += 32 + 52 + 8; // spacer + button + spacer
    return ((contentH + bottomPad) / screenH).clamp(0.08, 0.9);
  }

  final TextEditingController _passengersController = TextEditingController(
    text: '1',
  );
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedEvent;
  final List<String> _eventTypes = [
    'Wedding',
    'Birthday',
    'Corporate Event',
    'Concert',
    'Night Out',
    'Airport Transfer',
    'Graduation',
    'Other',
  ];
  double? _calculatedFare;
  double? _distanceKm;
  double? _durationSeconds;
  double _sheetExtent = 0;
  LocationSearchResult? _pickupLocation;
  LocationSearchResult? _dropoffLocation;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();


  String get _formattedDateTime {
    if (_selectedDate == null) return 'Date and time';
    final datePart = DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);
    if (_selectedTime == null) return datePart;
    final timePart = _selectedTime!.format(context);
    return '$datePart  \u2022  $timePart';
  }

  Future<void> _pickDateAndTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.darkSurface,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                  ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.darkSurface,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                  ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  @override
  void dispose() {
    MapMemory().save(_currentPosition, _mapController.camera.zoom);
    _passengersController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _commentController.dispose();
    super.dispose();
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

  Future<void> _handleLocationSelected() async {
    if (_pickupLocation != null && _dropoffLocation != null) {
      final pickupLatLng = LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude);
      final dropoffLatLng = LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude);

      final routeResult = await LocationSearchService.getRoute(pickupLatLng, dropoffLatLng);
      if (routeResult != null) {
        _distanceKm = routeResult.distanceKm;
        _durationSeconds = routeResult.durationSeconds;
        _routePoints = routeResult.points;
      } else {
        _distanceKm = const Distance().as(LengthUnit.Kilometer, pickupLatLng, dropoffLatLng);
        _durationSeconds = null;
        _routePoints = [pickupLatLng, dropoffLatLng];
      }

      final rate = await FareRateService.getRate(_countryCode ?? 'US');
      _calculatedFare = rate.baseFare + (_distanceKm! * rate.perKmRate);
      if (mounted) {
        _sheetExtent = _initialChildSize(context);
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds(pickupLatLng, dropoffLatLng),
              padding: const EdgeInsets.all(60),
            ),
          );
        });
      }
    }
  }

  void _showEventPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Event Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _eventTypes.map((event) => ListTile(
                        leading: Icon(
                          _selectedEvent == event ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _selectedEvent == event ? AppColors.primary : Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          event,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedEvent == event ? FontWeight.w600 : FontWeight.w400,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedEvent = event);
                          Navigator.pop(ctx);
                        },
                      )).toList(),
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
          // Map Background
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
                  AnimatedMarker.locationDot(point: _currentPosition, color: AppColors.primary),
                  if (_pickupLocation != null)
                    AnimatedMarker.pickupPin(point: LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude)),
                  if (_dropoffLocation != null)
                    AnimatedMarker.dropoffPin(point: LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude)),
                ],
              ),
              if (_routePoints != null && _routePoints!.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints!,
                      color: AppColors.primary,
                      strokeWidth: 6,
                    ),
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
              bottom: MediaQuery.of(context).size.height * _sheetExtent.clamp(0.08, 1.0) + 10,
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
                      '${_formatDistance(_distanceKm!)} · ${_formatDuration()}',
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
                      // Drag handle
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



                      // Number of passengers
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

                      // Date and time
                      GestureDetector(
                        onTap: _pickDateAndTime,
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
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: _selectedDate != null
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.white
                                                : Colors.black87),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _formattedDateTime,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _selectedDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: _selectedDate != null
                                              ? AppColors.primary
                                              : (isDark
                                                    ? AppColors.white
                                                    : AppColors.black),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
                      const SizedBox(height: 12),

                      // Event type
                      GestureDetector(
                        onTap: _showEventPicker,
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
                                    Icons.event_note,
                                    color: _selectedEvent != null
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.white
                                              : Colors.black87),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedEvent ?? 'Event type',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedEvent != null
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _selectedEvent != null
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
                      const SizedBox(height: 12),

                      // Comments
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

                      // Location Inputs with timeline
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
                      const SizedBox(height: 32),

                      // Request Estimate Button
                      Consumer<RideProvider>(
                        builder: (context, rideProv, child) {
                          return CustomButton(
                            title: _isSearching || rideProv.isLoading
                                ? 'Requesting estimate...'
                                : 'Request estimate',
                            isLoading: _isSearching || rideProv.isLoading,
                            onPress: _isSearching || rideProv.isLoading
                                ? () {}
                                : () async {
                                    final ctx = this.context;
                                    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
                                      CustomToast.showError(ctx, 'Please enter pickup and dropoff locations');
                                      return;
                                    }
                                    if (_selectedDate == null || _selectedTime == null) {
                                      CustomToast.showError(ctx, 'Please select date and time');
                                      return;
                                    }
                                    if (_calculatedFare == null) {
                                      CustomToast.showError(ctx, 'Fare not calculated yet');
                                      return;
                                    }

                                    final bookingProv = ctx.read<BookingProvider>();
                                    bookingProv.setTripDetails(
                                      pickupAddress: _fromController.text,
                                      dropoffAddress: _toController.text,
                                      pickupLat: _pickupLocation?.latitude,
                                      pickupLng: _pickupLocation?.longitude,
                                      dropoffLat: _dropoffLocation?.latitude,
                                      dropoffLng: _dropoffLocation?.longitude,
                                      passengerNote: _commentController.text.trim().isNotEmpty
                                          ? _commentController.text.trim()
                                          : null,
                                    );
                                    bookingProv.setFare(_calculatedFare!, _distanceKm);
                                    bookingProv.setBookingType(
                                      'special',
                                      scheduledTime: _selectedDate != null && _selectedTime != null
                                          ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute)
                                          : null,
                                      eventType: _selectedEvent,
                                    );

                                    ctx.push('/tip-selection', extra: {'fareAmount': _calculatedFare});
                                  },
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
