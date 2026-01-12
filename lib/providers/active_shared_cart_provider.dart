import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final activeSharedCartsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = SupabaseService.client.auth.currentUser!.id;

  final res = await SupabaseService.client
      .from('shared_carts')
      .select('id, code, restaurant_id')
      .eq('owner_id', uid)
      .eq('is_active', true);

  return List<Map<String, dynamic>>.from(res);
});
