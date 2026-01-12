import 'package:eatify/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/menu_provider.dart';
import '../../providers/shared_cart_provider.dart';

class SharedMenuScreen extends ConsumerWidget {
  final String restaurantId;
  final String restaurantName;

  const SharedMenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(restaurantMenuProvider(restaurantId));

    return Scaffold(
      appBar: AppBar(title: Text(restaurantName)),
      body: menuAsync.when(
        data: (items) {
          // Wrap in SingleChildScrollView to make screen scrollable
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.price} EGP'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        await ref
                            .read(sharedCartProvider.notifier)
                            .addItemToSharedCart(menuItemId: item.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.confirmation,
                              content: Text(
                                'Added to shared cart',
                                style: TextStyle(color: AppTheme.card),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
