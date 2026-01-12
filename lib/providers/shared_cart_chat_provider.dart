import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shared_cart_message_model.dart';
import '../services/supabase_service.dart';

final sharedCartChatProvider =
    StateNotifierProvider.family<SharedCartChatController,
        List<SharedCartMessage>, String>((ref, cartId) {
  ref.keepAlive();
  return SharedCartChatController(cartId);
});

class SharedCartChatController
    extends StateNotifier<List<SharedCartMessage>> {
  final String cartId;
  final _client = SupabaseService.client;

  RealtimeChannel? _channel;

  late String _ownerId;
  String get ownerId => _ownerId;

  final Set<String> currentlyTyping = {};
  Timer? _typingTimer;

  SharedCartChatController(this.cartId) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadOwner();
    await _loadMessages();
    _listenRealtime();
    await markAllSeen();

  }

  Future<void> _loadOwner() async {
    final res = await _client
        .from('shared_carts')
        .select('owner_id')
        .eq('id', cartId)
        .maybeSingle();

    if (res != null) _ownerId = res['owner_id'];
  }

  Future<void> _loadMessages() async {
    final msgs = await _client
        .from('shared_cart_messages')
        .select()
        .eq('cart_id', cartId)
        .order('created_at',ascending: true);

    final messages = List<Map<String, dynamic>>.from(msgs)
        .map((e) => SharedCartMessage.fromMap(e))
        .toList();

    if (messages.isEmpty) {
      state = [];
      return;
    }
    final messageIds = messages.map((m) => m.id).toList();

    final seenRows = await _client
        .from('shared_cart_message_seen')
        .select('message_id, user_id')
        .inFilter('message_id', messageIds);

    final seenMap = <String, Set<String>>{};

    for (final row in seenRows) {
      seenMap.putIfAbsent(row['message_id'], () => {});
      seenMap[row['message_id']]!.add(row['user_id']);
    }
    final senderIds = messages.map((m) => m.senderId).toSet().toList();

    final profiles = await _client
        .from('profiles')
        .select('id, username, user_number')
        .inFilter('id', senderIds);

    final profileMap = {
      for (final p in profiles) p['id']: p
    };

        state = messages.map((m) {
      final p = profileMap[m.senderId];

      return m.copyWith(
        username: p?['username'],
        userNumber: p?['user_number'],
        seenBy: seenMap[m.id] ?? {},
      );
    }).toList();
  }

  void _listenRealtime() {
    _channel = _client.channel('shared-cart-chat-$cartId');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'shared_cart_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'cart_id',
            value: cartId,
          ),
          callback: (payload) async {
            final raw = payload.newRecord;
            final msg = SharedCartMessage.fromMap(raw);

            final profile = await _client
                .from('profiles')
                .select('username, user_number')
                .eq('id', msg.senderId)
                .maybeSingle();

            final merged = msg.copyWith(
              username: profile?['username'],
              userNumber: profile?['user_number'],
              seenBy: {},
            );

            state = [...state, merged];
            await markAllSeen();
          },
        )
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'shared_cart_message_seen',
            callback: (payload) {
              final msgId = payload.newRecord['message_id'];
              final userId = payload.newRecord['user_id'];

              state = state.map((m) {
                if (m.id == msgId) {
                  final updated = Set<String>.from(m.seenBy);
                  updated.add(userId);
                  return m.copyWith(seenBy: updated);
                }
                return m;
              }).toList();
            },
          )
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
        .subscribe();
  }

  void startTyping() {
    final uid = _client.auth.currentUser!.id;

    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': uid, 'typing': true},
    );

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), stopTyping);
  }

  void stopTyping() {
    final uid = _client.auth.currentUser!.id;

    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': uid, 'typing': false},
    );
  }

  Future<void> sendMessage(String text) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('shared_cart_messages').insert({
      'cart_id': cartId,
      'sender_id': userId,
      'message': text,
    });
    await markAllSeen();

  }
    Future<void> markAllSeen() async {
      final uid = _client.auth.currentUser!.id;

      final unseen = state.where((m) =>
          m.senderId != uid && !m.seenBy.contains(uid));

      for (final m in unseen) {
        await _client.from('shared_cart_message_seen').insert({
          'message_id': m.id,
          'user_id': uid,
        });
      }
    }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}
