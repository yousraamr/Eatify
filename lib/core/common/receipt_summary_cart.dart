import 'package:eatify/features/checkout/checkout_screen.dart';
import 'package:flutter/material.dart';
import '../../../providers/cart_provider.dart';

class ReceiptSummary extends StatelessWidget {
  final CartState cart;

  const ReceiptSummary({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final deliveryFee = 20.0; // ONE delivery for the whole cart

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show subtotal per restaurant
          ...cart.itemsByRestaurant.entries.map((entry) {
            final items = entry.value;
            final restaurantName = items.first.item.restaurantName;
            final subtotal = items.fold<double>(
              0,
              (sum, i) => sum + i.item.price * i.quantity,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _row(theme, '$restaurantName Subtotal', subtotal),
            );
          }),

          const Divider(thickness: 2),
          const SizedBox(height: 8),

          // Fees
          _row(theme, 'Delivery Fee', cart.deliveryFee),
          _row(theme, 'Service Fee', cart.serviceFee),
          _row(theme, 'Tax (14%)', cart.tax),

          const Divider(thickness: 2),
          const SizedBox(height: 8),

          // Total
          _row(
            theme,
            'Total',
            cart.total + cart.deliveryFee + cart.serviceFee + cart.tax,
            bold: true,
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckoutScreen(isShared: false),
                  ),
                );
              },
              child: const Text(
                'Checkout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} EGP',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
