import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_cart_item_model.dart';
import '../services/supabase_service.dart';

final sharedCartItemsProvider =
    StateNotifierProvider.family<
      SharedCartItemsNotifier,
      AsyncValue<List<SharedCartItem>>,
      String
    >((ref, cartId) => SharedCartItemsNotifier(cartId));

class SharedCartItemsNotifier
    extends StateNotifier<AsyncValue<List<SharedCartItem>>> {
  final String cartId;
  RealtimeChannel? _itemsChannel;
  SharedCartItemsNotifier(this.cartId) : super(const AsyncLoading()) {
      _loadItems();
     _listenToItems();
  }

  Future<void> _loadItems() async {
  try {
    final cartItemsRes = await SupabaseService.client
        .from('shared_cart_items')
        .select('id, user_id, quantity, menu_items(name, price)')
        .eq('cart_id', cartId);

    final cartItems = (cartItemsRes as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final userIds = cartItems.map((e) => e['user_id'] as String).toSet().toList();

    if (userIds.isEmpty) {
      state = AsyncData([]);
      return;
    }

    // ✅ Correct UUID filter
    final profilesRes = await SupabaseService.client
        .from('profiles')
        .select('id, full_name')
        .filter('id', 'in', '(${userIds.join(",")})');

    final profilesMap = <String, String>{};
    for (var p in profilesRes as List<dynamic>) {
      final map = p as Map<String, dynamic>;
      profilesMap[map['id']] = map['full_name'] ?? 'User';
    }

    final items = cartItems.map((e) {
      return SharedCartItem(
        id: e['id'],
        userId: e['user_id'],
        userName: profilesMap[e['user_id']] ?? 'User',
        menuItemName: e['menu_items']['name'],
        price: (e['menu_items']['price'] as num).toDouble(),
        quantity: e['quantity'],
      );
    }).toList();
    
    state = AsyncData(items);
    
  } catch (e, st) {
    print('Error loading cart items: $e');
    state = AsyncError(e, st);
  }
}

  Future<void> increaseQuantity(String cartItemId, int currentQuantity) async {
    await SupabaseService.client
        .from('shared_cart_items')
        .update({'quantity': currentQuantity + 1})
        .eq('id', cartItemId);
    await _loadItems();
  }

  Future<void> decreaseQuantity(String cartItemId, int currentQuantity) async {
    if (currentQuantity <= 1) {
      await removeItem(cartItemId);
      return;
    }
    await SupabaseService.client
        .from('shared_cart_items')
        .update({'quantity': currentQuantity - 1})
        .eq('id', cartItemId);
    await _loadItems();
  }

  Future<void> removeItem(String cartItemId) async {
    await SupabaseService.client
        .from('shared_cart_items')
        .delete()
        .eq('id', cartItemId);
    await _loadItems();
  }

  void _listenToItems() {
  _itemsChannel?.unsubscribe();

  _itemsChannel =
      SupabaseService.client.channel('shared-cart-items-$cartId');

  // ✅ INSERT + UPDATE (can safely use filter)
  _itemsChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'shared_cart_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'cart_id',
          value: cartId,
        ),
        callback: (_) => _loadItems(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'shared_cart_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'cart_id',
          value: cartId,
        ),
        callback: (_) => _loadItems(),
      )

      // ✅ DELETE (NO FILTER — check manually)
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'shared_cart_items',
        callback: (payload) {
          final old = payload.oldRecord;
          if (old == null) return;

          if (old['cart_id'] == cartId) {
            _loadItems();
          }
        },
      )
      .subscribe();
}




  @override
  void dispose() {
    _itemsChannel?.unsubscribe();
    super.dispose();
  }
}
