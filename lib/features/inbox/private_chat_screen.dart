import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/private_chat_provider.dart';
import '../../services/supabase_service.dart';
import '../invitations/invite_to_cart_dialog.dart';

class PrivateChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const PrivateChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController ctrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      ref.read(privateChatProvider(widget.chatId).notifier).onChatOpened();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(privateChatProvider(widget.chatId).notifier).onChatClosed();

    ctrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(privateChatProvider(widget.chatId).notifier);
    if (state == AppLifecycleState.resumed) {
      controller.onChatOpened();
    } else {
      controller.onChatClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final messages = ref.watch(privateChatProvider(widget.chatId));
    final controller = ref.read(privateChatProvider(widget.chatId).notifier);

    // Auto scroll to bottom when messages update
    ref.listen(privateChatProvider(widget.chatId), (_, __) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (scrollCtrl.hasClients) {
          scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
        }
      });
    });

    final typingUsers =
        controller.currentlyTyping.where((id) => id != uid).toList();
    final onlineUsers = controller.onlineUsers.where((id) => id != uid).toList();
    final isOtherOnline = onlineUsers.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                          'Chat',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 5,
                        backgroundColor:
                            isOtherOnline ? AppTheme.confirmation : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                     Text(
                        isOtherOnline ? 'Online' : 'Offline',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Invite to cart',
              onPressed: () async {
                final otherUserId = await _getOtherUserId();
                if (otherUserId == null) return;

                showDialog(
                  context: context,
                  builder: (_) => InviteToCartDialog(toUserId: otherUserId),
                );
              },
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'block') {
                  await controller.blockUser();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'block',
                  child: Text('🚫 Block user'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final isMe = m.senderId == uid;
                final isLastMyMessage = isMe && i == messages.length - 1;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      AnimatedMessageBubble(
                        isMe: isMe,
                        message: m.message,
                      ),
                      if (isLastMyMessage)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 6),
                          child: Text(
                              m.isSeen ? 'Seen ✓✓' : 'Sent ✓',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Typing Indicator
          if (typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children:  [
                  Text(
                        'Typing',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                  SizedBox(width: 6),
                  TypingIndicator(),
                ],
              ),
            ),

          // Input Bar
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      onChanged: (v) {
                        v.isNotEmpty
                            ? controller.startTyping()
                            : controller.stopTyping();
                      },
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScale(
                    scale: ctrl.text.isNotEmpty ? 1 : 0.9,
                    duration: const Duration(milliseconds: 150),
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: AppTheme.primary,
                      child:  Icon(Icons.send, color: Theme.of(context).cardColor),
                      onPressed: () async {
                        final text = ctrl.text.trim();
                        if (text.isEmpty) return;
                        ctrl.clear();
                        await controller.send(text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get the other user in chat
  Future<String?> _getOtherUserId() async {
    final myId = SupabaseService.client.auth.currentUser!.id;

    final members = await SupabaseService.client
        .from('private_chat_members')
        .select('user_id')
        .eq('chat_id', widget.chatId);

    for (final m in members) {
      if (m['user_id'] != myId) {
        return m['user_id'];
      }
    }
    return null;
  }
}

/// Animated message bubble
class AnimatedMessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  const AnimatedMessageBubble(
      {super.key, required this.isMe, required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(isMe ? 20 * (1 - value) : -20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
              color: isMe
      ? Theme.of(context).cardColor
      : Theme.of(context).textTheme.bodyMedium!.color,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Animated typing indicator (3 bouncing dots)
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int i) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.2, 1, curve: Curves.easeIn),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: CircleAvatar(
          radius: 3,
          backgroundColor: AppTheme.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [_dot(0), _dot(1), _dot(2)]);
  }
}