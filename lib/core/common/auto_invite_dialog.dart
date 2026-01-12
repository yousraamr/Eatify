import 'package:eatify/providers/cart_invitation_provider.dart';
import 'package:eatify/providers/past_members_provider.dart';
import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoInviteDialog extends ConsumerStatefulWidget {
  final String cartId;
  const AutoInviteDialog({super.key, required this.cartId});

  @override
  ConsumerState<AutoInviteDialog> createState() => _AutoInviteDialogState();
}

class _AutoInviteDialogState extends ConsumerState<AutoInviteDialog> {
  final selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastUsers = ref.watch(pastMembersProvider);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Invite past members', style: theme.textTheme.titleLarge),
      content: SizedBox(
        width: double.maxFinite,
        child: pastUsers.when(
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'No past members yet',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: list.length,
              separatorBuilder: (_, __) => Divider(color: AppTheme.secondary),
              itemBuilder: (_, i) {
                final userId = list[i]['user_id'] as String;
                final username = list[i]['username'] as String;
                final userNumber = list[i]['user_number'];
                return CheckboxListTile(
                 activeColor: theme.primaryColor,
                    checkColor: theme.cardColor,
                    value: selected.contains(userId),
                    title: Text(username, style: theme.textTheme.bodyMedium),
                    subtitle: userNumber != null ? Text(userNumber.toString()) : null,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          selected.add(userId);     // ✅ String
                        } else {
                          selected.remove(userId);  // ✅ String
                        }
                      });
                    },
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
          error: (e, _) => Text(
            e.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.error),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text('Send invitations (${selected.length})',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.cardColor)),
          onPressed: selected.isEmpty
              ? null
              : () async {
                  final controller = ref.read(invitationControllerProvider);
                  for (final uid in selected) {
                    await controller.sendInvitation(toUserId: uid, cartId: widget.cartId);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invited ${selected.length} user(s)',
                          style: TextStyle(color: theme.cardColor)),
                      backgroundColor: AppTheme.confirmation,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
        ),
      ],
    );
  }
}
