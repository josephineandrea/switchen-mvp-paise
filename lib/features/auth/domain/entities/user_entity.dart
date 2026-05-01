import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final String? fcmToken;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.fcmToken,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, fullName, role];
}

enum UserRole { consumer, partner, admin }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.consumer:
        return 'consumer';
      case UserRole.partner:
        return 'partner';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'partner':
        return UserRole.partner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.consumer;
    }
  }
}
