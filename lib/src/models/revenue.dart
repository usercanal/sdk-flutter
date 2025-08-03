// Copyright © 2024 UserCanal. All rights reserved.

/// Revenue tracking data model for UserCanal Flutter SDK
///
/// This module defines the revenue tracking data structures used throughout
/// the SDK, including revenue events, subscription tracking, and purchase
/// validation.

import 'package:meta/meta.dart';
import '../core/constants.dart';
import '../errors/user_canal_error.dart';
import 'properties.dart';

/// Core revenue tracking class for purchase and subscription events
@immutable
class Revenue {
  const Revenue({
    required this.amount,
    required this.currency,
    this.orderId,
    this.productId,
    this.productName,
    this.productCategory,
    this.quantity = 1,
    this.receiptData,
    this.properties = Properties.empty,
  });

  /// Revenue amount (should be positive)
  final double amount;

  /// Currency code (ISO 4217)
  final Currency currency;

  /// Unique order/transaction identifier
  final String? orderId;

  /// Product identifier
  final String? productId;

  /// Human-readable product name
  final String? productName;

  /// Product category for analytics
  final String? productCategory;

  /// Quantity of items purchased
  final int quantity;

  /// Receipt/proof of purchase data
  final String? receiptData;

  /// Additional revenue properties
  final Properties properties;

  /// Create a one-time purchase revenue event
  factory Revenue.purchase({
    required double amount,
    required Currency currency,
    String? orderId,
    String? productId,
    String? productName,
    String? productCategory,
    int quantity = 1,
    String? receiptData,
    Properties properties = Properties.empty,
  }) {
    return Revenue(
      amount: amount,
      currency: currency,
      orderId: orderId,
      productId: productId,
      productName: productName,
      productCategory: productCategory,
      quantity: quantity,
      receiptData: receiptData,
      properties: properties,
    );
  }

  /// Create a subscription revenue event
  factory Revenue.subscription({
    required double amount,
    required Currency currency,
    required String subscriptionId,
    required SubscriptionPeriod period,
    String? productId,
    String? productName,
    int billingCycle = 1,
    String? receiptData,
    Properties properties = Properties.empty,
  }) {
    final subscriptionProperties = properties
        .withProperty('subscription_id', subscriptionId)
        .withProperty('billing_period', period.name)
        .withProperty('billing_cycle', billingCycle)
        .withProperty('is_subscription', true);

    return Revenue(
      amount: amount,
      currency: currency,
      orderId: subscriptionId,
      productId: productId,
      productName: productName,
      productCategory: 'subscription',
      quantity: 1,
      receiptData: receiptData,
      properties: subscriptionProperties,
    );
  }

  /// Create a refund revenue event (negative amount)
  factory Revenue.refund({
    required double originalAmount,
    required Currency currency,
    required String originalOrderId,
    String? refundReason,
    String? refundId,
    Properties properties = Properties.empty,
  }) {
    var refundProperties = properties
        .withProperty('original_order_id', originalOrderId)
        .withProperty('is_refund', true);

    if (refundReason != null) {
      refundProperties = refundProperties.withProperty('refund_reason', refundReason);
    }
    if (refundId != null) {
      refundProperties = refundProperties.withProperty('refund_id', refundId);
    }

    return Revenue(
      amount: -originalAmount.abs(), // Ensure negative amount
      currency: currency,
      orderId: refundId ?? originalOrderId,
      properties: refundProperties,
    );
  }

  /// Validate the revenue data
  void validate() {
    if (amount == 0) {
      throw const InvalidRevenueError('revenue amount cannot be zero');
    }

    if (amount.isInfinite || amount.isNaN) {
      throw const InvalidRevenueError('revenue amount must be a valid number');
    }

    if (quantity <= 0) {
      throw const InvalidRevenueError('quantity must be positive');
    }

    if (orderId != null && orderId!.isEmpty) {
      throw const InvalidRevenueError('order ID cannot be empty');
    }

    if (productId != null && productId!.isEmpty) {
      throw const InvalidRevenueError('product ID cannot be empty');
    }

    if (productName != null && productName!.length > 256) {
      throw const InvalidRevenueError('product name too long (max 256 characters)');
    }

    if (productCategory != null && productCategory!.length > 128) {
      throw const InvalidRevenueError('product category too long (max 128 characters)');
    }

    // Validate properties
    try {
      properties.validate();
    } catch (e) {
      throw InvalidRevenueError('invalid properties: $e');
    }
  }

  /// Get formatted amount with currency symbol
  String get formattedAmount {
    final formattedNumber = amount.toStringAsFixed(2);
    return '${currency.symbol}$formattedNumber';
  }

  /// Get total revenue (amount * quantity)
  double get totalRevenue => amount * quantity;

  /// Get formatted total revenue
  String get formattedTotalRevenue {
    final total = totalRevenue;
    final formattedNumber = total.toStringAsFixed(2);
    return '${currency.symbol}$formattedNumber';
  }

  /// Check if this is a refund
  bool get isRefund => amount < 0;

  /// Check if this is a subscription
  bool get isSubscription => properties.boolean('is_subscription') == true;

  /// Get subscription period if applicable
  SubscriptionPeriod? get subscriptionPeriod {
    final periodStr = properties.string('billing_period');
    if (periodStr != null) {
      return SubscriptionPeriod.values.cast<SubscriptionPeriod?>().firstWhere(
        (period) => period?.name == periodStr,
        orElse: () => null,
      );
    }
    return null;
  }

  /// Convert to event properties for tracking
  Map<String, dynamic> toEventProperties() {
    return {
      'revenue': amount,
      'currency': currency.code,
      'total_revenue': totalRevenue,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (productCategory != null) 'product_category': productCategory,
      'quantity': quantity,
      if (receiptData != null) 'receipt_data': receiptData,
      ...properties.toMap(),
    };
  }

  /// Create a copy with updated values
  Revenue copyWith({
    double? amount,
    Currency? currency,
    String? orderId,
    String? productId,
    String? productName,
    String? productCategory,
    int? quantity,
    String? receiptData,
    Properties? properties,
  }) {
    return Revenue(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      quantity: quantity ?? this.quantity,
      receiptData: receiptData ?? this.receiptData,
      properties: properties ?? this.properties,
    );
  }

  /// Add additional properties
  Revenue withProperties(Properties additionalProperties) {
    return copyWith(
      properties: properties.withProperties(additionalProperties.toMap()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Revenue &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          currency == other.currency &&
          orderId == other.orderId &&
          productId == other.productId &&
          productName == other.productName &&
          productCategory == other.productCategory &&
          quantity == other.quantity &&
          receiptData == other.receiptData &&
          properties == other.properties;

  @override
  int get hashCode => Object.hash(
        amount,
        currency,
        orderId,
        productId,
        productName,
        productCategory,
        quantity,
        receiptData,
        properties,
      );

  @override
  String toString() {
    return 'Revenue(amount: $formattedAmount, currency: ${currency.code}, '
        'orderId: $orderId, productId: $productId, quantity: $quantity)';
  }


}

/// Subscription billing periods
enum SubscriptionPeriod {
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  annual,
  custom,
}

/// Revenue builder for fluent API
class RevenueBuilder {
  double? _amount;
  Currency _currency = Currency.usd;
  String? _orderId;
  String? _productId;
  String? _productName;
  String? _productCategory;
  int _quantity = 1;
  String? _receiptData;
  Properties _properties = Properties.empty;

  RevenueBuilder amount(double amount) {
    _amount = amount;
    return this;
  }

  RevenueBuilder currency(Currency currency) {
    _currency = currency;
    return this;
  }

  RevenueBuilder orderId(String orderId) {
    _orderId = orderId;
    return this;
  }

  RevenueBuilder productId(String productId) {
    _productId = productId;
    return this;
  }

  RevenueBuilder productName(String productName) {
    _productName = productName;
    return this;
  }

  RevenueBuilder productCategory(String productCategory) {
    _productCategory = productCategory;
    return this;
  }

  RevenueBuilder quantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  RevenueBuilder receiptData(String receiptData) {
    _receiptData = receiptData;
    return this;
  }

  RevenueBuilder properties(Properties properties) {
    _properties = properties;
    return this;
  }

  RevenueBuilder property(String key, Object? value) {
    _properties = _properties.withProperty(key, value);
    return this;
  }

  Revenue build() {
    if (_amount == null) {
      throw const InvalidRevenueError('revenue amount is required');
    }

    final revenue = Revenue(
      amount: _amount!,
      currency: _currency,
      orderId: _orderId,
      productId: _productId,
      productName: _productName,
      productCategory: _productCategory,
      quantity: _quantity,
      receiptData: _receiptData,
      properties: _properties,
    );

    revenue.validate();
    return revenue;
  }
}

/// Revenue analytics helper
class RevenueAnalytics {
  RevenueAnalytics._();

  /// Calculate total revenue from a list of revenue events
  static double calculateTotal(List<Revenue> revenues, {Currency? currency}) {
    return revenues
        .where((r) => currency == null || r.currency == currency)
        .fold<double>(0.0, (total, revenue) => total + revenue.totalRevenue);
  }

  /// Group revenues by currency
  static Map<Currency, List<Revenue>> groupByCurrency(List<Revenue> revenues) {
    final grouped = <Currency, List<Revenue>>{};
    for (final revenue in revenues) {
      grouped.putIfAbsent(revenue.currency, () => []).add(revenue);
    }
    return grouped;
  }

  /// Group revenues by product category
  static Map<String?, List<Revenue>> groupByCategory(List<Revenue> revenues) {
    final grouped = <String?, List<Revenue>>{};
    for (final revenue in revenues) {
      grouped.putIfAbsent(revenue.productCategory, () => []).add(revenue);
    }
    return grouped;
  }

  /// Filter revenues by date range
  static List<Revenue> filterByDateRange(
    List<Revenue> revenues,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Note: This would need timestamp information from the revenue events
    // For now, returning all revenues as we don't have timestamps in Revenue model
    return revenues;
  }

  /// Get refund statistics
  static RefundStats getRefundStats(List<Revenue> revenues) {
    final refunds = revenues.where((r) => r.isRefund).toList();
    final totalRefunded = refunds.fold<double>(0.0, (sum, r) => sum + r.totalRevenue.abs());
    final refundCount = refunds.length;
    final totalRevenue = revenues.fold<double>(0.0, (sum, r) => sum + r.totalRevenue);
    final refundRate = totalRevenue > 0 ? (totalRefunded / totalRevenue) : 0.0;

    return RefundStats(
      totalRefunded: totalRefunded,
      refundCount: refundCount,
      refundRate: refundRate,
    );
  }
}

/// Refund statistics
@immutable
class RefundStats {
  const RefundStats({
    required this.totalRefunded,
    required this.refundCount,
    required this.refundRate,
  });

  final double totalRefunded;
  final int refundCount;
  final double refundRate;

  @override
  String toString() {
    return 'RefundStats(totalRefunded: $totalRefunded, '
        'refundCount: $refundCount, refundRate: ${(refundRate * 100).toStringAsFixed(2)}%)';
  }
}
