import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final UserRole role;
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    this.role = UserRole.consumer,
  });
  @override
  List<Object> get props => [email, password, fullName, phone, role];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthOtpVerifyRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthOtpVerifyRequested({required this.email, required this.token});
  @override
  List<Object> get props => [email, token];
}
