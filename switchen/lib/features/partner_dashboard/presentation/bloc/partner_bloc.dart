import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/partner_usecases.dart';

abstract class PartnerEvent extends Equatable { const PartnerEvent(); @override List<Object?> get props => []; }
class LoadPartnerProfile extends PartnerEvent { final String userId; const LoadPartnerProfile(this.userId); @override List<Object> get props => [userId]; }
class AddSurplusProduct extends PartnerEvent { final Map<String, dynamic> data; const AddSurplusProduct(this.data); @override List<Object> get props => [data]; }
class UpdateProductStock extends PartnerEvent { final String productId; final int qty; const UpdateProductStock({required this.productId, required this.qty}); @override List<Object> get props => [productId, qty]; }
class LoadPartnerSales extends PartnerEvent { final String partnerId; const LoadPartnerSales(this.partnerId); @override List<Object> get props => [partnerId]; }

abstract class PartnerState extends Equatable { const PartnerState(); @override List<Object?> get props => []; }
class PartnerInitial extends PartnerState {}
class PartnerLoading extends PartnerState {}
class PartnerProfileLoaded extends PartnerState { final Map<String, dynamic> profile; const PartnerProfileLoaded(this.profile); @override List<Object> get props => [profile]; }
class SurplusAdded extends PartnerState { final Map<String, dynamic> product; const SurplusAdded(this.product); @override List<Object> get props => [product]; }
class StockUpdated extends PartnerState {}
class PartnerSalesLoaded extends PartnerState { final List<Map<String, dynamic>> sales; const PartnerSalesLoaded(this.sales); @override List<Object> get props => [sales]; }
class PartnerError extends PartnerState { final String message; const PartnerError(this.message); @override List<Object> get props => [message]; }

class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final InputSurplus inputSurplus; final UpdateStock updateStock; final GetPartnerSales getPartnerSales; final GetPartnerProfile getPartnerProfile;
  PartnerBloc({required this.inputSurplus, required this.updateStock, required this.getPartnerSales, required this.getPartnerProfile}) : super(PartnerInitial()) {
    on<LoadPartnerProfile>((e, emit) async { emit(PartnerLoading()); final r = await getPartnerProfile(e.userId); r.fold((f) => emit(PartnerError(f.message)), (p) => emit(PartnerProfileLoaded(p))); });
    on<AddSurplusProduct>((e, emit) async { emit(PartnerLoading()); final r = await inputSurplus(e.data); r.fold((f) => emit(PartnerError(f.message)), (p) => emit(SurplusAdded(p))); });
    on<UpdateProductStock>((e, emit) async { emit(PartnerLoading()); final r = await updateStock(UpdateStockParams(productId: e.productId, qty: e.qty)); r.fold((f) => emit(PartnerError(f.message)), (_) => emit(StockUpdated())); });
    on<LoadPartnerSales>((e, emit) async { emit(PartnerLoading()); final r = await getPartnerSales(e.partnerId); r.fold((f) => emit(PartnerError(f.message)), (s) => emit(PartnerSalesLoaded(s))); });
  }
}
