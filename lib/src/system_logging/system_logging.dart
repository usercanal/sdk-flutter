// system_logging.dart
// UserCanal Flutter SDK - System Logging Module
//
// Copyright © 2024 UserCanal. All rights reserved.
//

/// System logging module for internal SDK debugging and diagnostics
///
/// This module provides comprehensive logging capabilities for the UserCanal SDK,
/// similar to the Swift SDK's logging system. It includes:
///
/// - Categorized logging (client, network, events, etc.)
/// - Multiple log levels (emergency to trace)
/// - Configurable verbosity
/// - Developer-friendly console output
/// - Filtering capabilities for debugging
///
/// Example usage:
/// ```dart
/// // Configure logging
/// SDKLogger.configure(debugEnabled: true, level: SystemLogLevel.debug);
///
/// // Log messages with categories
/// SDKLogger.info('SDK initialized', category: LogCategory.client);
/// SDKLogger.debug('Processing event', category: LogCategory.events);
/// SDKLogger.error('Network error occurred', error: exception, category: LogCategory.network);
///
/// // Use convenience methods
/// SDKLogger.eventActivity('Event queued for processing');
/// SDKLogger.networkActivity('TCP connection established');
/// ```
library system_logging;

export 'logging.dart';
