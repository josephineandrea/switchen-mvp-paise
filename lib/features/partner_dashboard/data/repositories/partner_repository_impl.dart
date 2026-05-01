import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/partner_remote_datasource.dart';
import '../../domain/repositories/partner_repository.dart';
class PartnerRepositoryImpl implements PartnerRepository {
  final PartnerRemoteDataSource remoteDataSource; final NetworkInfo networkInfo;
  PartnerRepositoryImpl({required this.remoteDataSource, required this.networkInfo});
  @override Future<Either<Failure, Map<String, dynamic>>> getPartnerProfile(String userId) async {
    try { return Right(await remoteDataSource.getPartnerProfile(userId)); } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
  @override Future<Either<Failure, Map<String, dynamic>>> inputSurplus(Map<String, dynamic> d) async {
    try { return Right(await remoteDataSource.inputSurplus(d)); } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
  @override Future<Either<Failure, void>> updateStock(String productId, int qty) async {
    try { await remoteDataSource.updateStock(productId, qty); return const Right(null); } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
  @override Future<Either<Failure, List<Map<String, dynamic>>>> getPartnerSales(String partnerId) async {
    try { return Right(await remoteDataSource.getPartnerSales(partnerId)); } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
}
