import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId =
      SupabaseService.client.auth.currentUser!.id;

  final res = await SupabaseService.client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res);
});
