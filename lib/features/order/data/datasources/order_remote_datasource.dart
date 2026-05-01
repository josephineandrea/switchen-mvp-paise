import 'package:supabase_flutter/supabase_flutter.dart';

abstract class OrderRemoteDataSource {
  Future<Map<String, dynamic>> createReservation({required String productId, required String partnerId, required String consumerId, required int qty});
  Future<List<Map<String, dynamic>>> getOrderHistory(String consumerId);
  Future<Map<String, dynamic>> getOrderDetail(String orderId);
  Future<Map<String, dynamic>> initiatePayment({required String orderId, required double amount, required String paymentMethod});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient _client;
  OrderRemoteDataSourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> createReservation({required String productId, required String partnerId, required String consumerId, required int qty}) async {
    final product = await _client.from('makanan').select('harga_diskon').eq('id_makanan', productId).single();
    final totalPrice = (product['harga_diskon'] as num).toDouble() * qty;
    final data = await _client.from('pemesanan').insert({
      'id_makanan': productId, 
      'id_pelanggan': consumerId, 
      'jumlah_pesan': qty, 
      'total_harga': totalPrice,
      'metode_pembayaran': 'transfer'
    }).select().single();
    return data;
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String consumerId) async {
    var query = _client.from('pemesanan').select('*, makanan(*, dapur(nama_dapur))');
        
    if (consumerId.isNotEmpty) {
      query = query.eq('id_pelanggan', consumerId);
    }
        
    final data = await query.order('tanggal_pesan', ascending: false);
        
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    return await _client.from('pemesanan').select('*, makanan(*, dapur(*))').eq('id_pesanan', orderId).single();
  }

  @override
  Future<Map<String, dynamic>> initiatePayment({required String orderId, required double amount, required String paymentMethod}) async {
    // Midtrans Sandbox - dibuat via Supabase Edge Function
    final result = await _client.functions.invoke('initiate-payment', body: {'order_id': orderId, 'amount': amount, 'payment_method': paymentMethod});
    return result.data as Map<String, dynamic>;
  }
}
