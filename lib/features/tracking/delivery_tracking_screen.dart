import 'package:eatify/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../providers/delivery_tracking_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/osrm_service.dart';
import '../../services/supabase_service.dart';

class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final LatLng restaurant;
  final LatLng destination;

  const DeliveryTrackingScreen({
    super.key,
    required this.orderId,
    required this.restaurant,
    required this.destination,
  });

  @override
  ConsumerState<DeliveryTrackingScreen> createState() =>
      _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState
    extends ConsumerState<DeliveryTrackingScreen> {
  late final MapController _mapController;
  List<LatLng> route = [];
  int etaSeconds = 0;
  bool _deliveryStarted = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final result = await OsrmService.fetchRoute(
      start: widget.restaurant,
      end: widget.destination,
    );

    if (!mounted) return;

    setState(() {
      route = result.points;
      etaSeconds = result.durationSeconds;
    });

    // 🚚 Start driver movement along route
    ref
        .read(
          deliveryTrackingProvider(widget.orderId).notifier,
        )
        .startTrackingAlongRoute(route);

    // 📍 Fit map to full route
    final bounds = LatLngBounds.fromPoints(route);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );

    // ✅ Trigger delivery lifecycle ONCE
    if (!_deliveryStarted) {
      _deliveryStarted = true;

      // Mark order as out for delivery
      await SupabaseService.client
          .from('orders')
          .update({'status': 'out_for_delivery'})
          .eq('id', widget.orderId);
      await NotificationService.create(
          userId: SupabaseService.client.auth.currentUser!.id,
          title: 'Out for Delivery',
          body: 'Your courier is on the way.',
        );
      // Auto mark delivered after delay
      ref.read(orderProvider).autoMarkDelivered(
            widget.orderId,
            seconds: 40,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver =
        ref.watch(deliveryTrackingProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
            title: const Text('Live Delivery'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
      body: Column(
        children: [
          /// ETA BAR
          if (etaSeconds > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Estimated arrival: ${(etaSeconds / 60).ceil()} min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          /// MAP
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.restaurant,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.eatify',
                ),

                if (route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route,
                        strokeWidth: 5,
                        color: Colors.blue,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.restaurant,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.green,
                        size: 36,
                      ),
                    ),
                    Marker(
                      point: widget.destination,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.home,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                    if (driver != null)
                      Marker(
                        point: driver,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.purple,
                          size: 38,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
