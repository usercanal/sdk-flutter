// logging.dart
// UserCanal Flutter SDK - System Logging
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import 'dart:developer' as developer;
import 'dart:io';

import '../core/configuration.dart';

// MARK: - System Logging

/// Internal SDK logging system (not user-facing logs)
/// This is for debugging the SDK itself, not for user application logs
class SDKLogger {
  // MARK: - Configuration

  /// Whether debug logging is enabled
  static bool isDebugEnabled = false;

  /// Current log level threshold
  static SDKLogLevel logLevel = SDKLogLevel.info;

  // MARK: - Public Logging Methods

  /// Log an info message
  static void info(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.info, message, category: category);
  }

  /// Log an error message
  static void error(String message, {Object? error, LogCategory category = LogCategory.general}) {
    final fullMessage = error != null ? '$message: $error' : message;
    _log(SDKLogLevel.error, fullMessage, category: category);
  }

  /// Log a debug message
  static void debug(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.debug, message, category: category);
  }

  /// Log a warning message
  static void warning(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.warning, message, category: category);
  }

  /// Log a critical message
  static void critical(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.critical, message, category: category);
  }

  /// Log a trace message
  static void trace(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.trace, message, category: category);
  }

  /// Log an emergency message
  static void emergency(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.emergency, message, category: category);
  }

  /// Log an alert message
  static void alert(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.alert, message, category: category);
  }

  /// Log a notice message
  static void notice(String message, {LogCategory category = LogCategory.general}) {
    _log(SDKLogLevel.notice, message, category: category);
  }

  // MARK: - Configuration Methods

  /// Configure SDK logging
  static void configure({bool debugEnabled = false, SDKLogLevel? level}) {
    SDKLogger.isDebugEnabled = debugEnabled;
    if (level != null) {
      SDKLogger.logLevel = level;
    }

    if (debugEnabled) {
      SDKLogger.info('Logging configured: debug enabled, level: ${SDKLogger.logLevel.name}');
    }
  }

  /// Enable debug logging
  static void enableDebug() {
    SDKLogger.isDebugEnabled = true;
    SDKLogger.logLevel = SDKLogLevel.debug;
    SDKLogger.info('Debug logging enabled');
  }

  /// Disable debug logging
  static void disableDebug() {
    SDKLogger.isDebugEnabled = false;
    SDKLogger.logLevel = SDKLogLevel.info;
    SDKLogger.info('Debug logging disabled');
  }

  // MARK: - Convenience Methods

  /// Log network activity
  static void networkActivity(String message, {SDKLogLevel level = SDKLogLevel.debug}) {
    _log(level, message, category: LogCategory.network);
  }

  /// Log batching activity
  static void batchingActivity(String message, {SDKLogLevel level = SDKLogLevel.debug}) {
    _log(level, message, category: LogCategory.batching);
  }

  /// Log device context activity
  static void deviceActivity(String message, {SDKLogLevel level = SDKLogLevel.debug}) {
    _log(level, message, category: LogCategory.device);
  }

  /// Log event processing activity
  static void eventActivity(String message, {SDKLogLevel level = SDKLogLevel.debug}) {
    _log(level, message, category: LogCategory.events);
  }

  /// Log client lifecycle activity
  static void clientActivity(String message, {SDKLogLevel level = SDKLogLevel.info}) {
    _log(level, message, category: LogCategory.client);
  }

  /// Log configuration activity
  static void configActivity(String message, {SDKLogLevel level = SDKLogLevel.info}) {
    _log(level, message, category: LogCategory.config);
  }

  /// Log error activity
  static void errorActivity(String message, {Object? error, SDKLogLevel level = SDKLogLevel.error}) {
    final fullMessage = error != null ? '$message: $error' : message;
    _log(level, fullMessage, category: LogCategory.error);
  }

  // MARK: - Internal Logging

  static void _log(SDKLogLevel level, String message, {required LogCategory category}) {
    // Check if we should log this level
    if (level.priority > logLevel.priority) return;

    final formattedMessage = '[${level.name.toUpperCase()}] UserCanal: $message';
    final categoryName = category.name.toUpperCase();

    // Use developer.log for better debugging experience in IDEs
    if (_shouldUseDeveloperLog()) {
      developer.log(
        formattedMessage,
        name: 'UserCanal.$categoryName',
        level: level.developerLogLevel,
        time: DateTime.now(),
      );
    } else {
      // Fallback to print with timestamp for release builds
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      print('[$timestamp] [$categoryName] $formattedMessage');
    }
  }

  // MARK: - Helper Methods

  static bool _shouldUseDeveloperLog() {
    // Use developer.log in debug mode or when debug logging is enabled
    bool debugMode = false;
    assert(() {
      debugMode = true;
      return true;
    }());

    return debugMode || isDebugEnabled;
  }
}

// MARK: - System Log Level

/// SDK internal log level enumeration for internal SDK logging
/// This is separate from user-facing LogLevel to avoid conflicts
enum SDKLogLevel implements Comparable<SDKLogLevel> {
  emergency(0, 'emergency', 2000),
  alert(1, 'alert', 1900),
  critical(2, 'critical', 1800),
  error(3, 'error', 1000),
  warning(4, 'warning', 900),
  notice(5, 'notice', 800),
  info(6, 'info', 800),
  debug(7, 'debug', 500),
  trace(8, 'trace', 300);

  const SDKLogLevel(this.priority, this.name, this.developerLogLevel);

  /// Priority order for log levels (lower = higher priority)
  final int priority;

  /// String name for the log level
  final String name;

  /// Level for dart:developer log function
  final int developerLogLevel;

  /// Check if this level should be logged given the current threshold
  bool shouldLog(SDKLogLevel threshold) => priority <= threshold.priority;

  /// Convert from string name
  static SDKLogLevel fromString(String name) {
    return SDKLogLevel.values.firstWhere(
      (level) => level.name == name.toLowerCase(),
      orElse: () => SDKLogLevel.info,
    );
  }

  @override
  int compareTo(SDKLogLevel other) => priority.compareTo(other.priority);

  bool operator <(SDKLogLevel other) => priority < other.priority;
  bool operator <=(SDKLogLevel other) => priority <= other.priority;
  bool operator >(SDKLogLevel other) => priority > other.priority;
  bool operator >=(SDKLogLevel other) => priority >= other.priority;
}

// MARK: - Log Categories

/// Categories for organizing SDK logs
enum LogCategory {
  general('general'),
  client('client'),
  network('network'),
  batching('batching'),
  device('device'),
  events('events'),
  error('error'),
  config('config');

  const LogCategory(this.name);

  final String name;

  /// Convert from string name
  static LogCategory fromString(String name) {
    return LogCategory.values.firstWhere(
      (category) => category.name == name.toLowerCase(),
      orElse: () => LogCategory.general,
    );
  }
}
