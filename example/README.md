# UserCanal Flutter SDK - Examples

This directory contains practical examples showing how to use the UserCanal Flutter SDK in real applications.

## Quick Start

1. **Replace API Key**: Update the API key in each example with your actual UserCanal API key
2. **Run Examples**: Execute any example with `dart run example/filename.dart`
3. **Check Console**: View SDK logs and example output in your console

## Examples Overview

### 📊 [events_example.dart](events_example.dart)
**Complete Event Tracking Guide**

Comprehensive examples of tracking user behavior and business events:
- **User Lifecycle**: signup, login, logout with properties
- **E-commerce**: product views, cart actions, purchases, revenue
- **App Engagement**: screen views, button clicks, form submissions
- **Custom Events**: video watching, feature usage, search
- **User Management**: identification, grouping, aliasing

```dart
// Track user signup with context
UserCanal.track(EventName.userSignedUp, properties: Properties.fromMap({
  'signup_method': 'email',
  'plan': 'premium',
  'source': 'landing_page',
}));

// Track revenue with details
UserCanal.eventRevenue(
  amount: 99.99,
  currency: Currency.usd,
  orderId: 'order_123',
  properties: Properties.fromMap({
    'product_id': 'premium_plan',
    'discount': 10.00,
  }),
);
```

### 📝 [logging_example.dart](logging_example.dart)
**Production Structured Logging**

Real-world logging patterns for monitoring and debugging:
- **Multiple Log Levels**: info, error, warning, debug, trace
- **Structured Data**: rich context with properties
- **Service Organization**: tag logs by service/component
- **Error Context**: detailed error information with stack traces
- **Performance Monitoring**: timing and resource usage

```dart
// Simple application logging
UserCanal.logInfo('User completed onboarding');

// Detailed error logging with context
UserCanal.log(LogLevel.error, 'Payment processing failed',
  service: 'payment_service',
  data: Properties.fromMap({
    'error_code': 'CARD_DECLINED',
    'transaction_id': 'txn_789',
    'user_id': 'user_123',
    'amount': 99.99,
    'retry_count': 2,
  })
);
```

## Configuration Examples

### Development Configuration
Perfect for testing and debugging:

```dart
await UserCanal.configure(
  apiKey: 'your-dev-api-key',
  endpoint: 'dev.usercanal.com:50000',
  logLevel: SystemLogLevel.debug,        // See all SDK logs
  enableDebugLogging: true,              // Console output
  batchSize: 5,                          // Small batches
  flushInterval: 2,                      // Fast flushing
);
```

### Production Configuration
Optimized for performance and privacy:

```dart
await UserCanal.configure(
  apiKey: 'your-prod-api-key',
  endpoint: 'collect.usercanal.com:50000',
  logLevel: SystemLogLevel.warning,      // Minimal logging
  enableDebugLogging: false,             // No console spam
  batchSize: 100,                        // Efficient batching
  flushInterval: 30,                     // Standard flushing
  collectDeviceContext: true,            // Rich analytics
);
```

## Common Patterns

### 1. User Onboarding Flow
```dart
// User starts signup
UserCanal.track(EventName.custom('signup_started'));

// User completes form
UserCanal.track(EventName.custom('signup_form_completed'));

// User verifies email
UserCanal.track(EventName.userSignedUp, properties: Properties.fromMap({
  'signup_method': 'email',
  'email_verified': true,
}));

// Identify the user
UserCanal.identify('user_123', traits: Properties.fromMap({
  'email': 'user@example.com',
  'plan': 'free',
}));
```

### 2. E-commerce Purchase Flow
```dart
// Product viewed
UserCanal.track(EventName.productViewed, properties: Properties.fromMap({
  'product_id': 'premium_plan',
  'price': 29.99,
}));

// Added to cart
UserCanal.track(EventName.productAddedToCart);

// Purchase completed
UserCanal.eventRevenue(
  amount: 29.99,
  currency: Currency.usd,
  orderId: 'order_456',
);
```

### 3. Error Handling Pattern
```dart
try {
  // Your app logic
  await processPayment();
  UserCanal.logInfo('Payment processed successfully');
} catch (error) {
  // Log the error with context
  UserCanal.logError('Payment processing failed', data: Properties.fromMap({
    'error_message': error.toString(),
    'payment_method': 'credit_card',
    'amount': 29.99,
  }));
  
  // Re-throw for app handling
  rethrow;
}
```

## Testing Your Integration

### 1. Verify Events Are Sent
Enable debug logging to see events in console:

```dart
await UserCanal.configure(
  apiKey: 'your-key',
  logLevel: SystemLogLevel.debug,
  enableDebugLogging: true,
);

// You'll see logs like:
// [EVENTS] [DEBUG] UserCanal: Tracked event "user_signed_up"
// [BATCHING] [DEBUG] UserCanal: Event added to batch (1/100)
```

### 2. Test Error Handling
```dart
await UserCanal.configure(
  apiKey: 'invalid-key',  // Intentionally invalid
  onError: (error) {
    print('Caught error: ${error.message}');
    // Handle appropriately in your app
  },
);
```

### 3. Privacy Testing
```dart
// Test opt-out behavior
UserCanal.optOut();
UserCanal.track(EventName.userSignedUp); // Should be dropped
print('Opted out: ${UserCanal.isOptedOut()}'); // true

UserCanal.optIn();
UserCanal.track(EventName.userSignedUp); // Should be sent
```

## Integration Tips

### 1. Flutter App Integration
```dart
// In your main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await UserCanal.configure(
    apiKey: 'your-api-key',
    collectDeviceContext: true,
  );
  
  runApp(MyApp());
}

// In your widgets
class LoginPage extends StatelessWidget {
  void _onLoginSuccess(String userId) {
    UserCanal.identify(userId);
    UserCanal.track(EventName.userLoggedIn);
  }
}
```

### 2. Error Boundaries
```dart
// Global error handler
FlutterError.onError = (FlutterErrorDetails details) {
  UserCanal.logError('Flutter error occurred', data: Properties.fromMap({
    'error': details.exception.toString(),
    'stack_trace': details.stack.toString(),
  }));
  
  // Your existing error handling
};
```

### 3. App Lifecycle Events
```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserCanal.track(EventName.appOpened);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        UserCanal.track(EventName.custom('app_backgrounded'));
        break;
      case AppLifecycleState.resumed:
        UserCanal.track(EventName.custom('app_foregrounded'));
        break;
    }
  }
}
```

## FAQ

### Q: How do I know if events are being sent?
A: Enable debug logging (`enableDebugLogging: true, logLevel: SystemLogLevel.debug`) to see detailed console output.

### Q: What's the difference between events and logs?
A: **Events** track user actions for analytics. **Logs** record system information for debugging and monitoring.

### Q: Can I use this in production?
A: Yes! The SDK is production-ready. Use `SystemLogLevel.warning` or higher for production to reduce console output.

### Q: How do I handle offline scenarios?
A: The SDK automatically queues events when offline and sends them when connectivity returns.

### Q: What data is collected automatically?
A: When `collectDeviceContext: true`, the SDK collects device type, OS version, app version, screen size, and network type. No personal information is collected.

## Support

- 📖 **Documentation**: [docs.usercanal.com](https://docs.usercanal.com)
- 🐛 **Issues**: [GitHub Issues](https://github.com/usercanal/sdk-flutter/issues)
- 💬 **Community**: [Discord](https://discord.gg/usercanal)

---

**Happy tracking! 🚀**