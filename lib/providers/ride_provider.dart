import 'dart:async';
import 'package:flutter/material.dart';
import 'package:klux_vip/repositories/ride_repository.dart';

class RideProvider extends ChangeNotifier {
  final RideRepository _rideRepository = RideRepository();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentRideId;
  Map<String, dynamic>? _currentRideDetails;
  StreamSubscription? _rideSubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentRideId => _currentRideId;
  Map<String, dynamic>? get currentRideDetails => _currentRideDetails;

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
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Using dummy coordinates for the prototype
      final rideId = await _rideRepository.requestRide(
        passengerId: passengerId,
        pickupLat: 37.42796133580664,
        pickupLng: -122.085749655962,
        pickupAddress: pickupAddress,
        dropoffLat: 37.43296265331129,
        dropoffLng: -122.08832357078792,
        dropoffAddress: dropoffAddress,
        fareAmount: 200.0,
      );
      
      _currentRideId = rideId;
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
    _rideSubscription = _rideRepository.listenToRide(_currentRideId!).listen(
      (rideData) {
        _currentRideDetails = rideData;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to ride: $error');
      },
    );
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
    _currentRideId = null;
    _currentRideDetails = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }
}
