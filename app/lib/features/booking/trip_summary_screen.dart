import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/config/env_config.dart';
import 'package:kenick_vip/providers/booking_provider.dart';
import 'package:kenick_vip/providers/payment_provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';
import 'package:kenick_vip/repositories/review_repository.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/active_trip_chat_sheet.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:kenick_vip/widgets/cards/active_trip_card.dart';
import 'package:kenick_vip/widgets/cards/fare_display.dart';
import 'package:kenick_vip/widgets/feedback/ride_search_indicator.dart';
import 'package:kenick_vip/widgets/feedback/shimmer_loading.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/widgets/map/map_animator.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripSummaryScreen extends StatefulWidget {
  const TripSummaryScreen({super.key});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen>
    with TickerProviderStateMixin {
  static const LatLng _initialPosition =
      LatLng(37.42796133580664, -122.085749655962);
  late LatLng _currentPosition;
  final MapController _mapController = MapController();
  List<LatLng> _polylinePoints = [];
  LatLng? _simulatedDriverPosition;
  double _simulatedDriverRotation = 0.0;
  int _currentPathIndex = 0;
  String? _lastStatus;
  double _currentEta = 5.0;
  bool _pickupPinRemoved = false;
  bool _showArrivalBanner = false;

  bool _isPaymentProcessing = false;
  bool _isPaymentSuccess = false;
  bool _showRatingModal = false;
  int _ratingStars = 0;
  String _driverName = '';
  final TextEditingController _commentController = TextEditingController();

  AnimationController? _simAnimationController;

  Timer? _searchTimeoutTimer;
  String _assignedDriverName = 'Chauffeur';
  String _assignedDriverRating = '5.0';
  String _assignedVehicleModel = 'Executive VIP Sedan';
  double _selectedTip = 0.0;

  @override
  void initState() {
    super.initState();
    final mem = MapMemory();
    _currentPosition = (mem.hasMemory && mem.lastPosition != null)
        ? mem.lastPosition!
        : _initialPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentPosition, mem.lastZoom);
    });
  }

  @override
  void dispose() {
    _searchTimeoutTimer?.cancel();
    _simAnimationController?.dispose();
    _commentController.dispose();
    MapMemory().save(_currentPosition, _mapController.camera.zoom);
    super.dispose();
  }

  void _startSearchTimer() {
    _searchTimeoutTimer?.cancel();
    _searchTimeoutTimer = Timer(const Duration(minutes: 2), () {
      if (mounted) {
        final rp = Provider.of<RideProvider>(context, listen: false);
        final status = rp.currentRideDetails?['status'] ?? 'requested';
        if (status == 'requested' || status == 'pending') {
          _showSearchTimeoutDialog();
        }
      }
    });
  }

  void _showSearchTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Searching Chauffeur',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'All nearby VIP chauffeurs are currently engaged on active journeys. Would you like to continue searching, schedule your ride for later, or cancel?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final rp = Provider.of<RideProvider>(context, listen: false);
              await rp.cancelCurrentRide(reason: 'Cancelled due to timeout');
              if (mounted) {
                CustomToast.showSuccess(context, 'Ride cancelled');
                context.go('/passenger-home');
              }
            },
            child: const Text('Cancel Request', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final rp = Provider.of<RideProvider>(context, listen: false);
              await rp.cancelCurrentRide(reason: 'Switched to scheduled booking');
              if (mounted) {
                context.push('/schedule-booking');
              }
            },
            child: const Text('Schedule for Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _startSearchTimer();
            },
            child: const Text('Keep Searching', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDriverDetails(String driverId) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, avatar_url')
          .eq('id', driverId)
          .maybeSingle();

      final details = await Supabase.instance.client
          .from('driver_details')
          .select('rating, total_rides')
          .eq('profile_id', driverId)
          .maybeSingle();

      final vehicle = await Supabase.instance.client
          .from('vehicles')
          .select('make, model, year, color, license_plate')
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (profile != null) {
            final first = (profile['first_name'] as String? ?? '').trim();
            final last = (profile['last_name'] as String? ?? '').trim();
            final fullName = '$first $last'.trim();
            _assignedDriverName = fullName.isNotEmpty ? fullName : 'Chauffeur';
            _driverName = _assignedDriverName;
          }
          if (details != null && details['rating'] != null) {
            _assignedDriverRating = (details['rating'] as num).toStringAsFixed(1);
          }
          if (vehicle != null) {
            final make = vehicle['make'] as String? ?? '';
            final model = vehicle['model'] as String? ?? '';
            final color = vehicle['color'] as String? ?? '';
            final plate = vehicle['license_plate'] as String?;
            _assignedVehicleModel = '$make $model${color.isNotEmpty ? ' · $color' : ''}${plate != null ? ' ($plate)' : ''}';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _handleCancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Ride Request?'),
        content: const Text('Are you sure you want to cancel your VIP chauffeur request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Searching'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final rp = Provider.of<RideProvider>(context, listen: false);
        await rp.cancelCurrentRide(reason: 'Cancelled by passenger');
        _searchTimeoutTimer?.cancel();
        if (mounted) {
          CustomToast.showSuccess(context, 'Ride request cancelled');
          context.go('/passenger-home');
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(context, 'Failed to cancel: $e');
        }
      }
    }
  }

  double _fareFrom(dynamic details) {
    if (details == null) return 200.0;
    final raw = details['fare_amount'];
    if (raw == null) return 200.0;
    return (raw as num).toDouble();
  }

  LatLng? _parsePoint(dynamic point) {
    if (point == null) return null;
    if (point is Map) {
      final coords = point['coordinates'];
      if (coords is List && coords.length >= 2) {
        return LatLng(
          double.tryParse(coords[1].toString()) ?? 37.42796133580664,
          double.tryParse(coords[0].toString()) ?? -122.085749655962,
        );
      }
    }
    final pointStr = point.toString();
    final regExp = RegExp(r'POINT\s*\(\s*([-\d\.]+)\s+([-\d\.]+)\s*\)');
    final match = regExp.firstMatch(pointStr);
    if (match != null) {
      final lng = double.tryParse(match.group(1) ?? '');
      final lat = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  List<LatLng> _generatePath(LatLng start, LatLng end, int steps) {
    final List<LatLng> path = [];
    final pt1 = LatLng(start.latitude, end.longitude);

    final halfSteps = steps ~/ 2;
    for (int i = 0; i <= halfSteps; i++) {
      final t = i / halfSteps;
      final lat = start.latitude + (pt1.latitude - start.latitude) * t;
      final lng = start.longitude + (pt1.longitude - start.longitude) * t;
      path.add(LatLng(lat, lng));
    }
    for (int i = 1; i <= halfSteps; i++) {
      final t = i / halfSteps;
      final lat = pt1.latitude + (end.latitude - pt1.latitude) * t;
      final lng = pt1.longitude + (end.longitude - pt1.longitude) * t;
      path.add(LatLng(lat, lng));
    }
    return path;
  }

  double _calculateAngle(LatLng current, LatLng next) {
    final dy = next.latitude - current.latitude;
    final dx = next.longitude - current.longitude;
    return atan2(dx, dy) * 180 / pi;
  }

  Future<void> _handleStatusChange(String status) async {
    _lastStatus = status;

    _simAnimationController?.stop();
    _simAnimationController?.dispose();
    _simAnimationController = null;

    final rideProv = Provider.of<RideProvider>(context, listen: false);
    final pickupRaw = rideProv.currentRideDetails?['pickup_location'];
    final dropoffRaw = rideProv.currentRideDetails?['dropoff_location'];

    final pickup =
        _parsePoint(pickupRaw) ?? const LatLng(37.42796133580664, -122.085749655962);
    final dropoff =
        _parsePoint(dropoffRaw) ?? const LatLng(37.43296265331129, -122.08832357078792);

    if (status == 'requested' || status == 'pending') {
      _startSearchTimer();
      setState(() {
        _polylinePoints = [pickup, dropoff];
        _simulatedDriverPosition = null;
        _pickupPinRemoved = false;
        _showArrivalBanner = false;
        _currentEta = 5.0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MapAnimator.smoothMove(_mapController, pickup, zoom: 14.5);
      });
    } else if (status == 'arriving') {
      _searchTimeoutTimer?.cancel();
      final driverId = rideProv.currentRideDetails?['driver_id'] as String?;
      if (driverId != null) {
        _fetchDriverDetails(driverId);
      }
      final startPt =
          LatLng(pickup.latitude + 0.003, pickup.longitude - 0.003);
      _polylinePoints = _generatePath(startPt, pickup, 30);
      _pickupPinRemoved = false;
      _showArrivalBanner = false;
      _currentEta = 3.0;

      _simAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 12),
      );

      _simAnimationController!.addListener(() {
        final t = _simAnimationController!.value;
        final index = (t * (_polylinePoints.length - 1)).floor();
        if (mounted) {
          setState(() {
            _currentPathIndex = index;
            _simulatedDriverPosition = _polylinePoints[index];
            _currentEta = (3.0 * (1.0 - t)).clamp(0.1, 3.0);

            if (index < _polylinePoints.length - 1) {
              _simulatedDriverRotation = _calculateAngle(
                  _polylinePoints[index], _polylinePoints[index + 1]);
            }

            MapAnimator.smoothMove(
                _mapController, _simulatedDriverPosition!,
                zoom: 15.2, duration: 400);

            if (t >= 0.70 && !_showArrivalBanner) {
              _showArrivalBanner = true;
            }
          });
        }
      });
      _simAnimationController!.forward();

    } else if (status == 'in_progress') {
      _searchTimeoutTimer?.cancel();
      final driverId = rideProv.currentRideDetails?['driver_id'] as String?;
      if (driverId != null) {
        _fetchDriverDetails(driverId);
      }
      _polylinePoints = _generatePath(pickup, dropoff, 40);
      _pickupPinRemoved = true;
      _showArrivalBanner = false;
      _currentEta = 8.0;

      _simAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 16),
      );

      _simAnimationController!.addListener(() {
        final t = _simAnimationController!.value;
        final index = (t * (_polylinePoints.length - 1)).floor();
        if (mounted) {
          setState(() {
            _currentPathIndex = index;
            _simulatedDriverPosition = _polylinePoints[index];
            _currentEta = (8.0 * (1.0 - t)).clamp(0.1, 8.0);

            if (index < _polylinePoints.length - 1) {
              _simulatedDriverRotation = _calculateAngle(
                  _polylinePoints[index], _polylinePoints[index + 1]);
            }

            final turnIndex = _polylinePoints.length ~/ 2;
            final distToTurn = (index - turnIndex).abs();
            double zoom = 14.8;
            if (distToTurn < 6) {
              zoom = 16.5;
            }

            MapAnimator.smoothMove(
                _mapController, _simulatedDriverPosition!,
                zoom: zoom, duration: 400);
          });
        }
      });
      _simAnimationController!.forward();

    } else if (status == 'completed') {
      _searchTimeoutTimer?.cancel();
      setState(() {
        _isPaymentProcessing = true;
        _isPaymentSuccess = false;
        _showRatingModal = false;
      });

      final driverId = rideProv.currentRideDetails?['driver_id'] as String?;
      if (driverId != null) {
        Supabase.instance.client
            .from('profiles')
            .select('first_name')
            .eq('id', driverId)
            .maybeSingle()
            .then((data) {
          if (data != null && mounted) {
            setState(() => _driverName = data['first_name'] as String? ?? '');
          }
        });
      }

      final rideId = rideProv.currentRideDetails?['id'] as String?;
      if (rideId != null) {
        final payProv = Provider.of<PaymentProvider>(context, listen: false);
        final result = await payProv.captureRidePayment(rideId: rideId);
        if (mounted) {
          setState(() {
            _isPaymentProcessing = false;
            _isPaymentSuccess = result['success'] == true;
          });
          if (result['success'] != true) {
            CustomToast.showError(context, result['error'] ?? 'Payment capture failed');
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isPaymentProcessing = false;
            _isPaymentSuccess = true;
          });
        }
      }

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _showRatingModal = true;
          });
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rideProv = Provider.of<RideProvider>(context);
    final status = rideProv.currentRideDetails?['status'] ?? 'requested';
    if (status != _lastStatus) {
      _handleStatusChange(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideProv = Provider.of<RideProvider>(context);
    final status = rideProv.currentRideDetails?['status'] ?? 'requested';
    final isSearching = status == 'requested';
    final isActive = status == 'in_progress' || status == 'arriving';
    final isInProgress = status == 'in_progress';
    final isCompleted = status == 'completed';

    final pickupRaw = rideProv.currentRideDetails?['pickup_location'];
    final dropoffRaw = rideProv.currentRideDetails?['dropoff_location'];
    final pickup =
        _parsePoint(pickupRaw) ?? const LatLng(37.42796133580664, -122.085749655962);
    final dropoff =
        _parsePoint(dropoffRaw) ?? const LatLng(37.43296265331129, -122.08832357078792);
    final fare = _fareFrom(rideProv.currentRideDetails);

    return Scaffold(
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
              onPositionChanged: (position, hasGesture) {
                _currentPosition = position.center;
              },
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
              PolylineLayer(
                polylines: [
                  Polyline(
                    points:
                        _polylinePoints.isNotEmpty ? _polylinePoints : [pickup, dropoff],
                    color: isInProgress
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.4),
                    strokeWidth: isInProgress ? 4.5 : 3.0,
                  ),
                  if (rideProv.driverPosition != null && (status == 'arriving' || status == 'accepted'))
                    Polyline(
                      points: [rideProv.driverPosition!, pickup],
                      color: Colors.green.withValues(alpha: 0.5),
                      strokeWidth: 3.0,
                    ),
                  if (rideProv.driverPosition != null && status == 'in_progress')
                    Polyline(
                      points: [rideProv.driverPosition!, dropoff],
                      color: AppColors.primary,
                      strokeWidth: 4.0,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_simulatedDriverPosition == null && rideProv.driverPosition == null)
                    AnimatedMarker.locationDot(
                        point: pickup, color: AppColors.primary),
                  AnimatedMarker.pickupPin(
                    point: pickup,
                    animateOut: _pickupPinRemoved,
                  ),
                  AnimatedMarker.dropoffPin(point: dropoff),
                  if (rideProv.driverPosition != null)
                    AnimatedMarker.driverCar(
                      point: rideProv.driverPosition!,
                      isStationary: status == 'arriving',
                    )
                  else if (_simulatedDriverPosition != null)
                    AnimatedMarker.driverCar(
                      point: _simulatedDriverPosition!,
                      rotationAngle: _simulatedDriverRotation,
                      isStationary: status == 'arriving' &&
                          _currentPathIndex >= _polylinePoints.length - 2,
                    ),
                ],
              ),
            ],
          ),

          if (!isCompleted)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: RideSearchIndicator(
                isSearching: isSearching,
                searchingText: 'Finding your chauffeur',
                foundText: status == 'arriving'
                    ? 'Chauffeur is arriving'
                    : 'Trip in progress',
                driverName: _assignedDriverName,
                driverRating: _assignedDriverRating,
                carModel: _assignedVehicleModel,
                eta: _currentEta.ceil().toString(),
                onCancelSearch: _handleCancelRide,
                onContactDriver: () {
                  ActiveTripChatSheet.show(context, _assignedDriverName);
                },
              ),
            ),

          if (!isCompleted)
            Consumer<RideProvider>(
              builder: (context, rp, child) {
                if (isActive) {
                  return _buildActiveTripCard(isDark, rp, fare);
                }
                if (isSearching) {
                  return _buildDraggableSheet(isDark, rp, fare);
                }
                return const SizedBox.shrink();
              },
            ),

          if (_showArrivalBanner && status == 'arriving' && !isCompleted)
            Positioned(
              top: 190,
              left: 24,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Chauffeur has arrived!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Michael is waiting at your pickup point.',
                            style: TextStyle(
                              color: AppColors.black.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(
                  begin: -0.5, end: 0, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 200.ms),
            ),

          if (isCompleted) ...[
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ).animate().fadeIn(duration: 300.ms),
            ),
            if (_isPaymentProcessing)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildPaymentProcessingCard(isDark),
              ),
            if (_isPaymentSuccess && !_showRatingModal)
              Align(
                child: _buildPaymentSuccessCard(isDark, fare),
              ),
            if (_showRatingModal)
              Align(
                child: _buildInlineRatingModal(isDark, rideProv),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTripCard(bool isDark, RideProvider rp, double fare) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ActiveTripCard(
        passengerName: 'You',
        pickupAddress:
            rp.currentRideDetails?['pickup_address'] ?? 'Pickup',
        dropoffAddress:
            rp.currentRideDetails?['dropoff_address'] ?? 'Dropoff',
        fare: fare.toStringAsFixed(2),
        status: _lastStatus ?? 'requested',
        timeElapsed: '12:30',
        onEndRide: () async {
          final rideId = rp.currentRideDetails?['id'] as String?;
          if (rideId != null) {
            try {
              await Supabase.instance.client
                  .from('rides')
                  .update({'status': 'completed'}).eq('id', rideId);
            } catch (_) {}
          }
        },
        onContact: () {
          ActiveTripChatSheet.show(context, _assignedDriverName);
        },
      ),
    );
  }

  Widget _buildDraggableSheet(bool isDark, RideProvider rp, double fare) {
    final pickup = rp.currentRideDetails?['pickup_address'] ?? 'From';
    final dropoff = rp.currentRideDetails?['dropoff_address'] ?? 'To';
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    double contentHeight = 0;
    contentHeight += 4 + 20;
    contentHeight += 12 + 16;
    contentHeight += 16 + 60;
    contentHeight += 16 + 60;
    contentHeight += 20;
    contentHeight += 100;
    contentHeight += 16;
    contentHeight += 60;
    contentHeight += 8;
    contentHeight += 16;
    contentHeight += 52;
    contentHeight += 20;
    final estimatedSheetHeight = contentHeight + 48;
    final initialChildSize =
        ((estimatedSheetHeight + bottomPad) / screenHeight).clamp(0.15, 0.85);

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: 0.12,
      maxChildSize: initialChildSize,
      snap: true,
      snapSizes: [initialChildSize.clamp(0.12, 0.85)],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Trip summary',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.person,
                  'Number of passengers',
                  '1',
                  isDark,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.grey.shade900 : const Color(0xFFF9F8F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _buildLocationRow(
                          Icons.my_location, Colors.green, pickup, isDark),
                      Padding(
                        padding: const EdgeInsets.only(left: 9),
                        child: SizedBox(
                          height: 14,
                          child: VerticalDivider(
                              width: 2,
                              thickness: 2,
                              color: Colors.grey.shade300),
                        ),
                      ),
                      _buildLocationRow(
                          Icons.location_on, Colors.red, dropoff, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FareDisplay(amount: '\$${fare.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/payment-method'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : const Color(0xFFF9F8F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.credit_card,
                            size: 16,
                            color: isDark ? AppColors.white : Colors.black87),
                        const SizedBox(width: 10),
                        Text(
                          'Payment method',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Payment will be processed after the ride',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  title: 'Cancel Request',
                  onPress: _handleCancelRide,
                  variant: ButtonVariant.outline,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF9F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: isDark ? AppColors.white : Colors.black87),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, Color iconColor, String address, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentProcessingCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Processing VIP Ride Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Finalizing invoice details securely...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Column(
            children: [
              Row(
                children: [
                  ShimmerText(width: 80, height: 12),
                  Spacer(),
                  ShimmerText(width: 50, height: 12),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  ShimmerText(width: 100, height: 12),
                  Spacer(),
                  ShimmerText(width: 40, height: 12),
                ],
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Row(
                children: [
                  ShimmerText(width: 60),
                  Spacer(),
                  ShimmerText(width: 70, height: 16),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 30),
          const CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ).animate().slideY(
        begin: 0.5, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildPaymentSuccessCard(bool isDark, double fare) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 40,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'Payment Successful',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${fare.toStringAsFixed(2)} debited from VIP Card',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Fare',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('\$${(fare * 0.9).toStringAsFixed(2)}',
                  style:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('VIP Lounge Surcharge',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('\$${(fare * 0.1).toStringAsFixed(2)}',
                  style:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 200.ms);
  }

  Widget _buildInlineRatingModal(bool isDark, RideProvider rideProv) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How was your VIP ride?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rate your experience with your chauffeur${_driverName.isNotEmpty ? ", $_driverName" : ""}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              final isLit = star <= _ratingStars;
              return GestureDetector(
                onTap: () {
                  setState(() => _ratingStars = star);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isLit ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 38,
                    color: isLit ? Colors.amber : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : const Color(0xFFF9F8F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              scrollPadding: const EdgeInsets.only(bottom: 10),
              controller: _commentController,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              decoration: const InputDecoration(
                hintText: 'Add a comment (optional)...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Chauffeur Gratuity',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [0.0, 5.0, 10.0, 20.0].map((amount) {
              final isSel = _selectedTip == amount;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    amount == 0.0 ? 'No Tip' : '\$${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.black : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) setState(() => _selectedTip = amount);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          CustomButton(
            title: 'Submit Review',
            onPress: () async {
              final ride = rideProv.currentRideDetails;
              final user = Supabase.instance.client.auth.currentUser;
              final bookingProv = context.read<BookingProvider>();

              if (ride == null || user == null || _ratingStars == 0) {
                if (mounted) CustomToast.showError(context, 'Please select a rating');
                return;
              }
              try {
                await ReviewRepository().submitReview(
                  rideId: ride['id'],
                  reviewerId: user.id,
                  revieweeId: ride['driver_id'],
                  rating: _ratingStars,
                  comment: _commentController.text.isNotEmpty ? _commentController.text : null,
                );
                if (mounted) CustomToast.showSuccess(context, 'Rating submitted!');
              } catch (e) {
                if (mounted) CustomToast.showError(context, 'Failed to submit review: $e');
              }

              bookingProv.setTip(_selectedTip);
              final fare = _fareFrom(ride);
              final rideId = ride['id'] as String? ?? 'RIDE';
              final pickupAddr = ride['pickup_address'] as String? ?? bookingProv.pickupAddress ?? '';
              final dropoffAddr = ride['dropoff_address'] as String? ?? bookingProv.dropoffAddress ?? '';
              final vType = bookingProv.vehicleType;

              rideProv.clearRide();
              if (mounted) {
                context.push('/booking-invoice', extra: {
                  'rideId': rideId,
                  'fareAmount': fare,
                  'tipAmount': _selectedTip,
                  'taxAmount': 0.0,
                  'totalAmount': fare + _selectedTip,
                  'pickupAddress': pickupAddr,
                  'dropoffAddress': dropoffAddr,
                  'vehicleType': vType,
                  'tripDate': DateTime.now().toString().substring(0, 10),
                  'bookingConfirmation': 'BK-${rideId.substring(0, min(8, rideId.length)).toUpperCase()}',
                  'invoiceNumber': 'KLX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                });
              }
            },
            variant: ButtonVariant.primary,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              final ride = rideProv.currentRideDetails;
              final bookingProv = context.read<BookingProvider>();
              bookingProv.setTip(_selectedTip);
              final fare = _fareFrom(ride);
              final rideId = ride?['id'] as String? ?? 'RIDE';
              final pickupAddr = ride?['pickup_address'] as String? ?? bookingProv.pickupAddress ?? '';
              final dropoffAddr = ride?['dropoff_address'] as String? ?? bookingProv.dropoffAddress ?? '';
              final vType = bookingProv.vehicleType;

              rideProv.clearRide();
              if (mounted) {
                context.push('/booking-invoice', extra: {
                  'rideId': rideId,
                  'fareAmount': fare,
                  'tipAmount': _selectedTip,
                  'taxAmount': 0.0,
                  'totalAmount': fare + _selectedTip,
                  'pickupAddress': pickupAddr,
                  'dropoffAddress': dropoffAddr,
                  'vehicleType': vType,
                  'tripDate': DateTime.now().toString().substring(0, 10),
                  'bookingConfirmation': 'BK-${rideId.substring(0, min(8, rideId.length)).toUpperCase()}',
                  'invoiceNumber': 'KLX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                });
              }
            },
            child: const Text('Skip Rating',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 200.ms);
  }
}
