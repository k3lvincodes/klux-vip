import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kenick_vip/repositories/ride_repository.dart';
import 'package:kenick_vip/services/location_search_service.dart';

class RideProvider extends ChangeNotifier {
  final RideRepository _rideRepository = RideRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _currentRideId;
  Map<String, dynamic>? _currentRideDetails;
  StreamSubscription? _rideSubscription;

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
  Map<String, dynamic>? get currentRideDetails => _currentRideDetails;
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

      final requestId = await _rideRepository.requestRide(
        passengerId: passengerId,
        pickupLat: pickupLat ?? 37.42796133580664,
        pickupLng: pickupLng ?? -122.085749655962,
        pickupAddress: pickupAddress,
        dropoffLat: dropoffLat ?? 37.43296265331129,
        dropoffLng: dropoffLng ?? -122.08832357078792,
        dropoffAddress: dropoffAddress,
        fareAmount: fareAmount ?? 200.0,
        passengerNote: passengerNote,
      );

      _currentRideId = requestId;
      _currentRideDetails = {
        'id': requestId,
        'fare_amount': fareAmount ?? 200.0,
        'pickup_address': pickupAddress,
        'dropoff_address': dropoffAddress,
        'status': 'pending',
      };

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
          (rideData) {
            _currentRideDetails = rideData;
            final lat = rideData['driver_lat'] as double?;
            final lng = rideData['driver_lng'] as double?;
            if (lat != null && lng != null) {
              _driverPosition = LatLng(lat, lng);
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error listening to ride: $error');
          },
        );
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
    _currentRideDetails = null;
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
