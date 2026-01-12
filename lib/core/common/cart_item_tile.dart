import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/cart_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final WidgetRef ref;

  const CartItemTile({super.key, required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.item.price.toStringAsFixed(2)} EGP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              _quantityButton(
                context,
                Icons.remove,
                () => ref
                    .read(cartProvider.notifier)
                    .decreaseQuantity(item.item.id),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.quantity.toString(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              _quantityButton(
                context,
                Icons.add,
                () => ref
                    .read(cartProvider.notifier)
                    .increaseQuantity(item.item.id),
              ),

              // Trash icon
              IconButton(
                icon: Icon(Icons.delete, color: AppTheme.error),
                onPressed: () {
                  ref.read(cartProvider.notifier).removeItem(item.item.id);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.item.name} removed from cart'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () =>
                            ref.read(cartProvider.notifier).restoreItem(item),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: theme.primaryColor, size: 18),
      ),
    );
  }
}
