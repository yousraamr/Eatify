import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../services/supabase_service.dart';

/// Menu items for a specific restaurant
final restaurantMenuProvider =
    FutureProvider.family<List<MenuItem>, String>((ref, restaurantId) async {
  final response = await SupabaseService.client
      .from('menu_items')
      .select()
      .eq('restaurant_id', restaurantId);

  if (response == null) return [];

  return (response as List)
      .map<MenuItem>((e) => MenuItem.fromMap(e))
      .toList();
});

/// Recent items (all menu items, across all restaurants)
final allMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final response = await SupabaseService.client.from('menu_items').select();

  if (response == null) return [];

  return (response as List)
      .map<MenuItem>((e) => MenuItem.fromMap(e))
      .toList();
});
