import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../core/utils/location_utils.dart';

final restaurantProvider = FutureProvider<List<Restaurant>>((ref) async {
  final response = await SupabaseService.client.from('restaurants').select();
  print("Supabase response: $response");

  final restaurants = response
      .map<Restaurant>((e) => Restaurant.fromMap(e))
      .toList();

  try {
    final position = await LocationService.getCurrentLocation();

    return restaurants.where((restaurant) {
      final distance = calculateDistanceKm(
        position.latitude,
        position.longitude,
        restaurant.latitude,
        restaurant.longitude,
      );
      return distance <= 10;
    }).toList();
  } catch (e) {
    // 🔥 fallback: show all restaurants
    return restaurants;
  }
});

Future<Restaurant> fetchRestaurantById(String id) async {
  final res = await SupabaseService.client
      .from('restaurants')
      .select()
      .eq('id', id)
      .single();

  return Restaurant.fromMap(res);
}
