class Ride {

  Ride({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.status,
    this.type = 'instant',
    this.scheduledTime,
    this.passengerNote,
    required this.fareAmount,
    this.batchStatus,
    this.cancelledBy,
    this.cancelledReason,
    this.driverLat,
    this.driverLng,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup_location'] as String? ?? '';
    final dropoff = json['dropoff_location'] as String? ?? '';
    final pickupCoords = _parsePoint(pickup);
    final dropoffCoords = _parsePoint(dropoff);

    return Ride(
      id: json['id'] as String,
      passengerId: json['passenger_id'] as String,
      driverId: json['driver_id'] as String?,
      pickupLat: json['pickup_lat'] as double? ?? pickupCoords.$1,
      pickupLng: json['pickup_lng'] as double? ?? pickupCoords.$2,
      pickupAddress: json['pickup_address'] as String? ?? '',
      dropoffLat: json['dropoff_lat'] as double? ?? dropoffCoords.$1,
      dropoffLng: json['dropoff_lng'] as double? ?? dropoffCoords.$2,
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      status: json['status'] as String? ?? 'requested',
      type: json['type'] as String? ?? 'instant',
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      passengerNote: json['passenger_note'] as String?,
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 0.0,
      batchStatus: json['batch_status'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledReason: json['cancelled_reason'] as String?,
      driverLat: json['driver_lat'] as double?,
      driverLng: json['driver_lng'] as double?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }
  final String id;
  final String passengerId;
  final String? driverId;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final String status;
  final String type;
  final DateTime? scheduledTime;
  final String? passengerNote;
  final double fareAmount;
  final String? batchStatus;
  final String? cancelledBy;
  final String? cancelledReason;
  final double? driverLat;
  final double? driverLng;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'status': status,
      'type': type,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'passenger_note': passengerNote,
      'fare_amount': fareAmount,
      'batch_status': batchStatus,
      'cancelled_by': cancelledBy,
      'cancelled_reason': cancelledReason,
      'driver_lat': driverLat,
      'driver_lng': driverLng,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  static (double, double) _parsePoint(String wkt) {
    final match = RegExp(r'POINT\(([\d\.\-]+)\s+([\d\.\-]+)\)').firstMatch(wkt);
    if (match != null) {
      return (double.parse(match.group(2)!), double.parse(match.group(1)!));
    }
    return (0.0, 0.0);
  }

  Ride copyWith({
    String? id,
    String? passengerId,
    String? driverId,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
    String? status,
    String? type,
    DateTime? scheduledTime,
    String? passengerNote,
    double? fareAmount,
    String? batchStatus,
    String? cancelledBy,
    String? cancelledReason,
    double? driverLat,
    double? driverLng,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Ride(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      status: status ?? this.status,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      passengerNote: passengerNote ?? this.passengerNote,
      fareAmount: fareAmount ?? this.fareAmount,
      batchStatus: batchStatus ?? this.batchStatus,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
