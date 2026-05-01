import 'package:dartz/dartz.dart';
import '../errors/failure.dart';

// Base use case dengan parameter
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Use case tanpa parameter
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

// Use case untuk stream/realtime
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

// Sentinel untuk use case tanpa parameter
class NoParams {}
