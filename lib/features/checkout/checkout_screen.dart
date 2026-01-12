import 'package:eatify/providers/shared_cart_items_provider.dart';
import 'package:eatify/providers/shared_cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../tracking/delivery_tracking_screen.dart';

class CheckoutScreen extends ConsumerWidget {
  final bool isShared;

  const CheckoutScreen({super.key, required this.isShared});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String paymentMethod = 'Cash';

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: paymentMethod,
              decoration:
                  const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
              ],
              onChanged: (v) => paymentMethod = v!,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('Confirm Order'),
                onPressed: () async {
                  try {
                    final address =
                        ref.read(selectedAddressProvider);
                    if (address == null) {
                      throw Exception('Select address first');
                    }
                    // final restaurantId =  ref.read(sharedCartProvider).value!.restaurantId;  

                    if(!isShared){
                    final cart = ref.read(cartProvider);
                    if (cart.isEmpty) {
                      throw Exception('Cart is empty');
                    }

                    String? firstOrderId;
                    LatLng? firstRestaurantLatLng;

                    for (final entry
                        in cart.itemsByRestaurant.entries) {
                      final restaurantId = entry.key;
                      final items = entry.value;

                      final restaurant =
                          await fetchRestaurantById(restaurantId);

                      final orderId = await ref
                          .read(orderProvider)
                          .checkoutPersonalCart(
                            restaurantId: restaurantId,
                            items: items,
                            paymentMethod: paymentMethod,
                          );

                      firstOrderId ??= orderId;
                      firstRestaurantLatLng ??= LatLng(
                        restaurant.latitude!,
                        restaurant.longitude!,
                      );
                    }

                    ref.read(cartProvider.notifier).clearCart();
                          
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryTrackingScreen(
                          orderId: firstOrderId!,
                          restaurant: firstRestaurantLatLng!,
                          destination: LatLng(
                            address.latitude,
                            address.longitude,
                          ),
                        ),
                      ),
                    );
                    } else {
                      final sharedCart =
                          ref.read(sharedCartProvider).value;
                      if (sharedCart == null) {
                        throw Exception('No active shared cart');
                      }

                      final orderId = await ref
                          .read(orderProvider)
                          .checkoutSharedCart(
                            paymentMethod: paymentMethod,
                          );

                      final restaurant =
                          await fetchRestaurantById(
                              sharedCart.restaurantId);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryTrackingScreen(
                            orderId: orderId,
                            restaurant: LatLng(
                              restaurant.latitude!,
                              restaurant.longitude!,
                            ),
                            destination: LatLng(
                              address.latitude,
                              address.longitude,
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}