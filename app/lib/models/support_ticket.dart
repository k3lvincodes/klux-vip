class SupportTicket {

  SupportTicket({
    required this.id,
    required this.userId,
    this.rideId,
    required this.category,
    required this.subject,
    required this.description,
    this.status = 'open',
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      rideId: json['ride_id'] as String?,
      category: json['category'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      assignedTo: json['assigned_to'] as String?,
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
  final String userId;
  final String? rideId;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ride_id': rideId,
      'category': category,
      'subject': subject,
      'description': description,
      'status': status,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
