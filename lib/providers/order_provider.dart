import 'package:eatify/providers/restaurant_provider.dart';
import 'package:eatify/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../providers/cart_provider.dart';
import '../providers/shared_cart_provider.dart';
import '../providers/address_provider.dart';

final orderProvider = Provider<OrderController>((ref) {
  return OrderController(ref);
});

class OrderController {
  final Ref ref;
  OrderController(this.ref);

  final _client = SupabaseService.client;

  /* -------------------------- PERSONAL CART CHECKOUT -------------------------- */

  Future<String> checkoutPersonalCart({
    required String paymentMethod,
  }) async {
    final cart = ref.read(cartProvider);
    final address = ref.read(selectedAddressProvider);
    final restaurantId = cart.items.first.item.restaurantId;
    final restaurant =
    await fetchRestaurantById(restaurantId);

    if (cart.items.isEmpty) {
      throw Exception('Cart is empty');
    }
    if (address == null) {
      throw Exception('Address not selected');
    }

    final userId = _client.auth.currentUser!.id;

    final orderRes = await _client
    .from('orders')
    .insert({
      'user_id': userId,
      'status': 'confirmed',
      'cart_type': 'personal',
      'total_price': cart.total,
      'address': address.label,
      'payment_method': paymentMethod,

      // ✅ restaurant snapshot
      'restaurant_lat': restaurant.latitude,
      'restaurant_lng': restaurant.longitude,

      // ✅ address snapshot
      'address_lat': address.latitude,
      'address_lng': address.longitude,
    })
    .select()
    .single();

    final orderId = orderRes['id'];

    for (final item in cart.items) {
      await _client.from('order_items').insert({
        'order_id': orderId,
        'menu_item_id': item.item.id,
        'quantity': item.quantity,
        'price': item.item.price,
      });
    }
    await NotificationService.create(
      userId: userId,
      title: 'Order Confirmed',
      body: 'Your order has been confirmed and is being prepared.',
    );
    ref.read(cartProvider.notifier).clearCart();
    return orderId;
  }

  /* --------------------------- SHARED CART CHECKOUT ---------------------------- */

  Future<String> checkoutSharedCart({
    required String paymentMethod,
  }) async {
    final sharedCartAsync = ref.read(sharedCartProvider);
    final address = ref.read(selectedAddressProvider);

    if (sharedCartAsync.value == null) {
      throw Exception('No shared cart');
    }
    if (address == null) {
      throw Exception('Address not selected');
    }

    final cart = sharedCartAsync.value!;
    final userId = _client.auth.currentUser!.id;
    final restaurant = await fetchRestaurantById(
    cart.restaurantId,
    );
    // Only owner can checkout
    if (cart.ownerId != userId) {
      throw Exception('Only cart owner can checkout');
    }

    final items = await _client
        .from('shared_cart_items')
        .select('menu_item_id, quantity, menu_items(price)')
        .eq('cart_id', cart.id);

    if (items.isEmpty) {
      throw Exception('Shared cart is empty');
    }

    double total = 0;
    for (final i in items) {
      total +=
          (i['menu_items']['price'] as num) * i['quantity'];
    }

   final orderRes = await _client
    .from('orders')
    .insert({
      'user_id': userId,
      'status': 'confirmed',
      'cart_type': 'shared',
      'cart_id': cart.id,
      'total_price': total,
      'address': address.label,
      'payment_method': paymentMethod,

      // ✅ restaurant snapshot
      'restaurant_lat': restaurant.latitude,
      'restaurant_lng': restaurant.longitude,

      // ✅ address snapshot
      'address_lat': address.latitude,
      'address_lng': address.longitude,
    })
    .select()
    .single();

    final orderId = orderRes['id'];

    for (final i in items) {
      await _client.from('order_items').insert({
        'order_id': orderId,
        'menu_item_id': i['menu_item_id'],
        'quantity': i['quantity'],
        'price': i['menu_items']['price'],
      });
    }
    await NotificationService.create(
      userId: userId,
      title: 'Order Confirmed',
      body: 'Your order has been confirmed and is being prepared.',
    );
    // Disable cart
    await _client
        .from('shared_carts')
        .update({'is_active': false})
        .eq('id', cart.id);

    ref.read(sharedCartProvider.notifier).leaveSharedCart();
    return orderId;
  }


      Future<void> autoMarkDelivered(
        String orderId, {
        int seconds = 30,
      }) async {
        // Wait delivery duration
        await Future.delayed(Duration(seconds: seconds));

        // Mark as delivered
        await _client
            .from('orders')
            .update({'status': 'delivered'})
            .eq('id', orderId);

       await NotificationService.create(
          userId: _client.auth.currentUser!.id,
          title: 'Order Delivered',
          body: 'Your order has been delivered successfully.',
        );
      }



}

