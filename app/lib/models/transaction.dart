class Transaction {

  Transaction({
    required this.id,
    this.rideId,
    required this.userId,
    required this.amount,
    required this.type,
    this.status = 'pending',
    this.payerId,
    this.payeeId,
    this.stripePaymentIntentId,
    this.stripeTransferId,
    this.deletedAt,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      rideId: json['ride_id'] as String?,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      payerId: json['payer_id'] as String?,
      payeeId: json['payee_id'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      stripeTransferId: json['stripe_transfer_id'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
  final String id;
  final String? rideId;
  final String userId;
  final double amount;
  final String type;
  final String status;
  final String? payerId;
  final String? payeeId;
  final String? stripePaymentIntentId;
  final String? stripeTransferId;
  final DateTime? deletedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'payer_id': payerId,
      'payee_id': payeeId,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'stripe_transfer_id': stripeTransferId,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
