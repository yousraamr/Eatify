import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

class CartState {
  final String? restaurantId;
  final List<CartItem> items;

  CartState({this.restaurantId, required this.items});

  factory CartState.empty() => CartState(items: []);

  double get total =>
      items.fold(0, (sum, i) => sum + i.item.price * i.quantity);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.empty());

  bool canAddFromRestaurant(String restaurantId) {
    return state.restaurantId == null ||
        state.restaurantId == restaurantId;
  }

  void addItem(MenuItem item) {
    if (!canAddFromRestaurant(item.restaurantId)) {
      throw Exception('DIFFERENT_RESTAURANT');
    }

    final index =
        state.items.indexWhere((e) => e.item.id == item.id);

    if (index >= 0) {
      final updated = [...state.items];
      updated[index] = updated[index]
          .copyWith(quantity: updated[index].quantity + 1);

      state = CartState(
        restaurantId: state.restaurantId,
        items: updated,
      );
    } else {
      state = CartState(
        restaurantId: item.restaurantId,
        items: [...state.items, CartItem(item: item, quantity: 1)],
      );
    }
  }

  void increaseQuantity(String menuItemId) {
  final updatedItems = state.items.map((i) {
    if (i.item.id == menuItemId) {
      return i.copyWith(quantity: i.quantity + 1);
    }
    return i;
  }).toList();

  state = CartState(items: updatedItems);
}

void decreaseQuantity(String menuItemId) {
  final newItems = state.items
      .map((i) {
        if (i.item.id == menuItemId) {
          return i.copyWith(quantity: i.quantity - 1);
        }
        return i;
      })
      .where((i) => i.quantity > 0)
      .toList();

  state = CartState(items: newItems);
}


void removeItem(String menuItemId) {
  final newItems = state.items
      .where((i) => i.item.id != menuItemId)
      .toList();

  state = CartState(items: newItems);
}

  void clearCart() {
    state = CartState.empty();
  }

  void restoreItem(CartItem item) {
  state = CartState(
    items: [...state.items, item],
  );
}
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>(
        (ref) => CartNotifier());
