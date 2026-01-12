import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final cartInvitationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final uid = SupabaseService.client.auth.currentUser!.id;

  final res = await SupabaseService.client
      .from('cart_invitations')
      .select('*, shared_carts(code)')
      .eq('to_user_id', uid)
      .eq('status', 'pending')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res);
});

final invitationControllerProvider = Provider(
  (ref) => InvitationController(ref),
);

class InvitationController {
  final Ref ref;
  InvitationController(this.ref);

  final _client = SupabaseService.client;

  /// Send invite
  Future<void> sendInvitation({
    required String toUserId,
    required String cartId,
  }) async {
    final fromId = _client.auth.currentUser!.id;

    await _client.from('cart_invitations').insert({
      'from_user_id': fromId,
      'to_user_id': toUserId,
      'cart_id': cartId,
    });
  }

  /// Send invite using USER NUMBER instead of UUID
  Future<void> sendInvitationByUserNumber({
    required int toUserNumber,
    required String cartId,
  }) async {
    final fromId = _client.auth.currentUser!.id;

    //  Find user UUID from user_number
    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('user_number', toUserNumber)
        .maybeSingle();

    if (profile == null) {
      throw Exception('User with this ID not found');
    }

    final toUserId = profile['id'];

    //  Send invitation
    await _client.from('cart_invitations').insert({
      'from_user_id': fromId,
      'to_user_id': toUserId,
      'cart_id': cartId,
    });
  }

  /// Accept invite 
  Future<String> acceptInvitation(Map invite) async {
    final cartId = invite['cart_id'];
    final userId = _client.auth.currentUser!.id;

    // 1. Add user to shared_cart_members
    await _client.from('shared_cart_members').insert({
      'cart_id': cartId,
      'user_id': userId,
    });

    // 2. Update invitation status
    await _client
        .from('cart_invitations')
        .update({'status': 'accepted'})
        .eq('id', invite['id']);

    // 3. Add system message
    final profile = await _client
        .from('profiles')
        .select('username')
        .eq('id', userId)
        .single();

    final username = profile['username'] ?? 'Someone';

    await _client.from('shared_cart_messages').insert({
      'cart_id': cartId,
      'sender_id': userId,
      'message': '$username joined the cart',
      'type': 'system',
    });

    // 4. Return the cart ID so we can load it
    return cartId;
  }

  /// Decline invite
  Future<void> declineInvitation(String inviteId) async {
    await _client
        .from('cart_invitations')
        .update({'status': 'declined'})
        .eq('id', inviteId);
  }
}
