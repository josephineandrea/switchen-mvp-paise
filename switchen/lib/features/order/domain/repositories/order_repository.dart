import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

abstract class OrderRepository {
  Future<Either<Failure, Map<String, dynamic>>> createReservation({required String productId, required String partnerId, required String consumerId, required int qty});
  Future<Either<Failure, List<Map<String, dynamic>>>> getOrderHistory(String consumerId);
  Future<Either<Failure, Map<String, dynamic>>> getOrderDetail(String orderId);
  Future<Either<Failure, Map<String, dynamic>>> initiatePayment({required String orderId, required double amount, required String paymentMethod});
}
