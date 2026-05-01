import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_datasource.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  StoreRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, List<StoreEntity>>> getRotatedStores({required double lat, required double lng, required String consumerId, double radiusKm = 5.0}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getRotatedStores(lat: lat, lng: lng, consumerId: consumerId, radiusKm: radiusKm);
      return Right(result);
    } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }

  @override
  Future<Either<Failure, StoreEntity>> getStoreDetail(String storeId) async {
    try { return Right(await remoteDataSource.getStoreDetail(storeId)); }
    catch (e) { return Left(ServerFailure(message: e.toString())); }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getStoreProducts(String storeId) async {
    try { return Right(await remoteDataSource.getStoreProducts(storeId)); }
    catch (e) { return Left(ServerFailure(message: e.toString())); }
  }

  @override
  Stream<List<ProductEntity>> watchStoreProducts(String storeId) => remoteDataSource.watchStoreProducts(storeId);
}
