import 'package:eatify/core/common/receipt_summary_cart.dart';
import 'package:eatify/core/common/restaurant_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';

class PersonalCartScreen extends ConsumerWidget {
  const PersonalCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: cart.isEmpty
          ? Center(
              child: Text(
                'Your cart is empty',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: cart.itemsByRestaurant.entries.map((entry) {
                      final items = entry.value;
                      final restaurantName = items.first.item.restaurantName;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: RestaurantSection(
                          restaurantName: restaurantName,
                          items: items,
                          ref: ref,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Receipt summary with elevated look
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ReceiptSummary(cart: cart),
                ),
              ],
            ),
    );
  }
}