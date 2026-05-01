import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/coupon_repository.dart';
class ShowCoupon extends UseCase<Map<String, dynamic>, String> {
  final CouponRepository repository; ShowCoupon(this.repository);
  @override Future<Either<Failure, Map<String, dynamic>>> call(String orderId) => repository.showCoupon(orderId);
}
class GetUserCoupons extends UseCase<List<Map<String, dynamic>>, String> {
  final CouponRepository repository; GetUserCoupons(this.repository);
  @override Future<Either<Failure, List<Map<String, dynamic>>>> call(String userId) => repository.getUserCoupons(userId);
}
class ValidateCoupon extends UseCase<bool, String> {
  final CouponRepository repository; ValidateCoupon(this.repository);
  @override Future<Either<Failure, bool>> call(String qrToken) => repository.validateCoupon(qrToken);
}
