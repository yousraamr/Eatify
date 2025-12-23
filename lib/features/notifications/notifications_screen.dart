import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notifications_provider.dart';
import '../../services/supabase_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final n = list[i];

              return ListTile(
                leading: Icon(
                  n['is_read']
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: n['is_read']
                      ? Colors.grey
                      : Colors.orange,
                ),
                title: Text(n['title']),
                subtitle: Text(n['body']),
                onTap: () async {
                  await SupabaseService.client
                      .from('notifications')
                      .update({'is_read': true})
                      .eq('id', n['id']);

                  ref.invalidate(notificationsProvider);
                },
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(e.toString())),
      ),
    );
  }
}
