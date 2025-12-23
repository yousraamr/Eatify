import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final deliveryTrackingProvider =
    StateNotifierProvider.family<
        DeliveryTrackingNotifier,
        LatLng?,
        String>((ref, orderId) {
  return DeliveryTrackingNotifier();
});

class DeliveryTrackingNotifier extends StateNotifier<LatLng?> {
  DeliveryTrackingNotifier() : super(null);

  Timer? _timer;
  List<LatLng> _route = [];
  int _index = 0;

  /// Start tracking ALONG ROUTE
  void startTrackingAlongRoute(List<LatLng> route) {
    if (route.isEmpty) return;

    _route = route;
    _index = 0;
    state = _route.first;

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (_index >= _route.length - 1) {
          state = _route.last;
          _timer?.cancel();
          return;
        }

        _index++;
        state = _route[_index];
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
