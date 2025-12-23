import 'package:eatify/core/common/inline_split_bill_widget.dart';
import 'package:eatify/features/checkout/checkout_screen.dart';
import 'package:eatify/providers/shared_cart_items_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/shared_cart_provider.dart';
import 'shared_menu_screen.dart';

class SharedCartScreen extends ConsumerStatefulWidget {
  const SharedCartScreen({super.key});

  @override
  ConsumerState<SharedCartScreen> createState() => _SharedCartScreenState();
}

class _SharedCartScreenState extends ConsumerState<SharedCartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(sharedCartProvider);

    ref.listen(sharedCartProvider, (prev, next) {
      if (next is AsyncData && next.value == null) {
        ref.read(sharedCartProvider.notifier).loadActiveSharedCart();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Cart')),
      body: cartAsync.when(
        data: (cart) {
          if (cart == null) return const _NoCartView();
          return _ActiveCartView(
            cartId: cart.id,
            code: cart.code,
            restaurantId: cart.restaurantId,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               NO CART VIEW                                 */
/* -------------------------------------------------------------------------- */

class _NoCartView extends ConsumerWidget {
  const _NoCartView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Join a Shared Cart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Enter cart code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              child: const Text('Join Cart'),
              onPressed: () async {
                try {
                  await ref
                      .read(sharedCartProvider.notifier)
                      .joinSharedCart(codeCtrl.text.trim());
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Create a shared cart from a restaurant menu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              ACTIVE CART VIEW                               */
/* -------------------------------------------------------------------------- */

class _ActiveCartView extends ConsumerWidget {
  final String cartId;
  final String code;
  final String restaurantId;

  const _ActiveCartView({
    required this.cartId,
    required this.code,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final cart = ref.read(sharedCartProvider).value!;
    final isOwner = currentUserId == cart.ownerId;
    final itemsAsync = ref.watch(sharedCartItemsProvider(cartId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// HEADER CARD
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                Text(
                  'Cart Code',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Add Items'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SharedMenuScreen(
                                restaurantId: restaurantId,
                                restaurantName: 'Shared Cart Restaurant',
                              ),
                            ),
                          );
                          ref.invalidate(sharedCartItemsProvider(cartId));
                        },
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Checkout'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(
                                  isShared: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(sharedCartProvider.notifier).leaveSharedCart();
                  },
                  child: const Text(
                    'Leave Cart',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// SPLIT BILL SUMMARY
          InlineSplitBillWidget(cartId: cartId),

          const SizedBox(height: 16),

          /// ITEMS LIST
          itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text('No items added yet'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isItemOwner = item.userId == currentUserId;
                  final canEdit = isItemOwner;

                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await ref
                          .read(sharedCartItemsProvider(cartId).notifier)
                          .removeItem(item.id);
                      ref.invalidate(sharedCartItemsProvider(cartId));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${item.menuItemName} removed from cart'),
                        ),
                      );
                    },
                    child: Container(
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
                          // IMAGE
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(16),
                            ),
                            child: Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                          // DETAILS
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menuItemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Added by ${item.userName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isItemOwner
                                          ? Colors.blue[700]
                                          : Colors.grey[600],
                                      fontWeight: isItemOwner
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.price.toStringAsFixed(2)} EGP',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // QUANTITY EDIT
                          if (canEdit)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () async {
                                    await ref
                                        .read(sharedCartItemsProvider(cartId)
                                            .notifier)
                                        .decreaseQuantity(
                                            item.id, item.quantity);
                                    ref.invalidate(
                                        sharedCartItemsProvider(cartId));
                                  },
                                ),
                                Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () async {
                                    await ref
                                        .read(sharedCartItemsProvider(cartId)
                                            .notifier)
                                        .increaseQuantity(
                                            item.id, item.quantity);
                                    ref.invalidate(
                                        sharedCartItemsProvider(cartId));
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
          ),
        ],
      ),
    );
  }
}
