import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/order_repository.dart';

class CreateReservationParams { final String productId; final String partnerId; final String consumerId; final int qty; const CreateReservationParams({required this.productId, required this.partnerId, required this.consumerId, required this.qty}); }
class CreateReservation extends UseCase<Map<String, dynamic>, CreateReservationParams> {
  final OrderRepository repository;
  CreateReservation(this.repository);
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(CreateReservationParams params) => repository.createReservation(productId: params.productId, partnerId: params.partnerId, consumerId: params.consumerId, qty: params.qty);
}

class GetOrderHistory extends UseCase<List<Map<String, dynamic>>, String> {
  final OrderRepository repository;
  GetOrderHistory(this.repository);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(String consumerId) => repository.getOrderHistory(consumerId);
}

class GetOrderDetail extends UseCase<Map<String, dynamic>, String> {
  final OrderRepository repository;
  GetOrderDetail(this.repository);
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(String orderId) => repository.getOrderDetail(orderId);
}

class InitiatePaymentParams { final String orderId; final double amount; final String paymentMethod; const InitiatePaymentParams({required this.orderId, required this.amount, required this.paymentMethod}); }
class InitiatePayment extends UseCase<Map<String, dynamic>, InitiatePaymentParams> {
  final OrderRepository repository;
  InitiatePayment(this.repository);
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(InitiatePaymentParams params) => repository.initiatePayment(orderId: params.orderId, amount: params.amount, paymentMethod: params.paymentMethod);
}
