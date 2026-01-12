import '../services/supabase_service.dart';

class PrivateChatService {
  static final _client = SupabaseService.client;

  /// ---------------------------------------------
  /// ORIGINAL (kept as-is)
  /// ---------------------------------------------
  static Future<String> getOrCreateChat(String otherUserId) async {
    final myId = _client.auth.currentUser!.id;

    // 1️⃣ Find existing chat
    final res = await _client
        .from('private_chat_members')
        .select('chat_id')
        .eq('user_id', myId);

    for (final row in res) {
      final chatId = row['chat_id'];

      final check = await _client
          .from('private_chat_members')
          .select()
          .eq('chat_id', chatId)
          .eq('user_id', otherUserId);

      if (check.isNotEmpty) {
        return chatId;
      }
    }

    // 2️⃣ Create new chat
    final chat = await _client
        .from('private_chats')
        .insert({})
        .select()
        .single();

    final chatId = chat['id'];

    // 3️⃣ Insert both members
    await _client.from('private_chat_members').insert([
      {'chat_id': chatId, 'user_id': myId},
      {'chat_id': chatId, 'user_id': otherUserId},
    ]);

    return chatId;
  }

  /// ---------------------------------------------
  /// NEW (by public user number)
  /// ---------------------------------------------
  static Future<String> getOrCreateChatByUserNumber(
      int userNumber) async {
      final myId = _client.auth.currentUser!.id;
    // 🔎 find real user id
    final user = await _client
        .from('profiles')
        .select('id')
        .eq('user_number', userNumber)
        .single();

    final otherUserId = user['id'];
     // ❌ check if blocked either way
  final blockCheck = await _client
      .from('user_blocks')
      .select()
      .or(
        'and(blocker_id.eq.$myId,blocked_id.eq.$otherUserId),'
        'and(blocker_id.eq.$otherUserId,blocked_id.eq.$myId)',
      );

  if (blockCheck.isNotEmpty) {
    throw Exception('You cannot chat with this user.');
  }
    return getOrCreateChat(otherUserId);
  }
}
