// lib/providers/profile_provider.dart
// REPLACE YOUR ENTIRE FILE WITH THIS

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// Simple auth state provider
final authStateListenerProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.client.auth.onAuthStateChange;
});

// Current user's profile - FIXED VERSION
final currentProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = await ref.watch(authStateListenerProvider.future);
  final user = authState.session?.user;

  if (user == null) {
    throw Exception('Not authenticated');
  }

  try {
    debugPrint('🔍 Fetching profile for user: ${user.id}');

    final profile = await SupabaseService.client
        .from('profiles')
        .select('id, user_number, username, full_name, avatar_url, created_at')
        .eq('id', user.id)
        .single();

    debugPrint('✅ Profile loaded: ${profile['username']}');
    return profile;
  } catch (e) {
    debugPrint('❌ Error fetching profile: $e');
    rethrow;
  }
});

final profileEditControllerProvider =
    StateNotifierProvider<ProfileEditController, AsyncValue<void>>(
      (ref) => ProfileEditController(ref),
    );

class ProfileEditController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ProfileEditController(this.ref) : super(const AsyncValue.data(null));

  /// Update profile text fields
  Future<bool> updateProfile({
    required String username,
    required String fullName,
  }) async {
    try {
      state = const AsyncValue.loading();

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await SupabaseService.client.from('profiles').update({
        'username': username,
        'full_name': fullName,
      }).eq('id', user.id);

      // 🔥 force refresh everywhere
      ref.invalidate(currentProfileProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('❌ Update profile error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Upload avatar image - FIXED VERSION
  Future<bool> updateAvatar(File imageFile) async {
    try {
      state = const AsyncValue.loading();

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final userId = user.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExt = imageFile.path.split('.').last.toLowerCase();

      // IMPORTANT: Use this exact path format
      final filePath = '$userId/avatar_$timestamp.$fileExt';

      debugPrint('🔍 Uploading to: avatars/$filePath');

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      debugPrint('📦 File size: ${bytes.length} bytes');

      // Determine content type
      String contentType = 'image/jpeg';
      if (fileExt == 'png') contentType = 'image/png';
      if (fileExt == 'jpg' || fileExt == 'jpeg') contentType = 'image/jpeg';

      // Upload to Supabase Storage
      final uploadResponse = await SupabaseService.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true, // Replace if exists
            ),
          );

      debugPrint('✅ Upload response: $uploadResponse');

      // Get public URL
      final imageUrl = SupabaseService.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      debugPrint('🔗 Public URL: $imageUrl');

      // Update profile with new avatar URL
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      debugPrint('✅ Profile updated with avatar URL');

      // Invalidate profile to refresh
      ref.invalidate(currentProfileProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('❌ Avatar upload failed: $e');
      debugPrint('Stack trace: $st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Remove avatar
  Future<bool> removeAvatar() async {
    try {
      state = const AsyncValue.loading();

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Update profile to null avatar
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);

      // Invalidate profile to refresh
      ref.invalidate(currentProfileProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('❌ Remove avatar error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}