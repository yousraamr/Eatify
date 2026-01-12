import 'package:eatify/core/common/cart_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/cart_item_model.dart';

class RestaurantSection extends StatelessWidget {
  final String restaurantName;
  final List<CartItem> items;
  final WidgetRef ref;

  const RestaurantSection({
    super.key,
    required this.restaurantName,
    required this.items,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              restaurantName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold, fontSize: 18
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => CartItemTile(item: item, ref: ref)),
        ],
      ),
    );
  }
}