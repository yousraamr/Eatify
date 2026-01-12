import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final sharedCartMembersProvider = StateNotifierProvider.family<
    SharedCartMembersController,
    List<Map<String, dynamic>>,
    String>((ref, cartId) {
  return SharedCartMembersController(cartId);
});

class SharedCartMembersController
    extends StateNotifier<List<Map<String, dynamic>>> {
  final String cartId;
  final _client = SupabaseService.client;
  late final RealtimeChannel _membersChannel;
  SharedCartMembersController(this.cartId) : super([]) {
    load();
    _listenToMembers();
  }

    void _listenToMembers() {
  _membersChannel = _client.channel('shared-cart-members-$cartId');

  _membersChannel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'shared_cart_members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'cart_id',
          value: cartId,
        ),
        callback: (_) {
          load(); // auto refresh members
        },
      )
      .subscribe();
}

@override
void dispose() {
  _membersChannel.unsubscribe();
  super.dispose();
}
  Future<void> load() async {
    // load members only
    final membersRes = await SupabaseService.client
        .from('shared_cart_members')
        .select('user_id')
        .eq('cart_id', cartId);

    final members = List<Map<String, dynamic>>.from(membersRes);

    if (members.isEmpty) {
      state = [];
      return;
    }

    // collect user ids
    final ids = members.map((e) => e['user_id']).toList();

    // load profiles separately
    final profilesRes = await SupabaseService.client
        .from('profiles')
        .select('id, username, user_number')
        .inFilter('id', ids);

    final profiles = List<Map<String, dynamic>>.from(profilesRes);

    final profileMap = {
      for (final p in profiles) p['id']: p
    };

    // merge
    state = members.map((m) {
      return {
        'user_id': m['user_id'],
        'profiles': profileMap[m['user_id']],
      };
    }).toList();
  }

  /// ❌ remove a member from cart (OWNER ONLY)
  Future<void> removeMember(String userId) async {
    await SupabaseService.client
        .from('shared_cart_members')
        .delete()
        .eq('cart_id', cartId)
        .eq('user_id', userId);
            final profile = await _client
        .from('profiles')
        .select('username')
        .eq('id', userId)
        .single();

       await SupabaseService.client
        .from('shared_cart_items')
        .delete()
        .eq('cart_id', cartId)
        .eq('user_id', userId);


    final username = profile['username'] ?? 'Someone';
      await _client.from('shared_cart_messages').insert({
      'cart_id': cartId,
      'sender_id': userId,
      'message': '$username was removed from the cart by owner',
      'type': 'system',
    });
    await load(); // refresh
  }
}
