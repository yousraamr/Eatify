import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  SharedCartItemsNotifier(this.cartId) : super(const AsyncLoading()) {
    _loadItems();
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
}
