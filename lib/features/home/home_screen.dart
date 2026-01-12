import 'package:eatify/features/cart/personal_cart_screen.dart';
import 'package:eatify/features/home/restaurants_screen.dart';
import 'package:eatify/features/invitations/cart_invitations_screen.dart';
import 'package:eatify/providers/fav_provider.dart';
import 'package:eatify/providers/recent_items_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatify/features/menu/menu_screen.dart';
import 'package:eatify/features/home/address_selection_screen.dart';
import 'package:eatify/features/notifications/notifications_screen.dart';
import 'package:eatify/core/common/round_textfield.dart';
import 'package:eatify/core/common/view_all_title_row.dart';
import 'package:eatify/services/supabase_service.dart';
import 'package:eatify/features/inbox/inbox_screen.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/profile_provider.dart'; 
import '../../core/utils/location_utils.dart';



final allRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final response = await SupabaseService.client.from('restaurants').select();
  return response.map<Restaurant>((e) => Restaurant.fromMap(e)).toList();
});


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  
  final txtSearch = TextEditingController();  
  String searchQuery = "";
  @override
      void initState() {
        super.initState();
        txtSearch.addListener(() {
          setState(() {
            searchQuery = txtSearch.text.toLowerCase();
          });
        });
      }
      @override
      void dispose() {
        txtSearch.dispose();
        super.dispose();
      }
      Future<void> _handleRestaurantTap(Restaurant r) async {
              final address = ref.read(selectedAddressProvider);

              // If no address, just open menu (or you can force address selection)
              if (address == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(
                      restaurantId: r.id,
                      restaurantName: r.name,
                    ),
                  ),
                );
                return;
              }

              final distance = calculateDistanceKm(
                address.latitude,
                address.longitude,
                r.latitude,
                r.longitude,
              );

              // 🚫 If farther than 10 km → show warning
              if (distance > 10) {
                final proceed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Out of delivery range"),
                    content: Text(
                      "This restaurant is about ${distance.toStringAsFixed(1)} km away from your location.\n\n"
                      "You can browse the menu, but ordering from this restaurant is currently unavailable.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Browse menu"),
                      ),
                    ],
                  ),
                );

                if (proceed != true) return;
              }

              // ✅ Open menu
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MenuScreen(
                    restaurantId: r.id,
                    restaurantName: r.name,
                  ),
                ),
              );
            }

  @override
  Widget build(BuildContext context) {
    final selectedAddress = ref.watch(selectedAddressProvider);
    final profileAsync = ref.watch(
      currentProfileProvider,
    ); // Now using the correct one!

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// 🔥 TOP GREETING SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: profileAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, __) => _GreetingFallback(),
                  data: (profile) {
                    final username = profile['username'] ?? 'User';
                    final avatarUrl = profile['avatar_url'];

                    return Row(
                      children: [
                        /// 👤 AVATAR
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.orange.shade200,
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),

                        const SizedBox(width: 12),

                        /// 👋 GREETING TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome back 👋",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _TopIconButton(
                          icon: Icons.notifications_none,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                        _TopIconButton(
                          icon: Icons.chat_bubble_outline,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InboxScreen(),
                            ),
                          ),
                        ),
                        _TopIconButton(
                          icon: Icons.person_add_alt_1,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => CartInvitationsScreen(),
                          ),
                        ),
                            _TopIconButton(
                          icon: Icons.shopping_cart_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalCartScreen(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// 📍 ADDRESS SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Delivering to",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressSelectionScreen(),
                        ),
                      ),
                      child: const Text("Change"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔍 SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoundTextfield(
                  hintText: "Search food or restaurant",
                  controller: txtSearch,
                  left: const Icon(Icons.search),
                ),
              ),

              const SizedBox(height: 30),

              /// 🍴 MOST POPULAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ViewAllTitleRow(
                  title: "Most Popular",
                  onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RestaurantsScreen(),
                    ),
                  ),
                ),
              ),

              ref
                  .watch(allRestaurantsProvider)
                  .when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                    data: (restaurants) {
                      final sorted = List<Restaurant>.from(restaurants)
                        ..sort((a, b) => b.rating.compareTo(a.rating));
                      final filtered = searchQuery.isEmpty
                                ? sorted
                                : sorted
                                    .where((r) =>
                                        r.name.toLowerCase().contains(searchQuery))
                                    .toList();

                            if (filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("No restaurants found"),
                              );
                            }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _RestaurantRow(
                          rObj: filtered[i],
                         onTap: () => _handleRestaurantTap(filtered[i]),
                        ),
                      );
                    },
                  ),

              const SizedBox(height: 30),

              /// 🍔 RECENT ITEMS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ViewAllTitleRow(title: "Recent Items"),
              ),

              SizedBox(
                height: 140,
                child: ref
                    .watch(recentItemsProvider)
                    .when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text(e.toString()),
                      data: (items) => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (_, i) =>
                            _MenuItemRow(mObj: items[i], onTap: () {}),
                      ),
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

/// 🔘 Top icon button
class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      splashRadius: 22,
    );
  }
}

/// Fallback greeting (edge case)
class _GreetingFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      "Hello 👋",
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

// Restaurant Row Widget
class _RestaurantRow extends ConsumerWidget {
  final Restaurant rObj;
  final VoidCallback onTap;

  const _RestaurantRow({required this.rObj, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(rObj.id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Restaurant image
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
              child: rObj.imageUrl.isEmpty
                  ? const Icon(Icons.fastfood, size: 36, color: Colors.grey)
                  : null,
            ),

            const SizedBox(width: 12),

            // Restaurant details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rObj.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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

            // Heart button on the far right
            IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              color: isFav ? Colors.red : Colors.grey,
              onPressed: () =>
                  ref.read(favoritesProvider.notifier).toggleFavorite(rObj.id),
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
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
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
              child: mObj.imageUrl.isEmpty
                  ? const Icon(Icons.fastfood, size: 36, color: Colors.grey)
                  : null,
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
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}
