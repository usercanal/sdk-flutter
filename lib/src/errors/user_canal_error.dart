// Copyright © 2024 UserCanal. All rights reserved.

/// Comprehensive error handling system for UserCanal Flutter SDK
///
/// This module defines all possible error scenarios that can occur during
/// SDK operations, providing detailed error information for debugging and
/// error recovery strategies.

import 'package:meta/meta.dart';

/// Base class for all UserCanal SDK errors
@immutable
abstract class UserCanalError implements Exception {
  /// Creates a UserCanal error with a message and optional underlying cause
  const UserCanalError(this.message, [this.cause]);

  /// Human-readable error message
  final String message;

  /// Underlying cause of the error (if any)
  final Object? cause;

  /// Error code for programmatic handling
  String get code;

  /// Whether this error is recoverable through retry
  bool get isRecoverable;

  /// Suggested retry delay for recoverable errors
  Duration? get retryDelay => null;

  @override
  String toString() => 'UserCanalError($code): $message';

  /// Create error with additional context
  UserCanalError withContext(String context) {
    return _ContextualUserCanalError(this, context);
  }
}

/// Configuration-related errors
class ConfigurationError extends UserCanalError {
  const ConfigurationError(String message, [Object? cause])
      : super(message, cause);

  @override
  String get code => 'CONFIGURATION_ERROR';

  @override
  bool get isRecoverable => false;
}

/// Invalid API key error
class InvalidApiKeyError extends ConfigurationError {
  const InvalidApiKeyError([String? message])
      : super(message ?? 'API key is invalid or missing');

  @override
  String get code => 'INVALID_API_KEY';
}

/// Invalid endpoint configuration error
class InvalidEndpointError extends ConfigurationError {
  const InvalidEndpointError(String endpoint)
      : super('Invalid endpoint configuration: $endpoint');

  @override
  String get code => 'INVALID_ENDPOINT';
}

/// Invalid configuration parameter error
class InvalidConfigurationError extends ConfigurationError {
  const InvalidConfigurationError(String parameter, String reason)
      : super('Invalid configuration for $parameter: $reason');

  @override
  String get code => 'INVALID_CONFIGURATION';
}

/// Network-related errors
abstract class NetworkError extends UserCanalError {
  const NetworkError(String message, [Object? cause]) : super(message, cause);

  @override
  bool get isRecoverable => true;

  @override
  Duration? get retryDelay => const Duration(seconds: 1);
}

/// Connection establishment failed
class ConnectionError extends NetworkError {
  const ConnectionError(String endpoint, [Object? cause])
      : super('Failed to connect to $endpoint', cause);

  @override
  String get code => 'CONNECTION_ERROR';

  @override
  Duration get retryDelay => const Duration(seconds: 2);
}

/// Connection timeout error
class ConnectionTimeoutError extends NetworkError {
  const ConnectionTimeoutError(this.timeout)
      : super('Connection timed out');

  final Duration timeout;

  @override
  String get code => 'CONNECTION_TIMEOUT';

  @override
  Duration get retryDelay => const Duration(seconds: 5);
}

/// Network request timeout
class RequestTimeoutError extends NetworkError {
  const RequestTimeoutError(this.timeout)
      : super('Request timed out');

  final Duration timeout;

  @override
  String get code => 'REQUEST_TIMEOUT';

  @override
  Duration get retryDelay => const Duration(seconds: 3);
}

/// Server returned an error response
class ServerError extends NetworkError {
  const ServerError(int statusCode, String message)
      : statusCode = statusCode,
        super('Server error ($statusCode): $message');

  final int statusCode;

  @override
  String get code => 'SERVER_ERROR';

  @override
  bool get isRecoverable => statusCode >= 500; // 5xx errors are recoverable

  @override
  Duration? get retryDelay => statusCode >= 500
      ? const Duration(seconds: 10)
      : null;
}

/// Network connectivity issues
class NetworkConnectivityError extends NetworkError {
  const NetworkConnectivityError()
      : super('No network connectivity available');

  @override
  String get code => 'NETWORK_CONNECTIVITY';

  @override
  Duration get retryDelay => const Duration(seconds: 30);
}

/// Data serialization/deserialization errors
abstract class SerializationError extends UserCanalError {
  const SerializationError(String message, [Object? cause])
      : super(message, cause);

  @override
  bool get isRecoverable => false;
}

/// FlatBuffer serialization failed
class FlatBufferSerializationError extends SerializationError {
  const FlatBufferSerializationError(String operation, [Object? cause])
      : super('FlatBuffer serialization failed during $operation', cause);

  @override
  String get code => 'FLATBUFFER_SERIALIZATION';
}

/// FlatBuffer deserialization failed
class FlatBufferDeserializationError extends SerializationError {
  const FlatBufferDeserializationError(String data, [Object? cause])
      : super('FlatBuffer deserialization failed for: $data', cause);

  @override
  String get code => 'FLATBUFFER_DESERIALIZATION';
}

/// JSON serialization error
class JsonSerializationError extends SerializationError {
  const JsonSerializationError(String operation, [Object? cause])
      : super('JSON serialization failed during $operation', cause);

  @override
  String get code => 'JSON_SERIALIZATION';
}

/// Data validation errors
abstract class ValidationError extends UserCanalError {
  const ValidationError(String message, [Object? cause])
      : super(message, cause);

  @override
  bool get isRecoverable => false;
}

/// Invalid event data
class InvalidEventError extends ValidationError {
  const InvalidEventError(String reason)
      : super('Invalid event data: $reason');

  @override
  String get code => 'INVALID_EVENT';
}

/// Invalid log entry
class InvalidLogEntryError extends ValidationError {
  const InvalidLogEntryError(String reason)
      : super('Invalid log entry: $reason');

  @override
  String get code => 'INVALID_LOG_ENTRY';
}

/// Invalid property value
class InvalidPropertyError extends ValidationError {
  const InvalidPropertyError(String property, String reason)
      : super('Invalid property "$property": $reason');

  @override
  String get code => 'INVALID_PROPERTY';
}

/// User identification errors
class InvalidUserIdError extends ValidationError {
  const InvalidUserIdError(String userId)
      : super('Invalid user ID: $userId');

  @override
  String get code => 'INVALID_USER_ID';
}

/// Revenue tracking errors
class InvalidRevenueError extends ValidationError {
  const InvalidRevenueError(String reason)
      : super('Invalid revenue data: $reason');

  @override
  String get code => 'INVALID_REVENUE';
}

/// Storage and persistence errors
abstract class StorageError extends UserCanalError {
  const StorageError(String message, [Object? cause]) : super(message, cause);

  @override
  bool get isRecoverable => true;

  @override
  Duration get retryDelay => const Duration(milliseconds: 500);
}

/// Local storage operation failed
class LocalStorageError extends StorageError {
  const LocalStorageError(String operation, [Object? cause])
      : super('Local storage failed during $operation', cause);

  @override
  String get code => 'LOCAL_STORAGE';
}

/// Storage quota exceeded
class StorageQuotaExceededError extends StorageError {
  const StorageQuotaExceededError(int maxSize)
      : super('Storage quota exceeded (max: ${maxSize}MB)');

  @override
  String get code => 'STORAGE_QUOTA_EXCEEDED';

  @override
  bool get isRecoverable => false; // Need manual intervention
}

/// SDK lifecycle errors
abstract class LifecycleError extends UserCanalError {
  const LifecycleError(String message, [Object? cause]) : super(message, cause);

  @override
  bool get isRecoverable => false;
}

/// SDK not initialized
class SdkNotInitializedError extends LifecycleError {
  const SdkNotInitializedError()
      : super('SDK not initialized. Call UserCanal.configure() first.');

  @override
  String get code => 'SDK_NOT_INITIALIZED';
}

/// SDK already initialized
class SdkAlreadyInitializedError extends LifecycleError {
  const SdkAlreadyInitializedError()
      : super('SDK already initialized');

  @override
  String get code => 'SDK_ALREADY_INITIALIZED';
}

/// SDK is shutting down
class SdkShuttingDownError extends LifecycleError {
  const SdkShuttingDownError()
      : super('SDK is shutting down');

  @override
  String get code => 'SDK_SHUTTING_DOWN';
}

/// Platform-specific errors
abstract class PlatformError extends UserCanalError {
  const PlatformError(String message, [Object? cause]) : super(message, cause);

  @override
  bool get isRecoverable => false;
}

/// Unsupported platform
class UnsupportedPlatformError extends PlatformError {
  const UnsupportedPlatformError(String platform)
      : super('Unsupported platform: $platform');

  @override
  String get code => 'UNSUPPORTED_PLATFORM';
}

/// Platform permission denied
class PlatformPermissionError extends PlatformError {
  const PlatformPermissionError(String permission)
      : super('Platform permission denied: $permission');

  @override
  String get code => 'PLATFORM_PERMISSION';
}

/// Batch processing errors
abstract class BatchError extends UserCanalError {
  const BatchError(String message, [Object? cause]) : super(message, cause);
}

/// Batch size exceeded
class BatchSizeExceededError extends BatchError {
  const BatchSizeExceededError(int size, int maxSize)
      : super('Batch size ($size) exceeds maximum ($maxSize)');

  @override
  String get code => 'BATCH_SIZE_EXCEEDED';

  @override
  bool get isRecoverable => false;
}

/// Batch processing failed
class BatchProcessingError extends BatchError {
  const BatchProcessingError(String reason, [Object? cause])
      : super('Batch processing failed: $reason', cause);

  @override
  String get code => 'BATCH_PROCESSING';

  @override
  bool get isRecoverable => true;

  @override
  Duration get retryDelay => const Duration(seconds: 1);
}

/// Privacy and compliance errors
abstract class PrivacyError extends UserCanalError {
  const PrivacyError(String message, [Object? cause]) : super(message, cause);

  @override
  bool get isRecoverable => false;
}

/// User has opted out of data collection
class UserOptedOutError extends PrivacyError {
  const UserOptedOutError()
      : super('User has opted out of data collection');

  @override
  String get code => 'USER_OPTED_OUT';
}

/// Data collection not consented
class ConsentRequiredError extends PrivacyError {
  const ConsentRequiredError()
      : super('User consent required for data collection');

  @override
  String get code => 'CONSENT_REQUIRED';
}

/// Internal implementation for contextual errors
class _ContextualUserCanalError extends UserCanalError {
  _ContextualUserCanalError(this.originalError, this.context)
      : super('Error with context', originalError.cause);

  final UserCanalError originalError;
  final String context;

  @override
  String get code => originalError.code;

  @override
  bool get isRecoverable => originalError.isRecoverable;

  @override
  Duration? get retryDelay => originalError.retryDelay;

  @override
  String toString() => 'UserCanalError(${originalError.code}): ${originalError.message} (Context: $context)';
}

/// Error callback function type
typedef UserCanalErrorCallback = void Function(UserCanalError error);

/// Error recovery strategy
enum ErrorRecoveryStrategy {
  /// Retry the operation immediately
  retryImmediate,

  /// Retry after a delay
  retryDelayed,

  /// Drop the operation and continue
  drop,

  /// Store for later retry
  store,

  /// Fail and stop processing
  fail,
}

/// Error recovery context
class ErrorRecoveryContext {
  const ErrorRecoveryContext({
    required this.error,
    required this.operation,
    required this.retryCount,
    this.data,
  });

  final UserCanalError error;
  final String operation;
  final int retryCount;
  final Map<String, dynamic>? data;

  /// Determine recovery strategy based on error type and retry count
  ErrorRecoveryStrategy get recommendedStrategy {
    // Max retry attempts reached
    if (retryCount >= 3) {
      return error.isRecoverable
          ? ErrorRecoveryStrategy.store
          : ErrorRecoveryStrategy.drop;
    }

    // Error is not recoverable
    if (!error.isRecoverable) {
      return ErrorRecoveryStrategy.drop;
    }

    // Network errors - retry with delay
    if (error is NetworkError) {
      return ErrorRecoveryStrategy.retryDelayed;
    }

    // Storage errors - retry immediately
    if (error is StorageError) {
      return ErrorRecoveryStrategy.retryImmediate;
    }

    // Batch errors - drop individual item
    if (error is BatchError) {
      return ErrorRecoveryStrategy.drop;
    }

    // Default: retry immediately
    return ErrorRecoveryStrategy.retryImmediate;
  }
}

/// Utility functions for error handling
class ErrorUtils {
  ErrorUtils._();

  /// Check if an error is a network-related issue
  static bool isNetworkError(UserCanalError error) => error is NetworkError;

  /// Check if an error is recoverable
  static bool isRecoverable(UserCanalError error) => error.isRecoverable;

  /// Get appropriate retry delay for an error
  static Duration? getRetryDelay(UserCanalError error) => error.retryDelay;

  /// Convert a generic exception to UserCanalError
  static UserCanalError fromException(Object exception, [StackTrace? stackTrace]) {
    if (exception is UserCanalError) {
      return exception;
    }

    // Handle common Flutter/Dart exceptions
    if (exception is FormatException) {
      return JsonSerializationError('Format error', exception);
    }

    // Note: TimeoutException is not available in all Dart versions
    // if (exception is TimeoutException) {
    //   return RequestTimeoutError(exception.duration ?? const Duration(seconds: 30));
    // }

    if (exception is ArgumentError) {
      return InvalidPropertyError('argument', exception.message ?? 'Invalid argument');
    }

    // Generic error for unknown exceptions
    return _GenericUserCanalError(exception.toString(), exception);
  }

  /// Create error context for debugging
  static Map<String, dynamic> createErrorContext({
    required UserCanalError error,
    String? operation,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'error_code': error.code,
      'error_message': error.message,
      'is_recoverable': error.isRecoverable,
      'retry_delay_ms': error.retryDelay?.inMilliseconds,
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
      'cause': error.cause?.toString(),
      ...?additionalData,
    };
  }
}

/// Generic error for unknown exceptions
class _GenericUserCanalError extends UserCanalError {
  const _GenericUserCanalError(String message, [Object? cause])
      : super(message, cause);

  @override
  String get code => 'GENERIC_ERROR';

  @override
  bool get isRecoverable => false;
}
