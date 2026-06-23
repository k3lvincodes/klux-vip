class AppNotification {

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data,
    this.status = 'pending',
    this.isRead = false,
    this.deliveryStatus = 'pending',
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      isRead: json['is_read'] as bool? ?? false,
      deliveryStatus: json['delivery_status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic>? data;
  final String status;
  final bool isRead;
  final String deliveryStatus;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'status': status,
      'is_read': isRead,
      'delivery_status': deliveryStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
