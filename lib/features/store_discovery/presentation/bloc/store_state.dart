import 'package:equatable/equatable.dart';
import '../../domain/entities/store_entity.dart';
abstract class StoreState extends Equatable { const StoreState(); @override List<Object?> get props => []; }
class StoreInitial extends StoreState {}
class StoreLoading extends StoreState {}
class StoresLoaded extends StoreState { final List<StoreEntity> stores; const StoresLoaded(this.stores); @override List<Object> get props => [stores]; }
class StoreDetailLoaded extends StoreState { final StoreEntity store; final List<ProductEntity> products; const StoreDetailLoaded({required this.store, required this.products}); @override List<Object> get props => [store, products]; }
class StoreError extends StoreState { final String message; const StoreError(this.message); @override List<Object> get props => [message]; }
