import 'package:supabase_flutter/supabase_flutter.dart';
abstract class CouponRemoteDataSource {
  Future<Map<String, dynamic>> showCoupon(String orderId);
  Future<List<Map<String, dynamic>>> getUserCoupons(String userId);
  Future<bool> validateCoupon(String qrToken);
}
class CouponRemoteDataSourceImpl implements CouponRemoteDataSource {
  final SupabaseClient _client;
  CouponRemoteDataSourceImpl(this._client);
  @override
  Future<Map<String, dynamic>> showCoupon(String orderId) async => await _client.from('coupons').select().eq('order_id', orderId).single();
  @override
  Future<List<Map<String, dynamic>>> getUserCoupons(String userId) async {
    final data = await _client.from('coupons').select('*, orders!inner(consumer_id, products(*), partners(name))').eq('orders.consumer_id', userId).order('id', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
  @override
  Future<bool> validateCoupon(String qrToken) async {
    final coupon = await _client.from('coupons').select().eq('qr_token', qrToken).eq('status', 'active').maybeSingle();
    if (coupon == null) return false;
    await _client.from('coupons').update({'status': 'used', 'used_at': DateTime.now().toIso8601String()}).eq('qr_token', qrToken);
    await _client.from('orders').update({'status': 'completed'}).eq('id', coupon['order_id']);
    return true;
  }
}
