import 'package:flutter/material.dart';

class BookingProvider extends ChangeNotifier {
  // Trip details
  String? _pickupAddress;
  String? _dropoffAddress;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _passengerNote;

  // Fare
  double? _fareAmount;
  double? _tipAmount;
  double? _distanceKm;

  // Booking type
  String _bookingType = 'instant';
  DateTime? _scheduledTime;
  String? _eventType;

  // Ride ID
  String? _rideId;

  // Getters
  String? get pickupAddress => _pickupAddress;
  String? get dropoffAddress => _dropoffAddress;
  double? get pickupLat => _pickupLat;
  double? get pickupLng => _pickupLng;
  double? get dropoffLat => _dropoffLat;
  double? get dropoffLng => _dropoffLng;
  String? get passengerNote => _passengerNote;
  double? get fareAmount => _fareAmount;
  double? get tipAmount => _tipAmount;
  double? get distanceKm => _distanceKm;
  String get bookingType => _bookingType;
  DateTime? get scheduledTime => _scheduledTime;
  String? get eventType => _eventType;
  String? get rideId => _rideId;
  double get totalAmount => (_fareAmount ?? 0) + (_tipAmount ?? 0);

  void setTripDetails({
    required String pickupAddress,
    required String dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? passengerNote,
  }) {
    _pickupAddress = pickupAddress;
    _dropoffAddress = dropoffAddress;
    _pickupLat = pickupLat;
    _pickupLng = pickupLng;
    _dropoffLat = dropoffLat;
    _dropoffLng = dropoffLng;
    _passengerNote = passengerNote;
    notifyListeners();
  }

  void setFare(double fare, double? distance) {
    _fareAmount = fare;
    _distanceKm = distance;
    notifyListeners();
  }

  void setTip(double tip) {
    _tipAmount = tip;
    notifyListeners();
  }

  void setBookingType(String type, {DateTime? scheduledTime, String? eventType}) {
    _bookingType = type;
    _scheduledTime = scheduledTime;
    _eventType = eventType;
    notifyListeners();
  }

  void setRideId(String id) {
    _rideId = id;
    notifyListeners();
  }

  void clear() {
    _pickupAddress = null;
    _dropoffAddress = null;
    _pickupLat = null;
    _pickupLng = null;
    _dropoffLat = null;
    _dropoffLng = null;
    _passengerNote = null;
    _fareAmount = null;
    _tipAmount = null;
    _distanceKm = null;
    _bookingType = 'instant';
    _scheduledTime = null;
    _eventType = null;
    _rideId = null;
    notifyListeners();
  }
}
