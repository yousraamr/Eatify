import 'package:eatify/core/common/auto_invite_dialog.dart';
import 'package:eatify/core/common/inline_split_bill_widget.dart';
import 'package:eatify/features/checkout/checkout_screen.dart';
import 'package:eatify/features/shared_cart/shared_cart_member_screen.dart';
import 'package:eatify/providers/shared_cart_items_provider.dart';
import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/shared_cart_provider.dart';
import 'shared_cart_chat_screen.dart';
import 'shared_menu_screen.dart';
import '../../core/common/invite_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eatify/translations/sharedcart_strings.dart';

class SharedCartScreen extends ConsumerStatefulWidget {
  const SharedCartScreen({super.key});

  @override
  ConsumerState<SharedCartScreen> createState() => _SharedCartScreenState();
}

class _SharedCartScreenState extends ConsumerState<SharedCartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharedCartProvider.notifier).loadActiveSharedCart();
    });

      


    // Animation controller for overall screen animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      ref.listen(sharedCartProvider, (prev, next) {
          final notifier = ref.read(sharedCartProvider.notifier);
          final oldCart = prev?.value;

          // nothing to compare
          if (oldCart == null) return;

          final currentUserId =
              Supabase.instance.client.auth.currentUser!.id;

          final isOwner = oldCart.ownerId == currentUserId;

          // ❌ Only non-owners can be kicked
          if (isOwner) return;

          // ❌ Only react to REAL kicks
          if (next.value == null && notifier.wasKicked) {
            notifier.wasKicked = false;

            Navigator.of(context).popUntil((r) => r.isFirst);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Shared cart removed or you were removed from the shared cart."),
              ),
            );
          }
        });
    final cartAsync = ref.watch(sharedCartProvider);
    final theme = Theme.of(context);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text(SharedcartStrings.sharedCart).tr(),
        backgroundColor: theme.primaryColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: cartAsync.when(
        data: (cart) {
          if (cart == null) return const _NoCartView();
          return _ActiveCartView(
            cartId: cart.id,
            code: cart.code,
            restaurantId: cart.restaurantId,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(), style: TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               NO CART VIEW                                 */
/* -------------------------------------------------------------------------- */
class _NoCartView extends ConsumerWidget {
  const _NoCartView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 60, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(tr(SharedcartStrings.joinSharedCart),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: tr(SharedcartStrings.enterCartCode),
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(tr(SharedcartStrings.joinCart)),
              onPressed: () async {
                try {
                  await ref
                      .read(sharedCartProvider.notifier)
                      .joinSharedCart(codeCtrl.text.trim());
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 30),
          Text(
            tr(SharedcartStrings.instructionsMsg),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              ACTIVE CART VIEW                               */
/* -------------------------------------------------------------------------- */
class _ActiveCartView extends ConsumerWidget {
  final String cartId;
  final String code;
  final String restaurantId;

  const _ActiveCartView({
    required this.cartId,
    required this.code,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final cart = ref.read(sharedCartProvider).value!;
    final isOwner = currentUserId == cart.ownerId;
    final itemsAsync = ref.watch(sharedCartItemsProvider(cartId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Animated Header Card
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Cart Code',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add / Checkout Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.card.withOpacity(0.8),
                            foregroundColor: AppTheme.primary,
                            shadowColor: AppTheme.error.withOpacity(0.5),
                          ),
                          child: const Text('Add Items'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SharedMenuScreen(
                                  restaurantId: restaurantId,
                                  restaurantName: 'Shared Cart Restaurant',
                                ),
                              ),
                            );
                            ref.invalidate(sharedCartItemsProvider(cartId));
                          },
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                            ),
                            child: const Text('Checkout'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CheckoutScreen(isShared: true),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(sharedCartProvider.notifier).leaveOrDiscard();
                    },
                    child: Text(
                      'Leave Cart',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action Buttons Grid
                  _ActionButtonGrid(
                    isOwner: isOwner,
                    cartId: cartId,
                    ownerId: cart.ownerId,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // SPLIT BILL
          InlineSplitBillWidget(cartId: cartId),

          const SizedBox(height: 16),

          // ITEMS LIST
          itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No items added yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isItemOwner = item.userId == currentUserId;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + i * 100),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _CartItemCard(
                      item: item,
                      canEdit: isItemOwner,
                      cartId: cartId,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           ACTION BUTTON GRID                               */
/* -------------------------------------------------------------------------- */
class _ActionButtonGrid extends StatelessWidget {
  final bool isOwner;
  final String cartId;
  final String ownerId;

  const _ActionButtonGrid({
    required this.isOwner,
    required this.cartId,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _ActionButton(
        icon: Icons.chat,
        label: 'Chat',
        color: AppTheme.secondary.withOpacity(0.2),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedCartChatScreen(cartId: cartId),
          ),
        ),
      ),
      _ActionButton(
        icon: Icons.person_add,
        label: 'Invite users',
        color: AppTheme.secondary.withOpacity(0.8),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => InviteDialog(cartId: cartId),
        ),
      ),
      _ActionButton(
        icon: Icons.history,
        label: 'Invite past members',
        color: AppTheme.secondary.withOpacity(0.8),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AutoInviteDialog(cartId: cartId),
        ),
      ),
    ];

    if (isOwner) {
      buttons.add(
        _ActionButton(
          icon: Icons.group,
          label: 'Manage members',
          color: AppTheme.secondary.withOpacity(0.2),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => CartMembersScreen(cartId: cartId, ownerId: ownerId),
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: buttons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + index * 100),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: buttons[index],
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           SINGLE ACTION BUTTON                             */
/* -------------------------------------------------------------------------- */
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           CART ITEM CARD                                    */
/* -------------------------------------------------------------------------- */
class _CartItemCard extends ConsumerWidget {
  final dynamic item;
  final bool canEdit;
  final String cartId;

  const _CartItemCard({
    required this.item,
    required this.canEdit,
    required this.cartId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl =
        item.imageUrl as String?; // Assuming your item has `imageUrl` field

    return Dismissible(
      key: ValueKey(item.id),
      direction: canEdit ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref
            .read(sharedCartItemsProvider(cartId).notifier)
            .removeItem(item.id);
        ref.invalidate(sharedCartItemsProvider(cartId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            content: Text('${item.menuItemName} removed from cart'),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ Image Section
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Container(
                width: 90,
                height: 90,
                color: Theme.of(context).cardColor,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood, color: Colors.grey),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      )
                    : const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),

            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menuItemName,
                      style: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added by ${item.userName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: canEdit
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontWeight: canEdit
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.price.toStringAsFixed(2)} EGP',
                      style: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (canEdit)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: () async {
                      await ref
                          .read(sharedCartItemsProvider(cartId).notifier)
                          .decreaseQuantity(item.id, item.quantity);
                      ref.invalidate(sharedCartItemsProvider(cartId));
                    },
                  ),
                  Text(
                    item.quantity.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () async {
                      await ref
                          .read(sharedCartItemsProvider(cartId).notifier)
                          .increaseQuantity(item.id, item.quantity);
                      ref.invalidate(sharedCartItemsProvider(cartId));
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
