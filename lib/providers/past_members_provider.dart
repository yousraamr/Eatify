import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final pastMembersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = SupabaseService.client.auth.currentUser!.id;

  // Get past member user_ids from RPC
  final res = await SupabaseService.client.rpc(
    'get_past_cart_members',
    params: {'p_user_id': uid},
  );

  final raw = List<Map<String, dynamic>>.from(res);
  if (raw.isEmpty) return [];

  final userIds = raw.map((e) => e['user_id']).toSet().toList();

  // Load profiles
  final profilesRes = await SupabaseService.client
      .from('profiles')
      .select('id, username, user_number')
      .inFilter('id', userIds);

  final profiles = List<Map<String, dynamic>>.from(profilesRes);

  // Build lookup
  final profileMap = {
    for (final p in profiles) p['id']: p,
  };

  // Merge
  return raw.map((e) {
    final profile = profileMap[e['user_id']];
    return {
      'user_id': e['user_id'],
      'username': profile?['username'] ?? 'User',
      'user_number': profile?['user_number'],
    };
  }).toList();
});
