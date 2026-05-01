import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
  static SupabaseStorageClient get storage => Supabase.instance.client.storage;

  // Helper: invoke edge function
  static Future<dynamic> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final response = await client.functions.invoke(
      functionName,
      body: body,
    );
    return response.data;
  }
}
