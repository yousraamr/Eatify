import 'package:eatify/core/utils/split_bill_calculator.dart';
import 'package:eatify/providers/split_bill_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitBillScreen extends ConsumerWidget {
  final String cartId;
  final String restaurantName;

  const SplitBillScreen({
    super.key,
    required this.cartId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitBill = ref.watch(splitBillProvider(cartId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Split Bill'),
        elevation: 0,
      ),
      body: splitBill.contributions.isEmpty
          ? _buildEmptyState()
          : _buildBillContent(context, splitBill),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No items in cart yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillContent(BuildContext context, SplitBillResult splitBill) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Restaurant Header
          _buildRestaurantHeader(context),

          const SizedBox(height: 16),

          // Total Summary Card
          _buildTotalSummaryCard(context, splitBill),

          const SizedBox(height: 24),

          // Per-Person Breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Individual Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...splitBill.contributions.map(
                  (contribution) => _buildUserContributionCard(
                    context,
                    contribution,
                    splitBill.contributions.indexOf(contribution),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            restaurantName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Shared Cart Receipt',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryCard(
    BuildContext context,
    SplitBillResult splitBill,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Participants Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${splitBill.participantCount} Participant${splitBill.participantCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Breakdown
          _buildSummaryRow(
            'Subtotal',
            splitBill.formattedTotalSubtotal,
            isSubtitle: true,
          ),
          if (splitBill.totalDeliveryFee > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Delivery Fee',
              splitBill.formattedTotalDeliveryFee,
              isSubtitle: true,
            ),
          ],
          if (splitBill.totalServiceFee > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Service Fee',
              splitBill.formattedTotalServiceFee,
              isSubtitle: true,
            ),
          ],
          if (splitBill.totalTax > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Tax',
              splitBill.formattedTotalTax,
              isSubtitle: true,
            ),
          ],

          const SizedBox(height: 16),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // Grand Total
          _buildSummaryRow(
            'GRAND TOTAL',
            splitBill.formattedGrandTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isSubtitle = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 22 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUserContributionCard(
    BuildContext context,
    UserContribution contribution,
    int index,
  ) {
    // Assign different colors to users
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: userColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: userColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: userColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: userColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${contribution.userId.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${contribution.itemCount} item${contribution.itemCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: userColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    contribution.formattedTotal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...contribution.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: userColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.menuItemName}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${(item.price * item.quantity).toStringAsFixed(2)} EGP',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),

                // Breakdown
                _buildContributionRow('Subtotal', contribution.formattedSubtotal),
                if (contribution.deliveryFee > 0) ...[
                  const SizedBox(height: 4),
                  _buildContributionRow(
                    'Delivery Share',
                    contribution.formattedDeliveryFee,
                  ),
                ],
                if (contribution.serviceFee > 0) ...[
                  const SizedBox(height: 4),
                  _buildContributionRow(
                    'Service Share',
                    contribution.formattedServiceFee,
                  ),
                ],
                if (contribution.tax > 0) ...[
                  const SizedBox(height: 4),
                  _buildContributionRow(
                    'Tax Share',
                    contribution.formattedTax,
                  ),
                ],

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: userColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total to Pay',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        contribution.formattedTotal,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: userColor,
                        ),
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
  }

  Widget _buildContributionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}