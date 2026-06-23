class UserProfile {

  UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.role,
    this.isSuperAdmin = false,
    this.selfieUrl,
    this.verificationStatus,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.emailVerifiedAt,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.stripeConnectId,
    this.stripeCustomerId,
    this.driverDetails,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      selfieUrl: json['selfie_url'] as String?,
      verificationStatus: json['verification_status'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
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
      stripeConnectId: json['stripe_connect_id'] as String?,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      driverDetails: json['driver_details'] as Map<String, dynamic>?,
    );
  }
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? role;
  final bool isSuperAdmin;
  final String? selfieUrl;
  final String? verificationStatus;
  final double rating;
  final int ratingCount;
  final DateTime? emailVerifiedAt;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? stripeConnectId;
  final String? stripeCustomerId;
  final Map<String, dynamic>? driverDetails;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
      'is_super_admin': isSuperAdmin,
      'selfie_url': selfieUrl,
      'verification_status': verificationStatus,
      'rating': rating,
      'rating_count': ratingCount,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'stripe_connect_id': stripeConnectId,
      'stripe_customer_id': stripeCustomerId,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarUrl,
    String? role,
    bool? isSuperAdmin,
    String? selfieUrl,
    String? verificationStatus,
    double? rating,
    int? ratingCount,
    DateTime? emailVerifiedAt,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? stripeConnectId,
    String? stripeCustomerId,
    Map<String, dynamic>? driverDetails,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      stripeConnectId: stripeConnectId ?? this.stripeConnectId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      driverDetails: driverDetails ?? this.driverDetails,
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    return email;
  }
}
