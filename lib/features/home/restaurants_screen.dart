import 'package:eatify/core/common/category_cell.dart';
import 'package:eatify/features/menu/menu_screen.dart';
import 'package:eatify/providers/restaurant_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class RestaurantsScreen extends ConsumerWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(restaurantFilterProvider);
    final restaurantsAsync = ref.watch(filteredRestaurantsProvider);

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
                        onTap: () =>
                            Navigator.pop(context, RestaurantFilter.all),
                      ),
                      ListTile(
                        title: const Text("Nearby only"),
                        onTap: () =>
                            Navigator.pop(context, RestaurantFilter.nearby),
                      ),
                    ],
                  ),
                ),
              );

              if (selected != null) {
                ref.read(restaurantFilterProvider.notifier).state = selected;
              }
            },
          ),
        ],
      ),

      body: restaurantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    filter == RestaurantFilter.nearby
                        ? "No restaurants within 10 km"
                        : "No restaurants found",
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: restaurants.length,
            itemBuilder: (_, index) {
              final r = restaurants[index];

              return CategoryCell(
                cObj: {
                  "name": r.name,
                  "image": r.imageUrl,
                  "rating": r.rating,
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
              );
            },
          );
        },
      ),
    );
  }
}
