import 'package:eatify/providers/chat_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/private_chat_service.dart';

import '../../providers/inbox_provider.dart';
import 'private_chat_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(inboxProvider); // 👈 now List<String>

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const StartChatDialog(),
          );
        },
      ),

      body: chats.isEmpty
          ? const Center(child: Text('No conversations yet'))
          : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (_, i) {
                final chatId = chats[i];

               return ListTile(
  leading: const CircleAvatar(child: Icon(Icons.person)),

  title: Consumer(
    builder: (_, ref, __) {
      final profileAsync = ref.watch(chatUserProvider(chatId));

      return profileAsync.when(
        data: (p) => Text(p['username'] ?? 'User'),
        loading: () => const Text('Loading...'),
        error: (_, __) => const Text('User'),
      );
    },
  ),

  subtitle: Consumer(
    builder: (_, ref, __) {
      final profileAsync = ref.watch(chatUserProvider(chatId));

      return profileAsync.when(
        data: (p) => Text('ID: ${p['user_number']}'),
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
      );
    },
  ),

  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatScreen(chatId: chatId),
      ),
    );
  },
);
              },
            ),
    );
  }
}

class StartChatDialog extends ConsumerWidget {
  const StartChatDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();

    return AlertDialog(
      title: const Text('Start new chat'),
      content: TextField(
        controller: ctrl,
        decoration:
            const InputDecoration(labelText: 'User ID'),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Start'),
          onPressed: () async {
            final otherId = ctrl.text.trim();
            if (otherId.isEmpty) return;

            final chatId =
                await PrivateChatService.getOrCreateChatByUserNumber(int.parse(otherId));

            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PrivateChatScreen(chatId: chatId),
              ),
            );
          },
        )
      ],
    );
  }
}
