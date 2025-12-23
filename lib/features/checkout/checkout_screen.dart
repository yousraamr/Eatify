import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/shared_cart_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/address_provider.dart';
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
              decoration: const InputDecoration(labelText: 'Payment Method'),
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
                    // 1️⃣ Ensure address exists
                    final address = ref.read(selectedAddressProvider);
                    if (address == null) {
                      throw Exception('Please select address first');
                    }

                    // 2️⃣ Determine restaurant ID
                    final restaurantId = isShared
                        ? ref.read(sharedCartProvider).value!.restaurantId
                        : ref.read(cartProvider).restaurantId;

                    if (restaurantId == null) {
                      throw Exception('Restaurant not found in cart');
                    }
                    
                    final restaurants = await ref.read(
                      restaurantProvider.future,
                    );

                    // 4️⃣ Find the restaurant for this order
                    /*final restaurant = restaurants.firstWhere(
                        (r) => r.id == restaurantId,
                        orElse: () => throw Exception('Restaurant not found'),
                      );*/
                    final restaurant = await fetchRestaurantById(restaurantId!);

                    // 5️⃣ Create LatLng safely
                    final restaurantLatLng = LatLng(
                      restaurant.latitude!,
                      restaurant.longitude!,
                    );

                    final destinationLatLng = LatLng(
                      address.latitude,
                      address.longitude,
                    );

                    // 4️⃣ Place order
                    final orderId = isShared
                        ? await ref
                              .read(orderProvider)
                              .checkoutSharedCart(paymentMethod: paymentMethod)
                        : await ref
                              .read(orderProvider)
                              .checkoutPersonalCart(
                                paymentMethod: paymentMethod,
                              );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order placed successfully'),
                      ),
                    );

                    // 5️⃣ Navigate to tracking with REAL coordinates
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryTrackingScreen(
                          orderId: orderId,
                          restaurant: restaurantLatLng,
                          destination: destinationLatLng,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
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
