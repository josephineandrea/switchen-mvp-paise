import 'package:supabase/supabase.dart';

Future<void> main() async {
  final supabaseUrl = 'https://zgjjwunocpsucvxzexby.supabase.co';
  final supabaseAnonKey = 'sb_publishable_s9zail3O8TYSyASAY0eVwQ_3tcrUWHu';
  
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  try {
    final buckets = await client.storage.listBuckets();
    print('Buckets:');
    for (var bucket in buckets) {
      print('- ${bucket.id} (public: ${bucket.public})');
    }
  } catch (e) {
    print('Error: $e');
  }
}
