import 'package:eatify/core/common/category_cell.dart';
import 'package:eatify/features/menu/menu_screen.dart';
import 'package:eatify/models/restaurant_model.dart';
import 'package:flutter/material.dart';
import 'package:eatify/services/location_service.dart';
import 'package:eatify/services/supabase_service.dart';
import 'package:eatify/core/utils/location_utils.dart';
import 'package:postgrest/src/types.dart';

enum RestaurantFilter { all, nearby }

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  RestaurantFilter filter = RestaurantFilter.nearby;
  List<Restaurant> restaurants = [];
  double? userLatitude;
  double? userLongitude;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

Future<void> _loadRestaurants() async {
  try {
    // 1️⃣ Get user location (optional)
    try {
      final position = await LocationService.getCurrentLocation();
      userLatitude = position.latitude;
      userLongitude = position.longitude;
    } catch (_) {
      userLatitude = null;
      userLongitude = null;
    }

    // 2️⃣ Fetch restaurants from Supabase
    final data = await SupabaseService.client
        .from('restaurants')
        .select(); // ✅ returns List<Map<String, dynamic>>

    if (data == null) {
      throw "No restaurants returned";
    }

    final allRestaurants = (data as List<dynamic>)
        .map((e) => Restaurant.fromMap(e as Map<String, dynamic>))
        .toList();

    print("✅ Loaded ${allRestaurants.length} restaurants");

    setState(() {
      restaurants = allRestaurants;
      isLoading = false;
    });
  } catch (e) {
    print("❌ ERROR fetching restaurants: $e");
    setState(() {
      error = e.toString();
      isLoading = false;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    // Apply filter
    final filteredRestaurants = restaurants.where((r) {
      if (filter == RestaurantFilter.all) return true;
      if (userLatitude == null || userLongitude == null) return true; // show all if location unavailable
      final distance = calculateDistanceKm(userLatitude!, userLongitude!, r.latitude, r.longitude);
      return distance <= 10;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurants"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final selected = await showDialog<RestaurantFilter>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Filter restaurants"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text("All restaurants"),
                        onTap: () => Navigator.pop(context, RestaurantFilter.all),
                      ),
                      ListTile(
                        title: const Text("Nearby only"),
                        onTap: () => Navigator.pop(context, RestaurantFilter.nearby),
                      ),
                    ],
                  ),
                ),
              );

              if (selected != null) {
                setState(() {
                  filter = selected;
                });
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Error: $error"))
              : filteredRestaurants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            filter == RestaurantFilter.nearby
                                ? "No restaurants within 10 km"
                                : "No restaurants found",
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      itemCount: filteredRestaurants.length,
                      itemBuilder: (_, index) {
                        final r = filteredRestaurants[index];
                        double? distance;
                        if (userLatitude != null && userLongitude != null) {
                          distance = calculateDistanceKm(userLatitude!, userLongitude!, r.latitude, r.longitude);
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MenuScreen(
                                  restaurantId: r.id,
                                  restaurantName: r.name,
                                ),
                              ),
                            );
                          },
                          child: CategoryCell(
                            cObj: {
                              "name": r.name,
                              "image": r.imageUrl,
                              "rating": r.rating,
                              "distance": distance != null ? "${distance.toStringAsFixed(1)} km" : null,
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MenuScreen(
                                    restaurantId: r.id,
                                    restaurantName: r.name,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

extension on PostgrestList {
  get data => null;
}
