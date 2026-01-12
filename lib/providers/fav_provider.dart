import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier(ref);
  },
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  FavoritesNotifier(this.ref) : super({}) {
    _loadFavorites();

    // Listen to auth state changes (login/logout)
    _supabase.auth.onAuthStateChange.listen((authState) {
      // authState is of type AuthState
      _loadFavorites();
    });
  }

  /// Load favorites for current user
  Future<void> _loadFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      state = {}; // clear favorites if no user
      return;
    }

    final response = await _supabase
        .from('favorites')
        .select('restaurant_id')
        .eq('user_id', userId);

    if (response != null) {
      state = (response as List)
          .map((e) => e['restaurant_id'] as String)
          .toSet();
    } else {
      state = {};
    }
  }

  /// Toggle favorite restaurant
  Future<void> toggleFavorite(String restaurantId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (state.contains(restaurantId)) {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId);
      state = {...state}..remove(restaurantId);
    } else {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
      });
      state = {...state}..add(restaurantId);
    }
  }

  /// Clear all favorites (call on logout)
  void clear() {
    state = {};
  }
}
