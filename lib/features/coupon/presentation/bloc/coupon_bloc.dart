import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/coupon_usecases.dart';

abstract class CouponEvent extends Equatable { const CouponEvent(); @override List<Object?> get props => []; }
class LoadCoupon extends CouponEvent { final String orderId; const LoadCoupon(this.orderId); @override List<Object> get props => [orderId]; }
class LoadUserCoupons extends CouponEvent { final String userId; const LoadUserCoupons(this.userId); @override List<Object> get props => [userId]; }
class ScanQrCode extends CouponEvent { final String qrToken; const ScanQrCode(this.qrToken); @override List<Object> get props => [qrToken]; }

abstract class CouponState extends Equatable { const CouponState(); @override List<Object?> get props => []; }
class CouponInitial extends CouponState {}
class CouponLoading extends CouponState {}
class CouponLoaded extends CouponState { final Map<String, dynamic> coupon; const CouponLoaded(this.coupon); @override List<Object> get props => [coupon]; }
class CouponsLoaded extends CouponState { final List<Map<String, dynamic>> coupons; const CouponsLoaded(this.coupons); @override List<Object> get props => [coupons]; }
class CouponValidated extends CouponState { final bool isValid; const CouponValidated(this.isValid); @override List<Object> get props => [isValid]; }
class CouponError extends CouponState { final String message; const CouponError(this.message); @override List<Object> get props => [message]; }

class CouponBloc extends Bloc<CouponEvent, CouponState> {
  final ShowCoupon showCoupon; final GetUserCoupons getUserCoupons; final ValidateCoupon validateCoupon;
  CouponBloc({required this.showCoupon, required this.getUserCoupons, required this.validateCoupon}) : super(CouponInitial()) {
    on<LoadCoupon>((e, emit) async { emit(CouponLoading()); final r = await showCoupon(e.orderId); r.fold((f) => emit(CouponError(f.message)), (c) => emit(CouponLoaded(c))); });
    on<LoadUserCoupons>((e, emit) async { emit(CouponLoading()); final r = await getUserCoupons(e.userId); r.fold((f) => emit(CouponError(f.message)), (c) => emit(CouponsLoaded(c))); });
    on<ScanQrCode>((e, emit) async { emit(CouponLoading()); final r = await validateCoupon(e.qrToken); r.fold((f) => emit(CouponError(f.message)), (v) => emit(CouponValidated(v))); });
  }
}
