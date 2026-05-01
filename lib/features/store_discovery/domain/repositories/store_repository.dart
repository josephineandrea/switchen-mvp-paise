import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/store_entity.dart';

abstract class StoreRepository {
  Future<Either<Failure, List<StoreEntity>>> getRotatedStores({
    required double lat,
    required double lng,
    required String consumerId,
    double radiusKm = 5.0,
  });

  Future<Either<Failure, StoreEntity>> getStoreDetail(String storeId);

  Future<Either<Failure, List<ProductEntity>>> getStoreProducts(String storeId);

  Stream<List<ProductEntity>> watchStoreProducts(String storeId);
}
