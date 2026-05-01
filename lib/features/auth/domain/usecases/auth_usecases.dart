import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// --- Sign In ---
class SignInParams {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});
}

class SignIn extends UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;
  SignIn(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) =>
      repository.signInWithEmail(email: params.email, password: params.password);
}

// --- Sign Up ---
class SignUpParams {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final UserRole role;
  const SignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    this.role = UserRole.consumer,
  });
}

class SignUp extends UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;
  SignUp(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) =>
      repository.signUpWithEmail(
        email: params.email,
        password: params.password,
        fullName: params.fullName,
        phone: params.phone,
        role: params.role,
      );
}

// --- Sign Out ---
class SignOut extends UseCaseNoParams<void> {
  final AuthRepository repository;
  SignOut(this.repository);

  @override
  Future<Either<Failure, void>> call() => repository.signOut();
}

// --- Get Current User ---
class GetCurrentUser extends UseCaseNoParams<UserEntity> {
  final AuthRepository repository;
  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call() => repository.getCurrentUser();
}

// --- Verify OTP ---
class VerifyOtpParams {
  final String email;
  final String token;
  const VerifyOtpParams({required this.email, required this.token});
}

class VerifyOtp extends UseCase<void, VerifyOtpParams> {
  final AuthRepository repository;
  VerifyOtp(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyOtpParams params) =>
      repository.verifyOtp(email: params.email, token: params.token);
}
