import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/store_usecases.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final GetRotatedStores getRotatedStores;
  final GetStoreDetail getStoreDetail;
  final GetStoreProducts getStoreProducts;
  final WatchStoreProducts watchStoreProducts;

  StoreBloc({required this.getRotatedStores, required this.getStoreDetail, required this.getStoreProducts, required this.watchStoreProducts}) : super(StoreInitial()) {
    on<LoadRotatedStores>((event, emit) async {
      emit(StoreLoading());
      final result = await getRotatedStores(GetRotatedStoresParams(lat: event.lat, lng: event.lng, consumerId: event.consumerId));
      result.fold((f) => emit(StoreError(f.message)), (stores) => emit(StoresLoaded(stores)));
    });
    on<LoadStoreDetail>((event, emit) async {
      emit(StoreLoading());
      final storeResult = await getStoreDetail(event.storeId);
      final productsResult = await getStoreProducts(event.storeId);
      storeResult.fold(
        (f) => emit(StoreError(f.message)),
        (store) => productsResult.fold(
          (f) => emit(StoreError(f.message)),
          (products) => emit(StoreDetailLoaded(store: store, products: products)),
        ),
      );
    });
  }
}
