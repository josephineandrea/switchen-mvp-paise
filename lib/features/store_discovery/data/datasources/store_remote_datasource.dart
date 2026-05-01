import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';

abstract class StoreRemoteDataSource {
  Future<List<StoreModel>> getRotatedStores({required double lat, required double lng, required String consumerId, double radiusKm = 5.0});
  Future<StoreModel> getStoreDetail(String storeId);
  Future<List<ProductModel>> getStoreProducts(String storeId);
  Stream<List<ProductModel>> watchStoreProducts(String storeId);
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final SupabaseClient _client;
  StoreRemoteDataSourceImpl(this._client);

  @override
  Future<List<StoreModel>> getRotatedStores({required double lat, required double lng, required String consumerId, double radiusKm = 5.0}) async {
    final data = await _client.functions.invoke('rotation-algo', body: {'consumer_id': consumerId, 'lat': lat, 'lng': lng, 'radius_km': radiusKm});
    final list = data.data as List<dynamic>? ?? [];
    return list.map((e) => StoreModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<StoreModel> getStoreDetail(String storeId) async {
    final data = await _client.from('partners').select().eq('id', storeId).single();
    return StoreModel.fromJson(data);
  }

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId) async {
    final data = await _client.from('products').select().eq('partner_id', storeId).eq('is_active', true).gt('stock_qty', 0);
    return (data as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Stream<List<ProductModel>> watchStoreProducts(String storeId) {
    return _client.from('products').stream(primaryKey: ['id']).eq('partner_id', storeId).map((list) => list.map((e) => ProductModel.fromJson(e)).toList());
  }
}
