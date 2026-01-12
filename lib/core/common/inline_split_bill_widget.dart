import 'package:eatify/providers/split_bill_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/split_bill_calculator.dart';

class InlineSplitBillWidget extends ConsumerWidget {
  final String cartId;
  const InlineSplitBillWidget({super.key, required this.cartId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitBill = ref.watch(splitBillProvider(cartId));

    if (splitBill.contributions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // adapts to light/dark mode
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.7),
                  theme.primaryColor,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: theme.cardColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Split Bill Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.cardColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 16, color: theme.cardColor),
                      const SizedBox(width: 4),
                      Text(
                        '${splitBill.participantCount}',
                        style: TextStyle(
                          color: theme.cardColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.4),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                _buildRow('Subtotal', splitBill.formattedTotalSubtotal, theme),
                if (splitBill.totalDeliveryFee > 0) ...[
                  const SizedBox(height: 8),
                  _buildRow(
                    'Delivery Fee',
                    splitBill.formattedTotalDeliveryFee,
                    theme,
                  ),
                ],
                if (splitBill.totalServiceFee > 0) ...[
                  const SizedBox(height: 8),
                  _buildRow(
                    'Service Fee',
                    splitBill.formattedTotalServiceFee,
                    theme,
                  ),
                ],
                if (splitBill.totalTax > 0) ...[
                  const SizedBox(height: 8),
                  _buildRow('Tax', splitBill.formattedTotalTax, theme),
                ],
                const SizedBox(height: 12),
                Divider(thickness: 2, color: theme.dividerColor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge!.color,
                      ),
                    ),
                    Text(
                      splitBill.formattedGrandTotal,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Per-Person Breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Individual Amounts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodySmall!.color,
                  ),
                ),
                const SizedBox(height: 12),
                ...splitBill.contributions.asMap().entries.map(
                  (entry) =>
                      _buildUserRow(context, entry.value, entry.key, theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodySmall!.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall!.color,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    UserContribution contribution,
    int index,
    ThemeData theme,
  ) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final userColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: userColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: userColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: userColor,
            radius: 20,
            child: Text(
              contribution.items.first.userName[0].toUpperCase(),
              style: TextStyle(
                color: theme.textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contribution.items.first.userName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge!.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${contribution.itemCount} item${contribution.itemCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall!.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: userColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              contribution.formattedTotal,
              style: TextStyle(
                color: theme.cardColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
