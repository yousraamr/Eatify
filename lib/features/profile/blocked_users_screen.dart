import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/blocked_users_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eatify/translations/blocked_strings.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();

    // Load blocked users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(blockedUsersProvider.notifier).load();
    });
  }

  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(BlockedStrings.blockedUsers).tr()),
      body: blocked.isEmpty
          ? Center(child: Text(BlockedStrings.noBlockedUsers).tr())
          : ListView.builder(
              itemCount: blocked.length,
              itemBuilder: (_, i) {
                final user = blocked[i];

                final String userId = user['id'];
                final String username = user['username'] ?? 'Unknown user';
                final dynamic numVal = user['user_number'];

                final String userNumber = numVal == null
                    ? '—'
                    : numVal.toString();

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(username),
                  subtitle: Text('ID: $userNumber'),
                  trailing: TextButton(
                    child: Text(
                      BlockedStrings.unblock.tr(),
                      style: const TextStyle(color: Colors.red),
                    ),
                    onPressed: () async {
                      await ref
                          .read(blockedUsersProvider.notifier)
                          .unblock(userId);
                    },
                  ),
                );
              },
            ),
    );
  }
}
