import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_cart_model.dart';
import '../services/supabase_service.dart';
import '../core/utils/code_generator.dart';

class SharedCartNotifier extends StateNotifier<AsyncValue<SharedCart?>> {
  SharedCartNotifier() : super(const AsyncValue.data(null));

  final _client = SupabaseService.client;

  RealtimeChannel? _membersChannel;
  RealtimeChannel? _cartChannel;

  bool wasKicked = false;

  /* ===================== LISTENERS ===================== */

  void _listenToMembership(String cartId) {
    _membersChannel?.unsubscribe();

    _membersChannel = _client.channel('shared-cart-members-$cartId');

    _membersChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'shared_cart_members',
          callback: (payload) {
            final old = payload.oldRecord;
            if (old == null) return;

            if (old['user_id'] == _client.auth.currentUser!.id) {
              wasKicked = true;
              state = const AsyncValue.data(null);
            }
          },
        )
        .subscribe();
  }

  void _listenToCartLifecycle(String cartId) {
    _cartChannel?.unsubscribe();

    _cartChannel = _client.channel('shared-cart-$cartId');

    _cartChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'shared_carts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: cartId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow == null) return;

            if (newRow['is_active'] == false) {
              wasKicked = true;
              state = const AsyncValue.data(null);
            }
          },
        )
        .subscribe();
  }

  void _attachListeners(String cartId) {
    wasKicked = false;
    _listenToMembership(cartId);
    _listenToCartLifecycle(cartId);
  }

  void _stopListening() {
    _membersChannel?.unsubscribe();
    _cartChannel?.unsubscribe();
    _membersChannel = null;
    _cartChannel = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  /* ===================== CREATE ===================== */

  Future<void> createSharedCart({required String restaurantId}) async {
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

    final cartId = res['id'];

    await _client.from('shared_cart_members').insert({
      'cart_id': cartId,
      'user_id': userId,
    });

    state = AsyncValue.data(SharedCart.fromMap(res));
    _attachListeners(cartId);
  }

  /* ===================== JOIN ===================== */

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

    if (exists.isEmpty) {
      await _client.from('shared_cart_members').insert({
        'cart_id': cartId,
        'user_id': userId,
      });
    }

    state = AsyncValue.data(SharedCart.fromMap(cartRes));
    _attachListeners(cartId);
  }

  /* ===================== LEAVE ===================== */

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

    _stopListening();
    state = const AsyncValue.data(null);
  }

  /* ===================== OWNER DISCARD ===================== */

  Future<void> discardSharedCart() async {
    final cart = state.value;
    if (cart == null) return;

    await _client
        .from('shared_carts')
        .update({'is_active': false})
        .eq('id', cart.id);
  }

  Future<void> leaveOrDiscard() async {
    final cart = state.value;
    if (cart == null) return;

    if (cart.ownerId == _client.auth.currentUser!.id) {
      await discardSharedCart();
    } else {
      await leaveSharedCart();
    }
  }

  /* ===================== LOADERS ===================== */

  Future<void> loadActiveSharedCart() async {
    try {
      state = const AsyncValue.loading();
      final userId = _client.auth.currentUser!.id;

      final owned = await _client
          .from('shared_carts')
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      if (owned.isNotEmpty) {
        final cart = SharedCart.fromMap(owned.first);
        state = AsyncValue.data(cart);
        _attachListeners(cart.id);
        return;
      }

      final member = await _client
          .from('shared_cart_members')
          .select('cart_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (member.isNotEmpty) {
        final cartId = member.first['cart_id'];

        final cartRes = await _client
            .from('shared_carts')
            .select()
            .eq('id', cartId)
            .eq('is_active', true)
            .maybeSingle();

        if (cartRes != null) {
          final cart = SharedCart.fromMap(cartRes);
          state = AsyncValue.data(cart);
          _attachListeners(cart.id);
          return;
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadExistingCart(String cartId) async {
    try {
      state = const AsyncValue.loading();

      final cartRes = await _client
          .from('shared_carts')
          .select()
          .eq('id', cartId)
          .eq('is_active', true)
          .single();

      state = AsyncValue.data(SharedCart.fromMap(cartRes));
      _attachListeners(cartId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /* ===================== ITEMS ===================== */

  Future<void> addItemToSharedCart({required String menuItemId}) async {
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
}

final sharedCartProvider =
    StateNotifierProvider<SharedCartNotifier, AsyncValue<SharedCart?>>(
  (ref) => SharedCartNotifier(),
);
