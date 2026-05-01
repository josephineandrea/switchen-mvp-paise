import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
abstract class CouponRepository {
  Future<Either<Failure, Map<String, dynamic>>> showCoupon(String orderId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserCoupons(String userId);
  Future<Either<Failure, bool>> validateCoupon(String qrToken);
}
