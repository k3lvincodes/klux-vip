class PaymentMethod {

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.providerToken,
    this.type = 'card',
    this.last4,
    this.stripePmId,
    this.isDefault = false,
    this.deletedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      providerToken: json['provider_token'] as String? ?? '',
      type: json['type'] as String? ?? 'card',
      last4: json['last4'] as String?,
      stripePmId: json['stripe_pm_id'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }
  final String id;
  final String userId;
  final String providerToken;
  final String type;
  final String? last4;
  final String? stripePmId;
  final bool isDefault;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider_token': providerToken,
      'type': type,
      'last4': last4,
      'stripe_pm_id': stripePmId,
      'is_default': isDefault,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
