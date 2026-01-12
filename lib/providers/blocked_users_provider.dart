import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersController, List<Map<String, dynamic>>>(
        (ref) => BlockedUsersController());

class BlockedUsersController
    extends StateNotifier<List<Map<String, dynamic>>> {
  BlockedUsersController() : super([]) {
    load();
  }

  Future<void> load() async {
    final uid = SupabaseService.client.auth.currentUser!.id;

    final res = await SupabaseService.client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', uid);

    final rows = List<Map<String, dynamic>>.from(res);

    if (rows.isEmpty) {
      state = [];
      return;
    }

    final ids = rows.map((e) => e['blocked_id'] as String).toList();

    final profiles = await SupabaseService.client
        .from('profiles')
        .select('id, username, user_number')
        .inFilter('id', ids);

    state = List<Map<String, dynamic>>.from(profiles);
  }

  Future<void> unblock(String blockedId) async {
    final uid = SupabaseService.client.auth.currentUser!.id;

    await SupabaseService.client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', uid)
        .eq('blocked_id', blockedId);

    await load(); // 🔁 realtime refresh
  }
}
