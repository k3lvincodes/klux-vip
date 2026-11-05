import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class BookingProvider extends ChangeNotifier {
  // Trip details
  String? _pickupAddress;
  String? _dropoffAddress;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _passengerNote;
  List<LatLng>? _routePoints;

  // Fare
  double? _fareAmount;
  double? _tipAmount;
  double? _distanceKm;

  // Booking type
  String _bookingType = 'instant';
  DateTime? _scheduledTime;
  String? _eventType;
  String _rideType = 'One way';
  DateTime? _returnTime;

  // Airport transfer details
  bool _isAirportTransfer = false;
  String? _airportTransferType; // 'dropoff' or 'pickup'
  String? _airportCode; // e.g. 'IND'
  String? _flightNumber; // e.g. 'LH 202'
  String? _airportPickupMode = 'flight_arrival'; // 'flight_arrival' or 'time'
  int? _flightBufferMinutes = 15; // e.g. 15, 30, 45...

  // Vehicle details
  String _vehicleType = 'GMC Yukon';
  String? _vehicleImage = 'assets/images/GMC.png';

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
  String get rideType => _rideType;
  DateTime? get returnTime => _returnTime;
  bool get isAirportTransfer => _isAirportTransfer;
  String? get airportTransferType => _airportTransferType;
  String? get airportCode => _airportCode;
  String? get flightNumber => _flightNumber;
  String? get airportPickupMode => _airportPickupMode;
  int? get flightBufferMinutes => _flightBufferMinutes;
  String get vehicleType => _vehicleType;
  String? get vehicleImage => _vehicleImage;
  String? get rideId => _rideId;
  List<LatLng>? get routePoints => _routePoints;
  double get totalAmount => (_fareAmount ?? 0) + (_tipAmount ?? 0);

  void setRoutePoints(List<LatLng>? points) {
    _routePoints = points;
    notifyListeners();
  }

  void setVehicle(String type, [String? image]) {
    _vehicleType = type;
    if (image != null) _vehicleImage = image;
    notifyListeners();
  }

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

  void setBookingType(
    String type, {
    DateTime? scheduledTime,
    String? eventType,
    String? rideType,
    DateTime? returnTime,
  }) {
    _bookingType = type;
    _scheduledTime = scheduledTime;
    _eventType = eventType;
    if (rideType != null) _rideType = rideType;
    _returnTime = returnTime;
    notifyListeners();
  }

  void setRideId(String id) {
    _rideId = id;
    notifyListeners();
  }

  void setAirportTransfer({
    required bool isAirportTransfer,
    String? airportTransferType,
    String? airportCode,
    String? flightNumber,
    String? airportPickupMode,
    int? flightBufferMinutes,
  }) {
    _isAirportTransfer = isAirportTransfer;
    _airportTransferType = airportTransferType;
    _airportCode = airportCode;
    _flightNumber = flightNumber;
    _airportPickupMode = airportPickupMode;
    _flightBufferMinutes = flightBufferMinutes;
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
    _routePoints = null;
    _fareAmount = null;
    _tipAmount = null;
    _distanceKm = null;
    _bookingType = 'instant';
    _scheduledTime = null;
    _eventType = null;
    _rideType = 'One way';
    _returnTime = null;
    _isAirportTransfer = false;
    _airportTransferType = null;
    _airportCode = null;
    _flightNumber = null;
    _airportPickupMode = 'flight_arrival';
    _flightBufferMinutes = 15;
    _rideId = null;
    notifyListeners();
  }
}
