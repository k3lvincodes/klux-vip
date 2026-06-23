import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kenick_vip/models/ride.dart';
import 'package:kenick_vip/repositories/payment_repository.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/services/location_search_service.dart';
import 'package:latlong2/latlong.dart';

class RideProvider extends ChangeNotifier {
  final RideRepository _rideRepository = RideRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _currentRideId;
  Ride? _currentRide;
  StreamSubscription<Ride>? _rideSubscription;

  LocationSearchResult? _pickupLocation;
  LocationSearchResult? _dropoffLocation;

  LatLng? _driverPosition;
  double _driverHeading = 0.0;
  StreamSubscription<Position>? _positionStream;

  List<LatLng>? _routeToPickup;
  List<LatLng>? _routeToDropoff;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentRideId => _currentRideId;
  Ride? get currentRide => _currentRide;

  Map<String, dynamic>? get currentRideDetails => _currentRide?.toJson();
  LocationSearchResult? get pickupLocation => _pickupLocation;
  LocationSearchResult? get dropoffLocation => _dropoffLocation;
  LatLng? get driverPosition => _driverPosition;
  double get driverHeading => _driverHeading;
  List<LatLng>? get routeToPickup => _routeToPickup;
  List<LatLng>? get routeToDropoff => _routeToDropoff;

  void setPickupDropoff(LocationSearchResult? pickup, LocationSearchResult? dropoff) {
    _pickupLocation = pickup;
    _dropoffLocation = dropoff;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> requestInstantRide({
    required String passengerId,
    required String pickupAddress,
    required String dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    double? fareAmount,
    String? passengerNote,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (pickupLat == null || pickupLng == null || dropoffLat == null || dropoffLng == null || fareAmount == null) {
        throw ArgumentError('pickupLat, pickupLng, dropoffLat, dropoffLng, and fareAmount must not be null');
      }

      final requestId = await _rideRepository.requestRide(
        passengerId: passengerId,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupAddress: pickupAddress,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        dropoffAddress: dropoffAddress,
        fareAmount: fareAmount,
        passengerNote: passengerNote,
      );

      _currentRideId = requestId;
      _currentRide = Ride(
        id: requestId,
        passengerId: passengerId,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupAddress: pickupAddress,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        dropoffAddress: dropoffAddress,
        fareAmount: fareAmount,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _listenToCurrentRide();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptRide({
    required String rideId,
    required String driverId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _rideRepository.acceptRide(rideId, driverId);

      _currentRideId = rideId;
      _listenToCurrentRide();
      _startLocationTracking();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _listenToCurrentRide() {
    if (_currentRideId == null) return;

    _rideSubscription?.cancel();
    _rideSubscription = _rideRepository
        .listenToRide(_currentRideId!)
        .listen(
          (ride) {
            _currentRide = ride;
            if (ride.driverLat != null && ride.driverLng != null) {
              _driverPosition = LatLng(ride.driverLat!, ride.driverLng!);
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error listening to ride: $error');
          },
        );
  }

  Future<void> _startLocationTracking() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      final pos = LatLng(position.latitude, position.longitude);
      _driverPosition = pos;
      _driverHeading = position.heading;
      _broadcastLocation(pos);
      notifyListeners();
    });
  }

  void _broadcastLocation(LatLng pos) {
    if (_currentRideId != null) {
      _rideRepository.updateDriverLocation(
        _currentRideId!,
        pos.latitude,
        pos.longitude,
      );
    }
  }

  Future<void> setRouteToPickup(List<LatLng> points) async {
    _routeToPickup = points;
    notifyListeners();
  }

  Future<void> setRouteToDropoff(List<LatLng> points) async {
    _routeToDropoff = points;
    notifyListeners();
  }

  Future<bool> updateRideStatus(String status) async {
    if (_currentRideId == null) return false;
    try {
      _setLoading(true);
      _setError(null);
      await _rideRepository.updateRideStatus(_currentRideId!, status);

      if (status == 'completed') {
        try {
          final paymentRepo = PaymentRepository();
          await paymentRepo.captureRidePayment(rideId: _currentRideId!);
        } catch (captureErr) {
          debugPrint('Failed to capture payment for ride $_currentRideId: $captureErr');
        }
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearRide() {
    _rideSubscription?.cancel();
    _positionStream?.cancel();
    _currentRideId = null;
    _currentRide = null;
    _driverPosition = null;
    _routeToPickup = null;
    _routeToDropoff = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
