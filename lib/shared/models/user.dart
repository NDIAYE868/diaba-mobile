class UserProfile {
  final int id;
  final String? avatar;
  final String? bio;
  final String? birthDate;

  const UserProfile({
    required this.id,
    this.avatar,
    this.bio,
    this.birthDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    avatar: json['avatar'] as String?,
    bio: json['bio'] as String?,
    birthDate: json['birth_date'] as String?,
  );
}

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role;
  final String? phone;
  final String? address;
  final int? communeId;
  final String? communeName;
  final int? departementId;
  final String? departementName;
  final int? regionId;
  final String? regionName;
  final bool isVerified;
  final bool isActive;
  final UserProfile? profile;
  final String? createdAt;
  final int ordersCount;
  final double totalSpent;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    this.phone,
    this.address,
    this.communeId,
    this.communeName,
    this.departementId,
    this.departementName,
    this.regionId,
    this.regionName,
    required this.isVerified,
    required this.isActive,
    this.profile,
    this.createdAt,
    this.ordersCount = 0,
    this.totalSpent = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      communeId: json['commune_id'] as int?,
      communeName: json['commune_name'] as String?,
      departementId: json['departement_id'] as int?,
      departementName: json['departement_name'] as String?,
      regionId: json['region_id'] as int?,
      regionName: json['region_name'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
      ordersCount: json['orders_count'] as int? ?? 0,
      totalSpent: _parseDouble(json['total_spent']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String get displayName => fullName.isNotEmpty ? fullName : email;
  bool get isClient => role == 'client';

  User copyWith({
    String? phone,
    String? address,
    String? firstName,
    String? lastName,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName,
      role: role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      communeId: communeId,
      communeName: communeName,
      departementId: departementId,
      departementName: departementName,
      regionId: regionId,
      regionName: regionName,
      isVerified: isVerified,
      isActive: isActive,
      profile: profile,
      createdAt: createdAt,
      ordersCount: ordersCount,
      totalSpent: totalSpent,
    );
  }
}
