import 'package:eatify/models/menu_item_model.dart';
import 'package:eatify/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recentItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser!.id;

  // 1️⃣ get recent order items for this user
  final response = await SupabaseService.client
      .from('order_items')
      .select('menu_item_id, orders!inner(user_id, created_at)')
      .eq('orders.user_id', userId)
      .order('created_at', referencedTable: 'orders', ascending: false)
      .limit(15);

  // 2️⃣ extract unique menu item ids (keep order)
  final ids = <String>[];
  for (final row in response) {
    final id = row['menu_item_id'] as String;
    if (!ids.contains(id)) ids.add(id);
  }

  if (ids.isEmpty) return [];

  // 3️⃣ fetch actual menu items
  final items = await SupabaseService.client
      .from('menu_items')
      .select()
      .inFilter('id', ids);

  // 4️⃣ map to MenuItem models
  final mapped = items.map<MenuItem>((e) => MenuItem.fromMap(e)).toList();

  // 5️⃣ keep same order as recent history
  mapped.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));

  return mapped;
});
