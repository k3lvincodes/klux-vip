import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/widgets/fare_display.dart';
import 'package:kenick_vip/widgets/ride_search_indicator.dart';
import 'package:kenick_vip/widgets/map/map_memory.dart';
import 'package:kenick_vip/widgets/map/animated_marker.dart';
import 'package:kenick_vip/widgets/map/map_animator.dart';
import 'package:kenick_vip/widgets/active_trip_card.dart';
import 'package:kenick_vip/widgets/active_trip_chat_sheet.dart';
import 'package:kenick_vip/widgets/shimmer_loading.dart';
import 'package:provider/provider.dart';
import 'package:kenick_vip/providers/ride_provider.dart';

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
  final TextEditingController _commentController = TextEditingController();

  AnimationController? _simAnimationController;

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
    _simAnimationController?.dispose();
    _commentController.dispose();
    MapMemory().save(_currentPosition, _mapController.camera.zoom);
    super.dispose();
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

  void _handleStatusChange(String status) {
    _lastStatus = status;

    _simAnimationController?.stop();
    _simAnimationController?.dispose();
    _simAnimationController = null;

    final rideProv = Provider.of<RideProvider>(context, listen: false);
    final pickupRaw = rideProv.currentRideDetails?['pickup_location'];
    final dropoffRaw = rideProv.currentRideDetails?['dropoff_location'];

    final pickup =
        _parsePoint(pickupRaw) ?? LatLng(37.42796133580664, -122.085749655962);
    final dropoff =
        _parsePoint(dropoffRaw) ?? LatLng(37.43296265331129, -122.08832357078792);

    if (status == 'requested') {
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
      setState(() {
        _isPaymentProcessing = true;
        _isPaymentSuccess = false;
        _showRatingModal = false;
      });

      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _isPaymentProcessing = false;
            _isPaymentSuccess = true;
          });
        }

        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) {
            setState(() {
              _showRatingModal = true;
            });
          }
        });
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
        _parsePoint(pickupRaw) ?? LatLng(37.42796133580664, -122.085749655962);
    final dropoff =
        _parsePoint(dropoffRaw) ?? LatLng(37.43296265331129, -122.08832357078792);
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
                    ? "https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}"
                    : "https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
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
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_simulatedDriverPosition == null)
                    AnimatedMarker.locationDot(
                        point: pickup, color: AppColors.primary),
                  AnimatedMarker.pickupPin(
                    point: pickup,
                    animateOut: _pickupPinRemoved,
                  ),
                  AnimatedMarker.dropoffPin(point: dropoff),
                  if (_simulatedDriverPosition != null)
                    AnimatedMarker.driverCar(
                      point: _simulatedDriverPosition!,
                      rotationAngle: _simulatedDriverRotation,
                      size: 40,
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
                driverName: 'Michael',
                driverRating: '4.9',
                driverAvatarUrl: null,
                carModel: 'Mercedes-Benz S-Class · Black VIP',
                eta: _currentEta.ceil().toString(),
                onCancelSearch: () => context.pop(),
                onContactDriver: () {
                  ActiveTripChatSheet.show(context, 'Michael');
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
                alignment: Alignment.center,
                child: _buildPaymentSuccessCard(isDark, fare),
              ),
            if (_showRatingModal)
              Align(
                alignment: Alignment.center,
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
        onEndRide: () {},
        onContact: () {
          ActiveTripChatSheet.show(context, 'Michael');
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
                  title: 'Done',
                  onPress: () {},
                  variant: ButtonVariant.primary,
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
          Column(
            children: [
              Row(
                children: [
                  ShimmerText(width: 80, height: 12),
                  const Spacer(),
                  ShimmerText(width: 50, height: 12),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ShimmerText(width: 100, height: 12),
                  const Spacer(),
                  ShimmerText(width: 40, height: 12),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  ShimmerText(width: 60, height: 14),
                  const Spacer(),
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
          const Text(
            'Rate your active experience with Michael',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
          const SizedBox(height: 24),
          CustomButton(
            title: 'Submit Review',
            onPress: () {
              rideProv.clearRide();
              context.go('/passenger-home');
            },
            variant: ButtonVariant.primary,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              rideProv.clearRide();
              context.go('/passenger-home');
            },
            child: const Text('Skip Rating',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 200.ms);
  }
}
