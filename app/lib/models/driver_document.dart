class DriverDocument {

  DriverDocument({
    required this.id,
    required this.driverId,
    required this.type,
    required this.fileUrl,
    this.status = 'pending',
    this.rejectionReason,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      type: json['type'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
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
  final String driverId;
  final String type;
  final String fileUrl;
  final String status;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'type': type,
      'file_url': fileUrl,
      'status': status,
      'rejection_reason': rejectionReason,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
