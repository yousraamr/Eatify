import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/private_message_model.dart';
import '../services/supabase_service.dart';

final privateChatProvider = StateNotifierProvider.family<
    PrivateChatController,
    List<PrivateMessage>,
    String>((ref, chatId) {
  return PrivateChatController(chatId);
});

class PrivateChatController extends StateNotifier<List<PrivateMessage>> {
  final String chatId;
  RealtimeChannel? _channel;

  // screen state
  bool _isChatOpen = false;

  // typing
  final Set<String> currentlyTyping = {};
  Timer? _typingTimer;

  // presence
  final Set<String> onlineUsers = {};

  PrivateChatController(this.chatId) : super([]) {
    _load();
    _listenRealtime();
  }

  /* ---------------- LOAD ---------------- */

  Future<void> _load() async {
    final res = await SupabaseService.client
        .from('private_messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    state = (res as List)
        .map((e) => PrivateMessage.fromMap(e))
        .toList();
  }

  /* ---------------- REALTIME ---------------- */

  void _listenRealtime() {
    _channel = SupabaseService.client.channel('chat:$chatId');

    onlineUsers.clear();

    _channel!

        // 📩 new message
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'private_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            final msg = PrivateMessage.fromMap(payload.newRecord);
            state = [...state, msg];

            // 🔧 FIX: mark seen only if I am receiver AND chat is open
            final myId =
                SupabaseService.client.auth.currentUser!.id;

            if (msg.senderId != myId && _isChatOpen) {
              await markAsSeen();
            }
          },
        )

        // 👁 seen updates
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'private_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final updated =
                PrivateMessage.fromMap(payload.newRecord);

            state = [
              for (final m in state)
                if (m.id == updated.id) updated else m
            ];
          },
        )

        // ✍️ typing
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final uid = payload['user_id'];
            final isTyping = payload['typing'] == true;

            if (isTyping) {
              currentlyTyping.add(uid);
            } else {
              currentlyTyping.remove(uid);
            }

            state = [...state];
          },
        )

        // 🟢 online
        .onPresenceJoin((payload) {
          for (final meta in payload.newPresences) {
            onlineUsers.add(meta.payload['user_id']);
          }
          state = [...state];
        })

        // 🔴 offline
        .onPresenceLeave((payload) {
          for (final meta in payload.leftPresences) {
            onlineUsers.remove(meta.payload['user_id']);
          }
          state = [...state];
        })

        // 🚀 connect
        .subscribe();
  }

  /* ---------------- SCREEN ---------------- */

  Future<void> onChatOpened() async {
    _isChatOpen = true;

    _channel?.track({
      'user_id': SupabaseService.client.auth.currentUser!.id,
      'online_at': DateTime.now().toIso8601String(),
    });

    // 🔧 FIX: mark unseen messages when opening chat
    await markAsSeen();
  }

  Future<void> onChatClosed() async {
    _isChatOpen = false;

    currentlyTyping.clear();
    onlineUsers.clear();

    _typingTimer?.cancel();
    await _channel?.untrack();
  }

  /* ---------------- TYPING ---------------- */

  void startTyping() {
    final uid = SupabaseService.client.auth.currentUser!.id;

    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': uid,
        'typing': true,
      },
    );

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), stopTyping);
  }

  void stopTyping() {
    final uid = SupabaseService.client.auth.currentUser!.id;

    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': uid,
        'typing': false,
      },
    );
  }

  /* ---------------- SEND ---------------- */

  Future<void> send(String text) async {
    stopTyping();

    final client = SupabaseService.client;
    final myId = client.auth.currentUser!.id;

    // 🔒 find other user in this chat
    final members = await client
        .from('private_chat_members')
        .select('user_id')
        .eq('chat_id', chatId);

    final other = members.firstWhere((e) => e['user_id'] != myId);
    final otherId = other['user_id'];

    // 🚫 block check (both directions)
    final blockCheck = await client
        .from('user_blocks')
        .select()
        .or(
          'and(blocker_id.eq.$myId,blocked_id.eq.$otherId),'
          'and(blocker_id.eq.$otherId,blocked_id.eq.$myId)',
        );

    if (blockCheck.isNotEmpty) {
      throw Exception('You cannot send messages to this user.');
    }

    // 📩 safe to send
    await client.from('private_messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'message': text,
      'is_seen': false,
    });
  }


  /* ---------------- SEEN ---------------- */

  Future<void> markAsSeen() async {
    if (!_isChatOpen) return;

    final uid = SupabaseService.client.auth.currentUser!.id;

    await SupabaseService.client
        .from('private_messages')
        .update({'is_seen': true})
        .eq('chat_id', chatId)
        .neq('sender_id', uid)
        .eq('is_seen', false);
  }

  void goOnline() {
    _channel?.track({
      'user_id': SupabaseService.client.auth.currentUser!.id,
      'online_at': DateTime.now().toIso8601String(),
    });
  }

  void goOffline() {
    _channel?.untrack();
  }


  Future<void> blockUser() async {
  final myId = SupabaseService.client.auth.currentUser!.id;

  final res = await SupabaseService.client
      .from('private_chat_members')
      .select('user_id')
      .eq('chat_id', chatId);

  final other = res.firstWhere((e) => e['user_id'] != myId);

  await SupabaseService.client.from('user_blocks').insert({
    'blocker_id': myId,
    'blocked_id': other['user_id'],
  });

  // remove both from chat
  await SupabaseService.client
      .from('private_chat_members')
      .delete()
      .eq('chat_id', chatId);

  _channel?.unsubscribe();
}
  /* ---------------- CLEANUP ---------------- */

  @override
  void dispose() {
    _typingTimer?.cancel();

    _channel?.untrack();
    _channel?.unsubscribe();
    SupabaseService.client.removeChannel(_channel!);

    super.dispose();
  }
}
