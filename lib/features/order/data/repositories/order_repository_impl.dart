import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/order_remote_datasource.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  OrderRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, Map<String, dynamic>>> createReservation({required String productId, required String partnerId, required String consumerId, required int qty}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await remoteDataSource.createReservation(productId: productId, partnerId: partnerId, consumerId: consumerId, qty: qty)); }
    catch (e) { return Left(ServerFailure(message: e.toString())); }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getOrderHistory(String consumerId) async {
    try { return Right(await remoteDataSource.getOrderHistory(consumerId)); }
    catch (e) { return Left(ServerFailure(message: e.toString())); }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOrderDetail(String orderId) async {
    try { return Right(await remoteDataSource.getOrderDetail(orderId)); }
    catch (e) { return Left(ServerFailure(message: e.toString())); }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> initiatePayment({required String orderId, required double amount, required String paymentMethod}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try { return Right(await remoteDataSource.initiatePayment(orderId: orderId, amount: amount, paymentMethod: paymentMethod)); }
    catch (e) { return Left(ServerFailure(message: e.toString())); }
  }
}
