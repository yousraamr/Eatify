import 'package:eatify/models/shared_cart_item_model.dart';

class SplitBillCalculator {
  /// Calculate split bill details for a shared cart
  static SplitBillResult calculate({
    required List<SharedCartItem> items,
    double deliveryFee = 0.0,
    double serviceFee = 0.0,
    double tax = 0.0,
  }) {
    if (items.isEmpty) {
      return SplitBillResult.empty();
    }

    // Group items by user
    final Map<String, List<SharedCartItem>> itemsByUser = {};
    for (var item in items) {
      if (!itemsByUser.containsKey(item.userId)) {
        itemsByUser[item.userId] = [];
      }
      itemsByUser[item.userId]!.add(item);
    }

    // Calculate subtotal per user
    final Map<String, double> subtotalsByUser = {};
    double totalSubtotal = 0.0;

    for (var entry in itemsByUser.entries) {
      final userId = entry.key;
      final userItems = entry.value;
      
      double userSubtotal = 0.0;
      for (var item in userItems) {
        userSubtotal += item.price * item.quantity;
      }
      
      subtotalsByUser[userId] = userSubtotal;
      totalSubtotal += userSubtotal;
    }

    // Calculate fees per user (proportional to their subtotal)
    final Map<String, double> deliveryFeeByUser = {};
    final Map<String, double> serviceFeeByUser = {};
    final Map<String, double> taxByUser = {};
    final Map<String, double> totalByUser = {};

    for (var entry in subtotalsByUser.entries) {
      final userId = entry.key;
      final userSubtotal = entry.value;
      final proportion = totalSubtotal > 0 ? userSubtotal / totalSubtotal : 0;

      deliveryFeeByUser[userId] = deliveryFee * proportion;
      serviceFeeByUser[userId] = serviceFee * proportion;
      taxByUser[userId] = tax * proportion;
      
      totalByUser[userId] = userSubtotal + 
                            deliveryFeeByUser[userId]! + 
                            serviceFeeByUser[userId]! + 
                            taxByUser[userId]!;
    }

    // Create user contributions
    final List<UserContribution> contributions = [];
    for (var entry in itemsByUser.entries) {
      final userId = entry.key;
      contributions.add(
        UserContribution(
          userId: userId,
          items: entry.value,
          subtotal: subtotalsByUser[userId]!,
          deliveryFee: deliveryFeeByUser[userId]!,
          serviceFee: serviceFeeByUser[userId]!,
          tax: taxByUser[userId]!,
          total: totalByUser[userId]!,
        ),
      );
    }

    return SplitBillResult(
      contributions: contributions,
      totalSubtotal: totalSubtotal,
      totalDeliveryFee: deliveryFee,
      totalServiceFee: serviceFee,
      totalTax: tax,
      grandTotal: totalSubtotal + deliveryFee + serviceFee + tax,
      participantCount: itemsByUser.length,
    );
  }

  /// Calculate for equal split (everyone pays same amount)
  static Map<String, double> calculateEqualSplit({
    required List<SharedCartItem> items,
    required List<String> participants, // All user IDs including those without items
    double deliveryFee = 0.0,
    double serviceFee = 0.0,
    double tax = 0.0,
  }) {
    if (participants.isEmpty) return {};

    double totalSubtotal = 0.0;
    for (var item in items) {
      totalSubtotal += item.price * item.quantity;
    }

    final grandTotal = totalSubtotal + deliveryFee + serviceFee + tax;
    final perPerson = grandTotal / participants.length;

    return {
      for (var userId in participants) userId: perPerson,
    };
  }
}

/// Result of split bill calculation
class SplitBillResult {
  final List<UserContribution> contributions;
  final double totalSubtotal;
  final double totalDeliveryFee;
  final double totalServiceFee;
  final double totalTax;
  final double grandTotal;
  final int participantCount;

  SplitBillResult({
    required this.contributions,
    required this.totalSubtotal,
    required this.totalDeliveryFee,
    required this.totalServiceFee,
    required this.totalTax,
    required this.grandTotal,
    required this.participantCount,
  });

  factory SplitBillResult.empty() {
    return SplitBillResult(
      contributions: [],
      totalSubtotal: 0,
      totalDeliveryFee: 0,
      totalServiceFee: 0,
      totalTax: 0,
      grandTotal: 0,
      participantCount: 0,
    );
  }

  /// Get contribution for specific user
  UserContribution? getContribution(String userId) {
    try {
      return contributions.firstWhere((c) => c.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Get total for specific user
  double getTotalForUser(String userId) {
    final contribution = getContribution(userId);
    return contribution?.total ?? 0.0;
  }
}

/// User's contribution to the bill
class UserContribution {
  final String userId;
  final List<SharedCartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tax;
  final double total;

  UserContribution({
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tax,
    required this.total,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Format for display
  String get formattedSubtotal => '${subtotal.toStringAsFixed(2)} EGP';
  String get formattedDeliveryFee => '${deliveryFee.toStringAsFixed(2)} EGP';
  String get formattedServiceFee => '${serviceFee.toStringAsFixed(2)} EGP';
  String get formattedTax => '${tax.toStringAsFixed(2)} EGP';
  String get formattedTotal => '${total.toStringAsFixed(2)} EGP';
}

/// Extension for easy formatting
extension SplitBillResultFormatting on SplitBillResult {
  String get formattedTotalSubtotal => '${totalSubtotal.toStringAsFixed(2)} EGP';
  String get formattedTotalDeliveryFee => '${totalDeliveryFee.toStringAsFixed(2)} EGP';
  String get formattedTotalServiceFee => '${totalServiceFee.toStringAsFixed(2)} EGP';
  String get formattedTotalTax => '${totalTax.toStringAsFixed(2)} EGP';
  String get formattedGrandTotal => '${grandTotal.toStringAsFixed(2)} EGP';
}