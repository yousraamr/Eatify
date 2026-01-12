import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final inboxProvider =
    StateNotifierProvider<InboxController, List<String>>(
        (ref) => InboxController());

class InboxController extends StateNotifier<List<String>> {
  RealtimeChannel? _channel;

  InboxController() : super([]) {
    _load();
    _listenRealtime();
  }

  Future<void> _load() async {
    final uid = SupabaseService.client.auth.currentUser!.id;

    final res = await SupabaseService.client
    .from('private_chat_members')
    .select('chat_id, user_id')
    .eq('user_id', uid);

    final blocks = await SupabaseService.client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', uid);

    final blockedIds =
        blocks.map((e) => e['blocked_id']).toSet();

    final filtered = res.where((row) {
      return !blockedIds.contains(row['user_id']);
    }).toList();

    state = filtered
        .map((e) => e['chat_id'] as String)
        .toSet()
        .toList();
  }

  void _listenRealtime() {
    final uid = SupabaseService.client.auth.currentUser!.id;

    _channel =
        SupabaseService.client.channel('inbox:$uid');

    // when someone adds you to a chat
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'private_chat_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) => _load(),
        )

        // when someone removes you
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'private_chat_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) => _load(),
        )

        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      SupabaseService.client.removeChannel(_channel!);
    }
    super.dispose();
  }
}
