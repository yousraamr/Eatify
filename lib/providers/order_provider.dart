import 'package:eatify/providers/recent_items_provider.dart';
import 'package:eatify/providers/restaurant_provider.dart';
import 'package:eatify/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../providers/shared_cart_provider.dart';
import '../providers/address_provider.dart';
import '../models/cart_item_model.dart';
import '../core/utils/location_utils.dart';

final orderProvider = Provider<OrderController>((ref) {
  return OrderController(ref);
});

class OrderController {
  final Ref ref;
  OrderController(this.ref);

  final _client = SupabaseService.client;

  /* ====================== PERSONAL CART (OPTION B) ====================== */
  /// ONE ORDER PER RESTAURANT
  Future<String> checkoutPersonalCart({
    required String restaurantId,
    required List<CartItem> items,
    required String paymentMethod,
  }) async {
    final address = ref.read(selectedAddressProvider);

    if (items.isEmpty) {
      throw Exception('Cart is empty');
    }
    if (address == null) {
      throw Exception('Address not selected');
    }

    final userId = _client.auth.currentUser!.id;
    final restaurant = await fetchRestaurantById(restaurantId);
    await _ensureWithinDeliveryRange(
      restaurantLat: restaurant.latitude,
      restaurantLng: restaurant.longitude,
      addressLat: address.latitude,
      addressLng: address.longitude,
      restaurantName: restaurant.name,
    );
    /// Calculate total for THIS restaurant
    double total = 0;
    for (final item in items) {
      total += item.item.price * item.quantity;
    }

    /// Create order
    final orderRes = await _client
        .from('orders')
        .insert({
          'user_id': userId,
          'status': 'confirmed',
          'cart_type': 'personal',
          'total_price': total,
          'address': address.label,
          'payment_method': paymentMethod,

          // Restaurant snapshot
          'restaurant_lat': restaurant.latitude,
          'restaurant_lng': restaurant.longitude,

          // Address snapshot
          'address_lat': address.latitude,
          'address_lng': address.longitude,
        })
        .select()
        .single();

    final orderId = orderRes['id'];

    /// Insert order items
    for (final item in items) {
      await _client.from('order_items').insert({
        'order_id': orderId,
        'menu_item_id': item.item.id,
        'quantity': item.quantity,
        'price': item.item.price,
      });
    }

    /// Notification
    await NotificationService.create(
      userId: userId,
      title: 'Order Confirmed',
      body: 'Your order has been confirmed and is being prepared.',
    );
    ref.invalidate(recentItemsProvider);

    return orderId;
  }

  /* ====================== SHARED CART (UNCHANGED) ====================== */

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

    // Only owner can checkout
    if (cart.ownerId != userId) {
      throw Exception('Only cart owner can checkout');
    }

    final restaurant =
        await fetchRestaurantById(cart.restaurantId);

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

          // Restaurant snapshot
          'restaurant_lat': restaurant.latitude,
          'restaurant_lng': restaurant.longitude,

          // Address snapshot
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

    // Disable shared cart
    await _client
        .from('shared_carts')
        .update({'is_active': false})
        .eq('id', cart.id);

    ref.read(sharedCartProvider.notifier).discardSharedCart();
    ref.invalidate(recentItemsProvider);

    return orderId;
  }

  /* ====================== AUTO DELIVERY ====================== */

  Future<void> autoMarkDelivered(
    String orderId, {
    int seconds = 30,
  }) async {  
    await Future.delayed(Duration(seconds: seconds));

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

  Future<void> _ensureWithinDeliveryRange({
  required double restaurantLat,
  required double restaurantLng,
  required double addressLat,
  required double addressLng,
  required String restaurantName,
}) async {
  final distance = calculateDistanceKm(
    addressLat,
    addressLng,
    restaurantLat,
    restaurantLng,
  );

  if (distance > 10) {
    throw Exception(
      "This restaurant ($restaurantName) is too far away (${distance.toStringAsFixed(1)} km). "
      "You can only order from restaurants within 10 km.",
    );
  }
}
}