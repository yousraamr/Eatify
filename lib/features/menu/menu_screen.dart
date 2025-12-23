import 'package:eatify/features/cart/personal_cart_screen.dart';
import 'package:eatify/features/shared_cart/shared_cart_screen.dart';
import 'package:eatify/providers/shared_cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item_model.dart';

class MenuScreen extends ConsumerWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final menuAsync = ref.watch(menuProvider());
    final menuAsync = ref.watch(restaurantMenuProvider(restaurantId));

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalCartScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              await ref
                  .read(sharedCartProvider.notifier)
                  .createSharedCart(
                    restaurantId: restaurantId,
                  );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SharedCartScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: menuAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No items available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              return _MenuItemCard(item: item);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _MenuItemCard extends ConsumerWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          /// IMAGE (PLACEHOLDER STYLE LIKE GITHUB)
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: Container(
              width: 110,
              height: 110,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.fastfood,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),

          /// DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.price} EGP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ADD BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                try {
                  ref
                      .read(cartProvider.notifier)
                      .addItem(item);

                  ScaffoldMessenger.of(context)
                      .clearSnackBars();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text('Added to cart'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (_) {
                  _showClearCartDialog(
                      context, ref, item);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'Your cart contains items from another restaurant.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Clear & Add'),
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              ref.read(cartProvider.notifier).addItem(item);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
