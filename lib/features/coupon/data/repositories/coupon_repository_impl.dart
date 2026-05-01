import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/coupon_remote_datasource.dart';
import '../../domain/repositories/coupon_repository.dart';
class CouponRepositoryImpl implements CouponRepository {
  final CouponRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  CouponRepositoryImpl({required this.remoteDataSource, required this.networkInfo});
  @override
  Future<Either<Failure, Map<String, dynamic>>> showCoupon(String orderId) async {
    try { return Right(await remoteDataSource.showCoupon(orderId)); } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserCoupons(String userId) async {
    try { return Right(await remoteDataSource.getUserCoupons(userId)); } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
  @override
  Future<Either<Failure, bool>> validateCoupon(String qrToken) async {
    try { return Right(await remoteDataSource.validateCoupon(qrToken)); } catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
}
