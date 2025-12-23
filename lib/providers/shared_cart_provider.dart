import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_cart_model.dart';
import '../services/supabase_service.dart';
import '../core/utils/code_generator.dart';

class SharedCartNotifier extends StateNotifier<AsyncValue<SharedCart?>> {
  SharedCartNotifier() : super(const AsyncValue.data(null));

  final _client = SupabaseService.client;

  // CREATE SHARED CART
  Future<void> createSharedCart({
    required String restaurantId,
  }) async {
    state = const AsyncValue.loading();

    final userId = _client.auth.currentUser!.id;
    final code = generateCartCode();

    final res = await _client
        .from('shared_carts')
        .insert({
          'code': code,
          'owner_id': userId,
          'restaurant_id': restaurantId,
        })
        .select()
        .single();

    state = AsyncValue.data(SharedCart.fromMap(res));
  }

  // JOIN SHARED CART
  Future<void> joinSharedCart(String code) async {
    state = const AsyncValue.loading();
    final userId = _client.auth.currentUser!.id;

    final cartRes = await _client
        .from('shared_carts')
        .select()
        .eq('code', code)
        .eq('is_active', true)
        .single();

    if (cartRes['owner_id'] == userId) {
      throw Exception('OWNER_CANNOT_JOIN');
    }

    final cartId = cartRes['id'];

    final exists = await _client
        .from('shared_cart_members')
        .select()
        .eq('cart_id', cartId)
        .eq('user_id', userId);

    if (exists.isNotEmpty) {
      throw Exception('ALREADY_JOINED');
    }

    await _client.from('shared_cart_members').insert({
      'cart_id': cartId,
      'user_id': userId,
    });

    state = AsyncValue.data(SharedCart.fromMap(cartRes));
  }

  // LEAVE SHARED CART
  Future<void> leaveSharedCart() async {
    final cart = state.value;
    if (cart == null) return;

    final userId = _client.auth.currentUser!.id;

    await _client
        .from('shared_cart_items')
        .delete()
        .eq('cart_id', cart.id)
        .eq('user_id', userId);

    await _client
        .from('shared_cart_members')
        .delete()
        .eq('cart_id', cart.id)
        .eq('user_id', userId);

    state = const AsyncValue.data(null);
  }

  // OWNER DISCARD CART
  Future<void> discardSharedCart() async {
    final cart = state.value;
    if (cart == null) return;

    await _client
        .from('shared_carts')
        .update({'is_active': false})
        .eq('id', cart.id);

    state = const AsyncValue.data(null);
  }

  Future<void> addItemToSharedCart({
  required String menuItemId,
}) async {
  final cart = state.value;
  if (cart == null) return;

  final userId = _client.auth.currentUser!.id;

  final existing = await _client
      .from('shared_cart_items')
      .select()
      .eq('cart_id', cart.id)
      .eq('user_id', userId)
      .eq('menu_item_id', menuItemId);

  if (existing.isNotEmpty) {
    await _client
        .from('shared_cart_items')
        .update({'quantity': existing.first['quantity'] + 1})
        .eq('id', existing.first['id']);
  } else {
    await _client.from('shared_cart_items').insert({
      'cart_id': cart.id,
      'user_id': userId,
      'menu_item_id': menuItemId,
      'quantity': 1,
    });
  }
}

  Future<void> loadActiveSharedCart() async {
  final userId = _client.auth.currentUser!.id;

  // Find active cart where user is a member OR owner
  final res = await _client
      .from('shared_carts')
      .select('id, code, owner_id, restaurant_id, is_active')
      .or(
        'owner_id.eq.$userId,'
        'id.in.(select cart_id from shared_cart_members where user_id = $userId)',
      )
      .eq('is_active', true)
      .maybeSingle();

  if (res == null) {
    state = const AsyncValue.data(null);
    return;
  }

  state = AsyncValue.data(SharedCart.fromMap(res));
}


}

final sharedCartProvider =
    StateNotifierProvider<SharedCartNotifier, AsyncValue<SharedCart?>>(
        (ref) => SharedCartNotifier());

