import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/order_usecases.dart';

// Events
abstract class OrderEvent extends Equatable { const OrderEvent(); @override List<Object?> get props => []; }
class CreateOrderRequested extends OrderEvent { final String productId; final String partnerId; final String consumerId; final int qty; const CreateOrderRequested({required this.productId, required this.partnerId, required this.consumerId, required this.qty}); @override List<Object> get props => [productId, qty]; }
class LoadOrderHistory extends OrderEvent { final String consumerId; const LoadOrderHistory(this.consumerId); @override List<Object> get props => [consumerId]; }
class LoadOrderDetail extends OrderEvent { final String orderId; const LoadOrderDetail(this.orderId); @override List<Object> get props => [orderId]; }
class PayOrderRequested extends OrderEvent { final String orderId; final double amount; final String paymentMethod; const PayOrderRequested({required this.orderId, required this.amount, required this.paymentMethod}); @override List<Object> get props => [orderId]; }

// States
abstract class OrderState extends Equatable { const OrderState(); @override List<Object?> get props => []; }
class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}
class OrderCreated extends OrderState { final Map<String, dynamic> order; const OrderCreated(this.order); @override List<Object> get props => [order]; }
class OrderHistoryLoaded extends OrderState { final List<Map<String, dynamic>> orders; const OrderHistoryLoaded(this.orders); @override List<Object> get props => [orders]; }
class OrderDetailLoaded extends OrderState { final Map<String, dynamic> order; const OrderDetailLoaded(this.order); @override List<Object> get props => [order]; }
class PaymentInitiated extends OrderState { final String paymentUrl; const PaymentInitiated(this.paymentUrl); @override List<Object> get props => [paymentUrl]; }
class OrderError extends OrderState { final String message; const OrderError(this.message); @override List<Object> get props => [message]; }

// BLoC
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateReservation createReservation;
  final GetOrderHistory getOrderHistory;
  final GetOrderDetail getOrderDetail;
  final InitiatePayment initiatePayment;

  OrderBloc({required this.createReservation, required this.getOrderHistory, required this.getOrderDetail, required this.initiatePayment}) : super(OrderInitial()) {
    on<CreateOrderRequested>((e, emit) async {
      emit(OrderLoading());
      final result = await createReservation(CreateReservationParams(productId: e.productId, partnerId: e.partnerId, consumerId: e.consumerId, qty: e.qty));
      result.fold((f) => emit(OrderError(f.message)), (order) => emit(OrderCreated(order)));
    });
    on<LoadOrderHistory>((e, emit) async {
      emit(OrderLoading());
      final result = await getOrderHistory(e.consumerId);
      result.fold((f) => emit(OrderError(f.message)), (orders) => emit(OrderHistoryLoaded(orders)));
    });
    on<LoadOrderDetail>((e, emit) async {
      emit(OrderLoading());
      final result = await getOrderDetail(e.orderId);
      result.fold((f) => emit(OrderError(f.message)), (order) => emit(OrderDetailLoaded(order)));
    });
    on<PayOrderRequested>((e, emit) async {
      emit(OrderLoading());
      final result = await initiatePayment(InitiatePaymentParams(orderId: e.orderId, amount: e.amount, paymentMethod: e.paymentMethod));
      result.fold((f) => emit(OrderError(f.message)), (data) => emit(PaymentInitiated(data['payment_url'] ?? '')));
    });
  }
}
