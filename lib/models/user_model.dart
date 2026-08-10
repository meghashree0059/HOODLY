/// User model for the Hoodly app.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isVerified;
  final String role;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
    this.isVerified = false,
    this.role = 'user',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['full_name'] ?? json['name'] as String? ?? 'New User',
        email: json['email'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        isVerified: json['is_verified'] as bool? ?? false,
        role: json['role'] as String? ?? 'user',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
        'is_verified': isVerified,
        'role': role,
      };

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isVerified,
    String? role,
  }) =>
      UserModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt ?? this.createdAt,
        isVerified: isVerified ?? this.isVerified,
        role: role ?? this.role,
      );

  @override
  String toString() => 'UserModel(id: $id, email: $email, fullName: $fullName, role: $role)';
}
