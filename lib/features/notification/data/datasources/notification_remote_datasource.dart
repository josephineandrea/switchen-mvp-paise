import 'package:supabase_flutter/supabase_flutter.dart';
abstract class NotificationRemoteDataSource {
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId);
  Future<void> markNotificationRead(String notifId);
}
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient _client;
  NotificationRemoteDataSourceImpl(this._client);
  @override Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    final d = await _client.from('notifications').select().eq('user_id', userId).order('sent_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(d);
  }
  @override Future<void> markNotificationRead(String notifId) async => await _client.from('notifications').update({'is_read': true}).eq('id', notifId);
}
