/// UserCanal Flutter SDK
///
/// A high-performance Flutter SDK for UserCanal CDP platform with analytics
/// events and structured logging using raw TCP and FlatBuffers.
///
/// ## Features
/// - Fire & forget event tracking
/// - Structured logging with RFC 5424 levels
/// - Raw TCP transport with FlatBuffer serialization
/// - User identification and revenue tracking
/// - Privacy controls (opt-in/opt-out)
/// - Session management
/// - Device context collection
///
/// ## Quick Start
///
/// ```dart
/// import 'package:usercanal_flutter/usercanal_flutter.dart';
///
/// // Configure the SDK
/// await UserCanal.configure(
///   apiKey: 'your-api-key',
///   endpoint: 'collect.usercanal.com:50000',
/// );
///
/// // Track events
/// UserCanal.track('user_signed_up', properties: {
///   'signup_method': 'email',
///   'plan': 'premium',
/// });
///
/// // Log messages
/// UserCanal.logInfo('User completed onboarding');
/// ```
library usercanal_flutter;

// Core SDK exports
export 'src/core/user_canal.dart';
export 'src/core/configuration.dart';

// Models and data structures
export 'src/models/event.dart';
export 'src/models/log_entry.dart';
export 'src/models/revenue.dart';
export 'src/models/user_traits.dart';
export 'src/models/properties.dart';

// Error handling
export 'src/errors/user_canal_error.dart';

// Schema types (will be available after schema generation)
export 'src/schema/schema_types.dart';

// Constants and enums
export 'src/core/constants.dart';

// Phase 2: Networking components
export 'src/networking/network_client.dart';
export 'src/networking/batch_manager.dart';
export 'src/networking/user_canal_client.dart';

// Phase 5: Lifecycle Management (optional Flutter integration)
export 'src/lifecycle/lifecycle_manager.dart';

// Phase 6: Privacy & Data Management
export 'src/storage/storage_manager.dart';

// System Logging (internal SDK debugging)
export 'src/system_logging/system_logging.dart';

// Phase 7: Device Context & Analytics
export 'src/device/device.dart';
