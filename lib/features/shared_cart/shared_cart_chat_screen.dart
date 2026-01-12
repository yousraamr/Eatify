import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/shared_cart_chat_provider.dart';
import '../../theme/app_theme.dart';

class SharedCartChatScreen extends ConsumerStatefulWidget {
  final String cartId;
  const SharedCartChatScreen({super.key, required this.cartId});

  @override
  ConsumerState<SharedCartChatScreen> createState() =>
      _SharedCartChatScreenState();
}

class _SharedCartChatScreenState extends ConsumerState<SharedCartChatScreen>
    with SingleTickerProviderStateMixin {
  final ctrl = TextEditingController();
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    final messages = ref.watch(sharedCartChatProvider(widget.cartId));
    final controller = ref.read(sharedCartChatProvider(widget.cartId).notifier);
    final typingUsers = controller.currentlyTyping
        .where((id) => id != myId)
        .toList();

    ref.listen(sharedCartChatProvider(widget.cartId), (_, __) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Chat'),
        backgroundColor: AppTheme.card,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 💬 Messages List
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isMe = m.senderId == myId;
                      final isSystem = m.type == 'system';

                      if (isSystem) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.card.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  m.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 300 + i * 50),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppTheme.card
                                            .withOpacity(0.5),
                                        child: Text(
                                          m.username?[0].toUpperCase() ?? 'U',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        m.username ?? 'User',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      if (m.senderId == controller.ownerId)
                                        const SizedBox(width: 4),
                                      if (m.senderId == controller.ownerId)
                                        const Text(
                                          '👑',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 2),
                                Material(
                                  elevation: 2,
                                  shadowColor: Colors.black26,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 260,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isMe
                                          ? LinearGradient(
                                              colors: [
                                                AppTheme.primary.withOpacity(
                                                  0.8,
                                                ),
                                                AppTheme.primary,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isMe
                                          ? null
                                          : AppTheme.card.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      m.message,
                                      style: TextStyle(
                                        color: isMe
                                            ? AppTheme.card
                                            : AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isMe && m.seenBy.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2,
                                      right: 6,
                                    ),
                                    child: Text(
                                      'Seen by ${m.seenBy.length}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ✍️ Typing Indicator
          if (typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Someone is typing...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ⌨ Input Field
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.card.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: ctrl,
                        onChanged: (v) {
                          if (v.isNotEmpty) {
                            controller.startTyping();
                          } else {
                            controller.stopTyping();
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    shape: const CircleBorder(),
                    color: AppTheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.card),
                      onPressed: () async {
                        final text = ctrl.text.trim();
                        if (text.isEmpty) return;
                        ctrl.clear();
                        await controller.sendMessage(text);
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
}
