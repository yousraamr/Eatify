import 'package:eatify/providers/cart_invitation_provider.dart';
import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteDialog extends ConsumerWidget {
  final String cartId;
  InviteDialog({super.key, required this.cartId});

  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Invite user', style: theme.textTheme.titleLarge),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'User ID',
          labelStyle: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(style: TextButton.styleFrom(foregroundColor: AppTheme.error), child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          child: const Text('Send invite'),
          onPressed: () async {
            final id = ctrl.text.trim();
            if (id.isEmpty) return;
            await ref.read(invitationControllerProvider).sendInvitationByUserNumber(toUserNumber: int.parse(id), cartId: cartId);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.confirmation,
                content: Text('Invitation sent', style: TextStyle(color: AppTheme.card)),
              ),
            );
          },
        ),
      ],
    );
  }
}
