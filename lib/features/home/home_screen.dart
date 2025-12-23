import 'package:eatify/features/home/restaurants_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatify/features/menu/menu_screen.dart';
import 'package:eatify/features/home/address_selection_screen.dart';
import 'package:eatify/features/notifications/notifications_screen.dart';
import 'package:eatify/core/common/round_textfield.dart';
import 'package:eatify/core/common/view_all_title_row.dart';
import 'package:eatify/services/supabase_service.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/menu_provider.dart';

// Provider: fetch all restaurants from Supabase
final allRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final response = await SupabaseService.client.from('restaurants').select();
  print("Supabase all restaurants response: $response");
  final restaurants = response.map<Restaurant>((e) => Restaurant.fromMap(e)).toList();
  return restaurants;
});

// Provider: dynamic username
final userNameProvider = StateProvider<String>((ref) => "User");

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController txtSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final response = await SupabaseService.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (response != null && response['full_name'] != null) {
        ref.read(userNameProvider.notifier).state = response['full_name'] as String;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAddress = ref.watch(selectedAddressProvider);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 46),

              // Greeting & Notifications
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Good morning $userName!",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                      icon: const Icon(Icons.notifications_none, size: 25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Address Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.location_on),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Delivering to",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedAddress?.label ?? "No address selected",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddressSelectionScreen()),
                        );
                      },
                      child: const Text("Change"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoundTextfield(
                  hintText: "Search Food",
                  controller: txtSearch,
                  left: Container(
                    alignment: Alignment.center,
                    width: 30,
                    child: const Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Most Popular Restaurants (Vertical)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ViewAllTitleRow(
                  title: "Most Popular",
                  onView: () {
                    // Navigate to all restaurants screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RestaurantsScreen()),
                    );
                  },
                ),
              ),
              ref.watch(allRestaurantsProvider).when(
                    data: (restaurants) {
                      if (restaurants.isEmpty) {
                        return const Center(child: Text("No restaurants available"));
                      }

                      // Sort by rating descending
                      final mostPopular = List<Restaurant>.from(restaurants)
                        ..sort((a, b) => b.rating.compareTo(a.rating));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        itemCount: mostPopular.length,
                        itemBuilder: (context, index) {
                          final r = mostPopular[index];
                          return _RestaurantRow(
                            rObj: r,
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
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  ),

              const SizedBox(height: 30),

              // Recent Items (Horizontal List)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ViewAllTitleRow(title: "Recent Items", onView: () {}),
              ),
              SizedBox(
                height: 130,
                child: ref.watch(allMenuItemsProvider).when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(child: Text("No recent items"));
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _MenuItemRow(mObj: item, onTap: () {});
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text("Error: $e")),
                    ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Restaurant Row Widget
class _RestaurantRow extends StatelessWidget {
  final Restaurant rObj;
  final VoidCallback onTap;

  const _RestaurantRow({required this.rObj, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                image: rObj.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(rObj.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: rObj.imageUrl.isEmpty ? const Icon(Icons.fastfood, size: 36, color: Colors.grey) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rObj.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(rObj.rating.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menu Item Row Widget
class _MenuItemRow extends StatelessWidget {
  final MenuItem mObj;
  final VoidCallback onTap;

  const _MenuItemRow({required this.mObj, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                image: mObj.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(mObj.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: mObj.imageUrl.isEmpty ? const Icon(Icons.fastfood, size: 36, color: Colors.grey) : null,
            ),
            const SizedBox(height: 8),
            Text(
              mObj.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              "${mObj.price} EGP",
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
