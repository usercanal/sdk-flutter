# UserCanal Flutter SDK

A high-performance Flutter SDK for UserCanal Customer Data Platform with analytics events and structured logging.

## Features

- 🚀 **High Performance**: Raw TCP connections with connection pooling
- 📊 **Smart Analytics**: Event tracking with automatic device context enrichment
- 📝 **Structured Logging**: RFC 5424 compliant logging with multiple levels
- 🔒 **Privacy First**: Built-in privacy controls and GDPR compliance
- 🛡️ **Type Safe**: Strongly typed APIs with comprehensive validation
- ⚡ **Production Ready**: Memory efficient with automatic retry and error handling

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  usercanal_flutter: ^0.1.0
```

```bash
flutter pub get
```

## Quick Start

### 1. Configuration

```dart
import 'package:usercanal_flutter/usercanal_flutter.dart';

await UserCanal.configure(
  apiKey: 'your-32-character-api-key',
  endpoint: 'collect.usercanal.com:50000',
  collectDeviceContext: true,  // Automatic device info
);
```

### 2. Event Tracking

```dart
// Track user actions
UserCanal.track(EventName.userSignedUp, properties: Properties.fromMap({
  'signup_method': 'email',
  'plan': 'premium',
  'referrer': 'google',
}));

// User identification
UserCanal.identify('user_12345', traits: Properties.fromMap({
  'email': 'user@example.com',
  'name': 'John Doe',
  'plan': 'premium',
}));

// Revenue tracking
UserCanal.eventRevenue(
  amount: 99.99,
  currency: Currency.usd,
  orderId: 'order_12345',
  properties: Properties.fromMap({
    'product_id': 'premium_plan',
    'discount_code': 'SAVE20',
  }),
);

// Group user associations
UserCanal.group('company_123', properties: Properties.fromMap({
  'company_name': 'Acme Corp',
  'industry': 'Technology',
}));
```

### 3. Structured Logging

```dart
// Different log levels
UserCanal.logInfo('User completed onboarding');
UserCanal.logError('Payment processing failed');
UserCanal.logDebug('Cache hit for user preferences');

// Rich structured data
UserCanal.log(LogLevel.warning, 'API rate limit approaching', 
  service: 'payment_service',
  data: Properties.fromMap({
    'requests_remaining': 10,
    'reset_time': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
    'user_id': 'user_12345',
  })
);
```

## Configuration Options

```dart
await UserCanal.configure(
  apiKey: 'your-api-key',
  endpoint: 'collect.usercanal.com:50000',
  
  // Performance settings
  batchSize: 100,
  flushInterval: 30, // seconds
  
  // Privacy settings
  defaultOptOut: false,
  collectDeviceContext: true,
  
  // Development settings
  logLevel: SystemLogLevel.info, // emergency, alert, critical, error, warning, notice, info, debug, trace
  enableDebugLogging: false,
  
  // Error handling
  onError: (error) {
    print('UserCanal Error: ${error.message}');
  },
);
```

## Privacy Controls

```dart
// User privacy controls
UserCanal.optOut();           // Stop all data collection
UserCanal.optIn();            // Resume data collection
bool opted = UserCanal.isOptedOut();

// GDPR compliance
UserCanal.grantConsent();     // Grant explicit consent
UserCanal.revokeConsent();    // Revoke consent
UserCanal.clearUserData();    // Clear all user data
Map<String, dynamic> data = UserCanal.exportUserData(); // Export user data
```

## Event Names

Use predefined event names for consistency:

```dart
// User lifecycle
UserCanal.track(EventName.userSignedUp);
UserCanal.track(EventName.userLoggedIn);
UserCanal.track(EventName.userLoggedOut);

// E-commerce
UserCanal.track(EventName.productViewed);
UserCanal.track(EventName.productAddedToCart);
UserCanal.track(EventName.orderCompleted);

// App engagement
UserCanal.track(EventName.appOpened);
UserCanal.track(EventName.screenViewed);
UserCanal.track(EventName.buttonClicked);

// Custom events
UserCanal.track(EventName.custom('video_watched'));
```

## Development Configuration

For development, enable detailed logging:

```dart
await UserCanal.configure(
  apiKey: 'dev-api-key',
  endpoint: 'dev.usercanal.com:50000',
  logLevel: SystemLogLevel.debug,        // See all SDK internal logs
  enableDebugLogging: true,              // Enable console output
  batchSize: 10,                         // Smaller batches for testing
  flushInterval: 5,                      // Faster flush for testing
);
```

Console output will show:
```
[CLIENT] [INFO] UserCanal: SDK configuration starting
[NETWORK] [DEBUG] UserCanal: Creating network client
[EVENTS] [DEBUG] UserCanal: Tracked event "user_signed_up"
[BATCHING] [DEBUG] UserCanal: Event added to batch (1/10)
```

## Error Handling

```dart
await UserCanal.configure(
  apiKey: 'your-api-key',
  onError: (UserCanalError error) {
    // Handle SDK errors
    switch (error.code) {
      case 'INVALID_API_KEY':
        print('Check your API key configuration');
        break;
      case 'NETWORK_ERROR':
        print('Network connectivity issue: ${error.message}');
        break;
      case 'VALIDATION_ERROR':
        print('Data validation failed: ${error.message}');
        break;
      default:
        print('UserCanal error: ${error.message}');
    }
  },
);
```

## Testing

For unit testing, you can disable network calls:

```dart
// In your test setup
await UserCanal.configure(
  apiKey: 'test-key',
  endpoint: 'localhost:0', // Causes connection failure
  onError: (error) {
    // Ignore network errors in tests
  },
);
```

## Requirements

- **Dart SDK**: >=3.2.0
- **Flutter**: >=3.16.0
- **iOS**: 12.0+
- **Android**: API level 21+ (Android 5.0)
- **Web**: All modern browsers
- **Desktop**: macOS 10.14+, Windows 10, Linux

## Performance

The SDK is optimized for production use:

- **Memory efficient**: < 5MB memory usage
- **CPU efficient**: < 1% CPU usage on average
- **Network efficient**: Batched requests, connection pooling
- **Battery efficient**: Minimal background processing

## Examples

See the [example/](example/) directory for complete usage examples:

- **[events_example.dart](example/events_example.dart)** - Complete event tracking guide with user lifecycle, e-commerce, and custom events
- **[logging_example.dart](example/logging_example.dart)** - Production structured logging with error handling and service organization

Run any example:
```bash
dart run example/events_example.dart
dart run example/logging_example.dart
```

## Support

- 📖 **Documentation**: [docs.usercanal.com](https://docs.usercanal.com)
- 🐛 **Issues**: [GitHub Issues](https://github.com/usercanal/sdk-flutter/issues)
- 💬 **Community**: [Discord](https://discord.gg/usercanal)
- 📧 **Email**: support@usercanal.com

## License

Copyright © 2024 UserCanal. All rights reserved.