import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
    required super.role,
    super.fcmToken,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String email) {
    return UserModel(
      id: json['id'] as String,
      email: email,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: UserRoleExtension.fromString(json['role'] as String? ?? 'consumer'),
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role.value,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
