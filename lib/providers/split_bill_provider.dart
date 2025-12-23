import 'package:eatify/core/utils/split_bill_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_cart_items_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for split bill calculation
/// Usage: ref.watch(splitBillProvider(cartId))
final splitBillProvider = Provider.family<SplitBillResult, String>(
  (ref, cartId) {
    // Watch cart items
    final itemsAsync = ref.watch(sharedCartItemsProvider(cartId));

    return itemsAsync.when(
      data: (items) {
        // DELIVERY FEE: Split equally among all participants
        const deliveryFee = 30.0; // EGP (you can make this dynamic later)
        
        // SERVICE FEE: 10% of subtotal
        double subtotal = 0.0;
        for (var item in items) {
          subtotal += item.totalPrice;
        }
        final serviceFee = subtotal * 0.10; // 10%
        
        // TAX: 14% of (subtotal + service fee)
        final tax = (subtotal + serviceFee) * 0.14; // 14% VAT

        return SplitBillCalculator.calculate(
          items: items,
          deliveryFee: deliveryFee,
          serviceFee: serviceFee,
          tax: tax,
        );
      },
      loading: () => SplitBillResult.empty(),
      error: (_, __) => SplitBillResult.empty(),
    );
  },
);

/// Provider for current user's total
final myTotalProvider = Provider.family<double, String>(
  (ref, cartId) {
    final splitBill = ref.watch(splitBillProvider(cartId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (currentUserId == null) return 0.0;
    
    return splitBill.getTotalForUser(currentUserId);
  },
);

/// Provider for checking if current user has items in cart
final hasItemsInCartProvider = Provider.family<bool, String>(
  (ref, cartId) {
    final itemsAsync = ref.watch(sharedCartItemsProvider(cartId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (currentUserId == null) return false;
    
    return itemsAsync.when(
      data: (items) => items.any((item) => item.userId == currentUserId),
      loading: () => false,
      error: (_, __) => false,
    );
  },
);