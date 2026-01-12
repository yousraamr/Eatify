import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../core/utils/location_utils.dart';

/// ----------------------------
/// 📍 User location provider
/// ----------------------------
final userLocationProvider = FutureProvider((ref) async {
  return await LocationService.getCurrentLocation();
});


/// ----------------------------
/// 🍽 Fetch ALL restaurants (raw, no filtering)
/// ----------------------------
final allRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final response = await SupabaseService.client.from('restaurants').select();
  return response.map<Restaurant>((e) => Restaurant.fromMap(e)).toList();
});


/// ----------------------------
/// 🎛 Filter state
/// ----------------------------
enum RestaurantFilter { all, nearby }

final restaurantFilterProvider =
    StateProvider<RestaurantFilter>((ref) => RestaurantFilter.nearby);


/// ----------------------------
/// 🔥 Filtered restaurants (location + filter applied)
/// ----------------------------
final filteredRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(allRestaurantsProvider.future);
  final filter = ref.watch(restaurantFilterProvider);

  // If "all", skip location completely
  if (filter == RestaurantFilter.all) {
    return restaurants;
  }

  try {
    final position = await ref.watch(userLocationProvider.future);

    return restaurants.where((r) {
      final distance = calculateDistanceKm(
        position.latitude,
        position.longitude,
        r.latitude,
        r.longitude,
      );
      return distance <= 10;
    }).toList();
  } catch (e) {
    // If location fails → fallback to all restaurants
    return restaurants;
  }
});


/// ----------------------------
/// 🏪 Fetch single restaurant
/// ----------------------------
Future<Restaurant> fetchRestaurantById(String id) async {
  final res = await SupabaseService.client
      .from('restaurants')
      .select()
      .eq('id', id)
      .single();

  return Restaurant.fromMap(res);
}
