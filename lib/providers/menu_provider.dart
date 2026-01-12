import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../services/supabase_service.dart';

/// Menu items for a specific restaurant
final restaurantMenuProvider = FutureProvider.family<List<MenuItem>, String>((
  ref,
  restaurantId,
) async {
  // Fetch menu items along with their restaurant info using a join
  final response = await SupabaseService.client
      .from('menu_items')
      .select(
        'id, name, price, description, image_url, restaurant_id, restaurants(name)',
      ) // join restaurants table
      .eq('restaurant_id', restaurantId);

  if (response == null) return [];

  return (response as List).map<MenuItem>((e) {
    // e['restaurants'] will contain restaurant data
    final restaurantName = e['restaurants'] != null
        ? e['restaurants']['name']
        : 'Unknown Restaurant';

    // Inject restaurantName into the map so MenuItem.fromMap works
    return MenuItem.fromMap({...e, 'restaurant_name': restaurantName});
  }).toList();
});

/// Recent items (all menu items, across all restaurants)
final allMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final response = await SupabaseService.client.from('menu_items').select();

  if (response == null) return [];

  return (response as List).map<MenuItem>((e) => MenuItem.fromMap(e)).toList();
});
