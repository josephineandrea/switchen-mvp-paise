import 'package:equatable/equatable.dart';
abstract class StoreEvent extends Equatable { const StoreEvent(); @override List<Object?> get props => []; }
class LoadRotatedStores extends StoreEvent { final double lat; final double lng; final String consumerId; const LoadRotatedStores({required this.lat, required this.lng, required this.consumerId}); @override List<Object> get props => [lat, lng, consumerId]; }
class LoadStoreDetail extends StoreEvent { final String storeId; const LoadStoreDetail(this.storeId); @override List<Object> get props => [storeId]; }
class LoadStoreProducts extends StoreEvent { final String storeId; const LoadStoreProducts(this.storeId); @override List<Object> get props => [storeId]; }
