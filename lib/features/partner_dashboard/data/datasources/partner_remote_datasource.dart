import 'package:supabase_flutter/supabase_flutter.dart';
abstract class PartnerRemoteDataSource {
  Future<Map<String, dynamic>> getPartnerProfile(String userId);
  Future<Map<String, dynamic>> inputSurplus(Map<String, dynamic> productData);
  Future<void> updateStock(String productId, int qty);
  Future<List<Map<String, dynamic>>> getPartnerSales(String partnerId);
}
class PartnerRemoteDataSourceImpl implements PartnerRemoteDataSource {
  final SupabaseClient _client;
  PartnerRemoteDataSourceImpl(this._client);
  @override Future<Map<String, dynamic>> getPartnerProfile(String userId) async => await _client.from('partners').select().eq('user_id', userId).single();
  @override Future<Map<String, dynamic>> inputSurplus(Map<String, dynamic> productData) async => await _client.from('products').insert(productData).select().single();
  @override Future<void> updateStock(String productId, int qty) async => await _client.from('products').update({'stock_qty': qty, 'updated_at': DateTime.now().toIso8601String()}).eq('id', productId);
  @override Future<List<Map<String, dynamic>>> getPartnerSales(String partnerId) async {
    final data = await _client.from('orders').select('*, products(name, surplus_price)').eq('partner_id', partnerId).eq('status', 'paid').order('reserved_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
