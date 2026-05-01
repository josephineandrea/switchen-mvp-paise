import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/notification_remote_datasource.dart';
import '../../domain/repositories/notification_repository.dart';
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource; final NetworkInfo networkInfo;
  NotificationRepositoryImpl({required this.remoteDataSource, required this.networkInfo});
  @override Future<Either<Failure, List<Map<String, dynamic>>>> getUserNotifications(String userId) async { try { return Right(await remoteDataSource.getUserNotifications(userId)); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
  @override Future<Either<Failure, void>> markNotificationRead(String id) async { try { await remoteDataSource.markNotificationRead(id); return const Right(null); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
}
