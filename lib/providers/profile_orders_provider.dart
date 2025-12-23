import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final liveOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId =
      SupabaseService.client.auth.currentUser!.id;

  final res = await SupabaseService.client
      .from('orders')
      .select()
      .eq('user_id', userId)
      .filter(
        'status',
        'in',
        '("confirmed","out_for_delivery")',
      )
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res);
});

final orderHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId =
      SupabaseService.client.auth.currentUser!.id;

  final res = await SupabaseService.client
      .from('orders')
      .select()
      .eq('user_id', userId)
      .eq('status', 'delivered')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res);
});
