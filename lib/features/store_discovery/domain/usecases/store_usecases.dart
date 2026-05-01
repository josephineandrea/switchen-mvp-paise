import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/store_entity.dart';
import '../repositories/store_repository.dart';

// UC-1: Get Rotated Stores
class GetRotatedStoresParams {
  final double lat;
  final double lng;
  final String consumerId;
  final double radiusKm;
  const GetRotatedStoresParams({
    required this.lat,
    required this.lng,
    required this.consumerId,
    this.radiusKm = 5.0,
  });
}

class GetRotatedStores extends UseCase<List<StoreEntity>, GetRotatedStoresParams> {
  final StoreRepository repository;
  GetRotatedStores(this.repository);

  @override
  Future<Either<Failure, List<StoreEntity>>> call(GetRotatedStoresParams params) =>
      repository.getRotatedStores(
        lat: params.lat,
        lng: params.lng,
        consumerId: params.consumerId,
        radiusKm: params.radiusKm,
      );
}

// UC-2: Get Store Detail
class GetStoreDetail extends UseCase<StoreEntity, String> {
  final StoreRepository repository;
  GetStoreDetail(this.repository);

  @override
  Future<Either<Failure, StoreEntity>> call(String storeId) =>
      repository.getStoreDetail(storeId);
}

// Get Store Products
class GetStoreProducts extends UseCase<List<ProductEntity>, String> {
  final StoreRepository repository;
  GetStoreProducts(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(String storeId) =>
      repository.getStoreProducts(storeId);
}

// Watch Store Products (Realtime)
class WatchStoreProducts extends StreamUseCase<List<ProductEntity>, String> {
  final StoreRepository repository;
  WatchStoreProducts(this.repository);

  @override
  Stream<Either<Failure, List<ProductEntity>>> call(String storeId) {
    return repository.watchStoreProducts(storeId).map((products) => Right(products));
  }
}
