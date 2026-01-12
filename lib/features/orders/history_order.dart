import 'package:eatify/providers/profile_orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eatify/translations/ordhis_strings.dart';
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(orderHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: const Text(OrdhisStrings.orderHistory).tr(),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
      ),
      body: history.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const _EmptyHistoryView();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final order = orders[i];

              return Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                elevation: 3,
                shadowColor: Colors.black12,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(
                    '${OrdhisStrings.orderNumber.tr()} #${order['id'].toString().substring(0, 6)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    OrdhisStrings.deliveredOrders.tr(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               EMPTY STATE                                  */
/* -------------------------------------------------------------------------- */

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  [
          Icon(Icons.history, size: 70, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            OrdhisStrings.noPreviousOrders.tr(),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            OrdhisStrings.completeOrdMsg.tr(),
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
