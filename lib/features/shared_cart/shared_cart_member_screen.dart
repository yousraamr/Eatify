import 'package:eatify/providers/shared_cart_member_provider.dart';
import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartMembersScreen extends ConsumerWidget {
  final String cartId;
  final String ownerId;

  const CartMembersScreen({
    super.key,
    required this.cartId,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(sharedCartMembersProvider(cartId));

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),

      body: members.isEmpty
          ? const Center(child: Text('No members'))
          : ListView.builder(
              itemCount: members.length,
              itemBuilder: (_, i) {
                final row = members[i];
                final profile = row['profiles'];
                final uid = row['user_id'];

                final isOwner = uid == ownerId;

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (profile['username'] ?? 'U')
                          .toString()
                          .toUpperCase()[0],
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(profile['username'] ?? 'User'),
                      if (isOwner)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('👑'),
                        ),
                    ],
                  ),
                  subtitle: Text('ID: ${profile['user_number']}'),

                  trailing: !isOwner
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: AppTheme.error),
                          onPressed: () async {
                            await ref
                                .read(sharedCartMembersProvider(cartId)
                                    .notifier)
                                .removeMember(uid);
                          },
                        )
                      : null,
                );
              },
            ),
    );
  }
}
