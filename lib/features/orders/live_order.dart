import 'package:eatify/features/tracking/delivery_tracking_screen.dart';
import 'package:eatify/providers/profile_orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eatify/translations/liveord_strings.dart';
class LiveOrdersScreen extends ConsumerWidget {
  const LiveOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveOrders = ref.watch(liveOrdersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: const Text(LiveordStrings.liveOrders).tr(),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: liveOrders.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const _EmptyLiveOrdersView();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, index) {
              return _LiveOrderCard(order: orders[index]);
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
/*                               ORDER CARD                                   */
/* -------------------------------------------------------------------------- */

class _LiveOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _LiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final rLat = order['restaurant_lat'];
        final rLng = order['restaurant_lng'];
        final aLat = order['address_lat'];
        final aLng = order['address_lng'];

        if (rLat == null || rLng == null || aLat == null || aLng == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LiveordStrings.deliveryLocationNotAvailable).tr()),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryTrackingScreen(
              orderId: order['id'],
              restaurant: LatLng(rLat, rLng),
              destination: LatLng(aLat, aLng),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            /// Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            /// Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${LiveordStrings.orderNumber.tr()} #${order['id'].toString().substring(0, 6)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order['status']
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            /// Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               EMPTY STATE                                  */
/* -------------------------------------------------------------------------- */

class _EmptyLiveOrdersView extends StatelessWidget {
  const _EmptyLiveOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 70,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 20),
            Text(
              LiveordStrings.noLiveOrdersYet.tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              LiveordStrings.trackOrderMsg.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).cardColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
