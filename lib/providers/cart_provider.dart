import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

class CartState {
  final List<CartItem> items;

  const CartState({required this.items});

  factory CartState.empty() => const CartState(items: []);

  bool get isEmpty => items.isEmpty;

  double get total =>
      items.fold(0, (s, i) => s + i.item.price * i.quantity);

  Map<String, List<CartItem>> get itemsByRestaurant {
    final map = <String, List<CartItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.item.restaurantId, () => []);
      map[item.item.restaurantId]!.add(item);
    }
    return map;
  }

  // ================= RECEIPT CALCULATIONS =================

  double restaurantSubtotal(String restaurantId) {
    return items
        .where((i) => i.item.restaurantId == restaurantId)
        .fold(0, (s, i) => s + i.item.price * i.quantity);
  }

  double get deliveryFee => itemsByRestaurant.length * 20.0;
  double get serviceFee => total * 0.05;
  double get tax => total * 0.14;

  double get grandTotal => total + deliveryFee + serviceFee + tax;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.empty());

  void addItem(MenuItem item) {
    final index =
        state.items.indexWhere((e) => e.item.id == item.id);

    if (index != -1) {
      final updated = [...state.items];
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = CartState(items: updated);
    } else {
      state = CartState(
        items: [...state.items, CartItem(item: item, quantity: 1)],
      );
    }
  }

  void increaseQuantity(String id) {
    state = CartState(
      items: state.items
          .map((i) =>
              i.item.id == id ? i.copyWith(quantity: i.quantity + 1) : i)
          .toList(),
    );
  }

  void decreaseQuantity(String id) {
    state = CartState(
      items: state.items
          .map((i) =>
              i.item.id == id ? i.copyWith(quantity: i.quantity - 1) : i)
          .where((i) => i.quantity > 0)
          .toList(),
    );
  }

  void removeItem(String id) {
    state = CartState(
      items: state.items.where((i) => i.item.id != id).toList(),
    );
  }

  void restoreItem(CartItem item) {
    state = CartState(
      items: [...state.items, item],
    );
  }

  void clearCart() {
    state = CartState.empty();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);