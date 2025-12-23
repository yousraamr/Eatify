import 'package:eatify/features/checkout/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';

class PersonalCartScreen extends ConsumerWidget {
  const PersonalCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                /// CART ITEMS
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final cartItem = cart.items[i];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            /// IMAGE PLACEHOLDER
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.horizontal(
                                left: Radius.circular(16),
                              ),
                              child: Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.fastfood,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            /// ITEM DETAILS
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cartItem.item.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${cartItem.item.price} EGP',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .primaryColor,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// ACTIONS
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  /// DELETE (WITH UNDO)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      final removedItem =
                                          cartItem;

                                      ref
                                          .read(cartProvider.notifier)
                                          .removeItem(
                                            cartItem.item.id,
                                          );

                                      ScaffoldMessenger.of(context)
                                          .clearSnackBars();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${cartItem.item.name} removed',
                                          ),
                                          duration:
                                              const Duration(
                                                  seconds: 5),
                                          action:
                                              SnackBarAction(
                                            label: 'UNDO',
                                            onPressed: () {
                                              ref
                                                  .read(cartProvider.notifier)
                                                  .restoreItem(
                                                    removedItem,
                                                  );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  /// QUANTITY CONTROLS
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(
                                              30),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 18,
                                          ),
                                          onPressed:
                                              cartItem.quantity >
                                                      1
                                                  ? () {
                                                      ref
                                                          .read(cartProvider
                                                              .notifier)
                                                          .decreaseQuantity(
                                                            cartItem
                                                                .item
                                                                .id,
                                                          );
                                                    }
                                                  : null,
                                        ),
                                        Text(
                                          cartItem.quantity
                                              .toString(),
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(cartProvider
                                                    .notifier)
                                                .increaseQuantity(
                                                  cartItem.item
                                                      .id,
                                                );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                /// CHECKOUT BAR
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${cart.total.toStringAsFixed(2)} EGP',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          child: const Text('Checkout'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CheckoutScreen(
                                      isShared: false,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
