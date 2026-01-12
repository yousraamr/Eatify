import 'package:eatify/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatUserProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, chatId) async {
  final client = SupabaseService.client;
  final myId = client.auth.currentUser!.id;

  // get other member
  final member = await client
      .from('private_chat_members')
      .select('user_id')
      .eq('chat_id', chatId)
      .neq('user_id', myId)
      .single();

  final profile = await client
      .from('profiles')
      .select('username, user_number')
      .eq('id', member['user_id'])
      .single();

  return profile;
});
