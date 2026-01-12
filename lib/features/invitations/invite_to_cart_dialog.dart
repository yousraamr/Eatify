import 'package:eatify/providers/active_shared_cart_provider.dart';
import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';

class InviteToCartDialog extends ConsumerWidget {
  final String toUserId;

  const InviteToCartDialog({super.key, required this.toUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartsAsync = ref.watch(activeSharedCartsProvider);

    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Invite to Shared Cart',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Divider(color: AppTheme.textPrimary),
            const SizedBox(height: 12),

            // Content
            cartsAsync.when(
              data: (carts) {
                if (carts.isEmpty) {
                  return SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'No active shared carts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  );
                }

                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: carts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final cart = carts[i];

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await SupabaseService.client
                              .from('cart_invitations')
                              .insert({
                                'from_user_id':
                                    SupabaseService.client.auth.currentUser!.id,
                                'to_user_id': toUserId,
                                'cart_id': cart['id'],
                              });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Invitation sent'),
                              backgroundColor: AppTheme.confirmation,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primary,
                                child: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cart ${cart['code']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Restaurant: ${cart['restaurant_id']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              error: (e, _) => SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    e.toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
