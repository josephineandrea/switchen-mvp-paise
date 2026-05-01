import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/admin_remote_datasource.dart';
import '../../domain/repositories/admin_repository.dart';
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource; final NetworkInfo networkInfo;
  AdminRepositoryImpl({required this.remoteDataSource, required this.networkInfo});
  @override Future<Either<Failure, List<Map<String, dynamic>>>> getAllPartners() async { try { return Right(await remoteDataSource.getAllPartners()); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
  @override Future<Either<Failure, void>> approvePartner(String id) async { try { await remoteDataSource.approvePartner(id); return const Right(null); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
  @override Future<Either<Failure, void>> suspendPartner(String id) async { try { await remoteDataSource.suspendPartner(id); return const Right(null); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
  @override Future<Either<Failure, Map<String, dynamic>>> getPlatformAnalytics() async { try { return Right(await remoteDataSource.getPlatformAnalytics()); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
  @override Future<Either<Failure, Map<String, dynamic>>> getFoodWasteData() async { try { return Right(await remoteDataSource.getFoodWasteData()); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
  @override Future<Either<Failure, void>> broadcastNotification({required String title, required String body}) async { try { await remoteDataSource.broadcastNotification(title: title, body: body); return const Right(null); } catch (e) { return Left(ServerFailure(message: e.toString())); } }
}
