import 'package:supabase_flutter/supabase_flutter.dart';
abstract class AdminRemoteDataSource {
  Future<List<Map<String, dynamic>>> getAllPartners();
  Future<void> approvePartner(String partnerId);
  Future<void> suspendPartner(String partnerId);
  Future<Map<String, dynamic>> getPlatformAnalytics();
  Future<Map<String, dynamic>> getFoodWasteData();
  Future<void> broadcastNotification({required String title, required String body});
}
class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final SupabaseClient _client;
  AdminRemoteDataSourceImpl(this._client);
  @override Future<List<Map<String, dynamic>>> getAllPartners() async {
    final d = await _client.from('partners').select('*, profiles(full_name, phone)').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(d);
  }
  @override Future<void> approvePartner(String id) async => await _client.from('partners').update({'status': 'active'}).eq('id', id);
  @override Future<void> suspendPartner(String id) async => await _client.from('partners').update({'status': 'suspended'}).eq('id', id);
  @override Future<Map<String, dynamic>> getPlatformAnalytics() async {
    final orders = await _client.from('orders').select('id, total_price, status');
    final partners = await _client.from('partners').select('id, status');
    return {'total_orders': orders.length, 'total_revenue': orders.fold(0.0, (s, o) => s + (o['total_price'] ?? 0)), 'total_partners': partners.length, 'active_partners': partners.where((p) => p['status'] == 'active').length};
  }
  @override Future<Map<String, dynamic>> getFoodWasteData() async {
    final orders = await _client.from('orders').select('qty, products(name, original_price, surplus_price)').eq('status', 'completed');
    return {'total_saved_orders': orders.length, 'estimated_kg_saved': orders.length * 0.5};
  }
  @override Future<void> broadcastNotification({required String title, required String body}) async => await _client.functions.invoke('send-notification', body: {'broadcast': true, 'title': title, 'body': body});
}
