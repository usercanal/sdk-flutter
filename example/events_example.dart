// events_example.dart
// UserCanal Flutter SDK - Events Usage Example
//
// Copyright © 2024 UserCanal. All rights reserved.
//
// This example demonstrates how to use UserCanal for event tracking
// in a Flutter application. Shows the most common event patterns.

import 'package:usercanal_flutter/usercanal_flutter.dart';

/// Simple events usage example for UserCanal Flutter SDK
void main() async {
  print('=== UserCanal Flutter SDK - Events Example ===\n');

  // 1. Configure the SDK
  await UserCanal.configure(
    apiKey: 'your-32-character-api-key-here',
    endpoint: 'collect.usercanal.com:50000',
    collectDeviceContext: true,
    logLevel: SystemLogLevel.info,
  );

  print('✓ SDK configured successfully\n');

  // 2. User Lifecycle Events
  await demoUserLifecycleEvents();

  // 3. E-commerce Events
  await demoEcommerceEvents();

  // 4. App Engagement Events
  await demoAppEngagementEvents();

  // 5. Custom Events
  await demoCustomEvents();

  // 6. User Management
  await demoUserManagement();

  // 7. Revenue Tracking
  await demoRevenueTracking();

  print('\n=== Events Example Complete ===');
  print('All events have been queued and will be sent to UserCanal.');
}

/// Demonstrate user lifecycle events
Future<void> demoUserLifecycleEvents() async {
  print('--- User Lifecycle Events ---');

  // User registration
  UserCanal.track(EventName.userSignedUp, properties: Properties.fromMap({
    'signup_method': 'email',
    'plan': 'free',
    'referrer': 'google_ads',
    'campaign': 'summer_2024',
  }));
  print('✓ User signed up');

  // User login
  UserCanal.track(EventName.userLoggedIn, properties: Properties.fromMap({
    'login_method': 'email',
    'device_remembered': false,
  }));
  print('✓ User logged in');

  // User logout
  UserCanal.track(EventName.userLoggedOut, properties: Properties.fromMap({
    'session_duration': 1800, // 30 minutes in seconds
    'pages_viewed': 12,
  }));
  print('✓ User logged out');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate e-commerce events
Future<void> demoEcommerceEvents() async {
  print('\n--- E-commerce Events ---');

  // Product viewed
  UserCanal.track(EventName.productViewed, properties: Properties.fromMap({
    'product_id': 'premium_plan_monthly',
    'product_name': 'Premium Plan (Monthly)',
    'category': 'subscription',
    'price': 29.99,
    'currency': 'USD',
  }));
  print('✓ Product viewed');

  // Add to cart
  UserCanal.track(EventName.productAddedToCart, properties: Properties.fromMap({
    'product_id': 'premium_plan_monthly',
    'quantity': 1,
    'price': 29.99,
    'cart_total': 29.99,
  }));
  print('✓ Product added to cart');

  // Checkout started
  UserCanal.track(EventName.checkoutStarted, properties: Properties.fromMap({
    'cart_total': 29.99,
    'item_count': 1,
    'payment_method': 'credit_card',
  }));
  print('✓ Checkout started');

  // Order completed
  UserCanal.track(EventName.orderCompleted, properties: Properties.fromMap({
    'order_id': 'order_789',
    'total': 29.99,
    'tax': 2.40,
    'shipping': 0.00,
    'discount': 5.00,
    'coupon_code': 'SAVE5',
  }));
  print('✓ Order completed');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate app engagement events
Future<void> demoAppEngagementEvents() async {
  print('\n--- App Engagement Events ---');

  // App opened
  UserCanal.track(EventName.appOpened, properties: Properties.fromMap({
    'source': 'push_notification',
    'campaign': 'weekly_digest',
  }));
  print('✓ App opened');

  // Screen viewed
  UserCanal.track(EventName.screenViewed, properties: Properties.fromMap({
    'screen_name': 'product_details',
    'previous_screen': 'product_list',
    'time_spent': 45, // seconds
  }));
  print('✓ Screen viewed');

  // Button clicked
  UserCanal.track(EventName.buttonClicked, properties: Properties.fromMap({
    'button_text': 'Upgrade to Premium',
    'button_location': 'header',
    'screen_name': 'dashboard',
  }));
  print('✓ Button clicked');

  // Form submitted
  UserCanal.track(EventName.formSubmitted, properties: Properties.fromMap({
    'form_name': 'contact_us',
    'form_fields': ['name', 'email', 'message'],
    'validation_errors': 0,
  }));
  print('✓ Form submitted');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate custom events
Future<void> demoCustomEvents() async {
  print('\n--- Custom Events ---');

  // Video events
  UserCanal.track(EventName.custom('video_started'), properties: Properties.fromMap({
    'video_id': 'intro_tutorial',
    'video_title': 'Getting Started with UserCanal',
    'video_duration': 180, // seconds
    'video_quality': '1080p',
  }));
  print('✓ Video started');

  UserCanal.track(EventName.custom('video_completed'), properties: Properties.fromMap({
    'video_id': 'intro_tutorial',
    'completion_percentage': 100,
    'watch_time': 175, // seconds actually watched
  }));
  print('✓ Video completed');

  // Feature usage
  UserCanal.track(EventName.custom('feature_used'), properties: Properties.fromMap({
    'feature_name': 'dashboard_widget',
    'widget_type': 'analytics_chart',
    'interaction_type': 'click',
  }));
  print('✓ Feature used');

  // Search events
  UserCanal.track(EventName.custom('search_performed'), properties: Properties.fromMap({
    'search_query': 'flutter analytics',
    'search_category': 'documentation',
    'results_count': 25,
    'selected_result_position': 3,
  }));
  print('✓ Search performed');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate user management
Future<void> demoUserManagement() async {
  print('\n--- User Management ---');

  // Identify user
  UserCanal.identify('user_12345', traits: Properties.fromMap({
    'email': 'john.doe@example.com',
    'name': 'John Doe',
    'plan': 'premium',
    'signup_date': '2024-01-15',
    'company': 'Acme Corp',
    'role': 'developer',
  }));
  print('✓ User identified');

  // Group association
  UserCanal.group('company_789', properties: Properties.fromMap({
    'company_name': 'Acme Corp',
    'industry': 'Technology',
    'employee_count': 150,
    'plan': 'enterprise',
  }));
  print('✓ User grouped');

  // User alias (linking old and new IDs)
  UserCanal.alias('anonymous_user_abc123', 'user_12345');
  print('✓ User aliased');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate revenue tracking
Future<void> demoRevenueTracking() async {
  print('\n--- Revenue Tracking ---');

  // Simple revenue event
  UserCanal.eventRevenue(
    amount: 29.99,
    currency: Currency.usd,
    orderId: 'order_456',
  );
  print('✓ Revenue tracked (simple)');

  // Detailed revenue event
  UserCanal.eventRevenue(
    amount: 99.99,
    currency: Currency.usd,
    orderId: 'order_789',
    properties: Properties.fromMap({
      'product_id': 'premium_annual',
      'product_name': 'Premium Plan (Annual)',
      'discount_amount': 20.00,
      'tax_amount': 8.00,
      'payment_method': 'credit_card',
      'billing_country': 'US',
      'customer_segment': 'enterprise',
    }),
  );
  print('✓ Revenue tracked (detailed)');

  await Future.delayed(Duration(milliseconds: 100));
}
