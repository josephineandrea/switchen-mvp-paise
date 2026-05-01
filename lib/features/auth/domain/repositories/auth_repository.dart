import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    UserRole role = UserRole.consumer,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String token,
  });

  Future<Either<Failure, void>> updateFcmToken(String fcmToken);

  Stream<UserEntity?> get authStateChanges;
}
