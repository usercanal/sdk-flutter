// Copyright © 2024 UserCanal. All rights reserved.

/// Schema types and FlatBuffer integration for UserCanal Flutter SDK
///
/// This module provides a high-level interface for working with FlatBuffer
/// schemas, including serialization, deserialization, and type-safe access
/// to schema fields.

import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../core/constants.dart';
import '../errors/user_canal_error.dart';

// Generated FlatBuffer classes (TODO: Add correct FlatBuffers package)
// export 'generated/index.dart';

/// Base interface for all schema objects
abstract class SchemaObject {
  /// Serialize this object to FlatBuffer bytes
  Uint8List toFlatBuffer();

  /// Validate this object's data
  void validate();

  /// Get the schema type for this object
  SchemaType get schemaType;
}

/// Common batch structure for all data types
@immutable
class BatchData implements SchemaObject {
  const BatchData({
    required this.apiKey,
    required SchemaType schemaType,
    required this.data,
    this.batchId,
  }) : _schemaType = schemaType;

  /// Fixed 16-byte authentication key
  final Uint8List apiKey;

  /// Optional sequence number for tracking
  final int? batchId;

  /// Schema type for routing
  final SchemaType _schemaType;

  /// Schema-specific data payload
  final Uint8List data;

  @override
  Uint8List toFlatBuffer() {
    // TODO: Phase 2 - Implement using generated FlatBuffer classes
    throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
  }

  @override
  void validate() {
    if (apiKey.length != 16) {
      throw const InvalidConfigurationError('apiKey', 'must be exactly 16 bytes');
    }

    if (data.isEmpty) {
      throw const InvalidEventError('batch data cannot be empty');
    }

    if (batchId != null && batchId! < 0) {
      throw const InvalidEventError('batch ID must be non-negative');
    }
  }

  @override
  SchemaType get schemaType => _schemaType;

  /// Create batch data from API key string
  factory BatchData.fromApiKey({
    required String apiKeyString,
    required SchemaType schemaType,
    required Uint8List data,
    int? batchId,
  }) {
    // Convert hex string to bytes
    final apiKeyBytes = _hexStringToBytes(apiKeyString);

    return BatchData(
      apiKey: apiKeyBytes,
      schemaType: schemaType,
      data: data,
      batchId: batchId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchData &&
          runtimeType == other.runtimeType &&
          _uint8ListEquals(apiKey, other.apiKey) &&
          batchId == other.batchId &&
          _schemaType == other._schemaType &&
          _uint8ListEquals(data, other.data);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(apiKey),
        batchId,
        _schemaType,
        Object.hashAll(data),
      );
}

/// Event data structure
@immutable
class EventData implements SchemaObject {
  const EventData({
    required this.events,
  });

  /// List of events in this batch
  final List<EventEntry> events;

  @override
  Uint8List toFlatBuffer() {
    // TODO: Phase 2 - Implement using generated FlatBuffer classes
    throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
  }

  @override
  void validate() {
    if (events.isEmpty) {
      throw const InvalidEventError('event batch cannot be empty');
    }

    for (final event in events) {
      event.validate();
    }
  }

  @override
  SchemaType get schemaType => SchemaType.event;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventData &&
          runtimeType == other.runtimeType &&
          _listEquals(events, other.events);

  @override
  int get hashCode => Object.hashAll(events);
}

/// Single event entry
@immutable
class EventEntry implements SchemaObject {
  const EventEntry({
    required this.timestamp,
    required this.eventType,
    required this.userId,
    required this.payload,
  });

  /// Unix timestamp in milliseconds
  final int timestamp;

  /// Processing path selector
  final EventType eventType;

  /// Fixed 16-byte UUID
  final Uint8List userId;

  /// Event data as bytes
  final Uint8List payload;

  @override
  Uint8List toFlatBuffer() {
    // TODO: Phase 2 - Implement using generated FlatBuffer classes
    throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
  }

  @override
  void validate() {
    if (timestamp <= 0) {
      throw const InvalidEventError('timestamp must be positive');
    }

    if (userId.length != 16) {
      throw const InvalidEventError('user ID must be exactly 16 bytes');
    }

    if (payload.isEmpty) {
      throw const InvalidEventError('event payload cannot be empty');
    }
  }

  @override
  SchemaType get schemaType => SchemaType.event;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventEntry &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          eventType == other.eventType &&
          _uint8ListEquals(userId, other.userId) &&
          _uint8ListEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(
        timestamp,
        eventType,
        Object.hashAll(userId),
        Object.hashAll(payload),
      );
}

/// Log data structure
@immutable
class LogData implements SchemaObject {
  const LogData({
    required this.logs,
  });

  /// List of log entries in this batch
  final List<LogEntry> logs;

  @override
  Uint8List toFlatBuffer() {
    // TODO: Phase 2 - Implement using generated FlatBuffer classes
    throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
  }

  @override
  void validate() {
    if (logs.isEmpty) {
      throw const InvalidLogEntryError('log batch cannot be empty');
    }

    for (final log in logs) {
      log.validate();
    }
  }

  @override
  SchemaType get schemaType => SchemaType.log;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogData &&
          runtimeType == other.runtimeType &&
          _listEquals(logs, other.logs);

  @override
  int get hashCode => Object.hashAll(logs);
}

/// Single log entry
@immutable
class LogEntry implements SchemaObject {
  const LogEntry({
    required this.eventType,
    required this.contextId,
    required this.level,
    required this.timestamp,
    required this.source,
    required this.service,
    required this.payload,
  });

  /// Primary field for routing
  final LogEventType eventType;

  /// Session/transaction ID for correlation
  final int contextId;

  /// Severity level
  final LogLevel level;

  /// Source timestamp (ms since epoch)
  final int timestamp;

  /// Source hostname/instance
  final String source;

  /// Service/application name
  final String service;

  /// Structured data as bytes
  final Uint8List payload;

  @override
  Uint8List toFlatBuffer() {
    // TODO: Phase 2 - Implement using generated FlatBuffer classes
    throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
  }

  @override
  void validate() {
    if (timestamp <= 0) {
      throw const InvalidLogEntryError('timestamp must be positive');
    }

    if (source.isEmpty) {
      throw const InvalidLogEntryError('source cannot be empty');
    }

    if (service.isEmpty) {
      throw const InvalidLogEntryError('service cannot be empty');
    }

    if (payload.isEmpty) {
      throw const InvalidLogEntryError('log payload cannot be empty');
    }

    if (service.length > 128) {
      throw const InvalidLogEntryError('service name too long (max 128 characters)');
    }
  }

  @override
  SchemaType get schemaType => SchemaType.log;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntry &&
          runtimeType == other.runtimeType &&
          eventType == other.eventType &&
          contextId == other.contextId &&
          level == other.level &&
          timestamp == other.timestamp &&
          source == other.source &&
          service == other.service &&
          _uint8ListEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(
        eventType,
        contextId,
        level,
        timestamp,
        source,
        service,
        Object.hashAll(payload),
      );
}

/// Schema serialization utilities
class SchemaSerializer {
  SchemaSerializer._();

  /// Serialize any schema object to bytes
  static Uint8List serialize(SchemaObject object) {
    try {
      object.validate();
      return object.toFlatBuffer();
    } catch (e) {
      throw FlatBufferSerializationError(
        'Failed to serialize ${object.runtimeType}',
        e,
      );
    }
  }

  /// Deserialize batch data from bytes
  static BatchData deserializeBatch(Uint8List bytes) {
    try {
      // TODO: Phase 2 - Implement using generated FlatBuffer classes
      throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
    } catch (e) {
      throw FlatBufferDeserializationError(
        'Failed to deserialize batch data',
        e,
      );
    }
  }

  /// Deserialize event data from bytes
  static EventData deserializeEventData(Uint8List bytes) {
    try {
      // TODO: Phase 2 - Implement using generated FlatBuffer classes
      throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
    } catch (e) {
      throw FlatBufferDeserializationError(
        'Failed to deserialize event data',
        e,
      );
    }
  }

  /// Deserialize log data from bytes
  static LogData deserializeLogData(Uint8List bytes) {
    try {
      // TODO: Phase 2 - Implement using generated FlatBuffer classes
      throw UnimplementedError('FlatBuffer generation will be implemented in Phase 2');
    } catch (e) {
      throw FlatBufferDeserializationError(
        'Failed to deserialize log data',
        e,
      );
    }
  }

  /// Create a batch with event data
  static BatchData createEventBatch({
    required String apiKey,
    required List<EventEntry> events,
    int? batchId,
  }) {
    final eventData = EventData(events: events);
    final eventBytes = serialize(eventData);

    return BatchData.fromApiKey(
      apiKeyString: apiKey,
      schemaType: SchemaType.event,
      data: eventBytes,
      batchId: batchId,
    );
  }

  /// Create a batch with log data
  static BatchData createLogBatch({
    required String apiKey,
    required List<LogEntry> logs,
    int? batchId,
  }) {
    final logData = LogData(logs: logs);
    final logBytes = serialize(logData);

    return BatchData.fromApiKey(
      apiKeyString: apiKey,
      schemaType: SchemaType.log,
      data: logBytes,
      batchId: batchId,
    );
  }
}

/// Schema validation utilities
class SchemaValidator {
  SchemaValidator._();

  /// Validate API key format
  static bool isValidApiKey(String apiKey) {
    if (apiKey.length != 32) return false;
    return RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(apiKey);
  }

  /// Validate user ID bytes
  static bool isValidUserId(Uint8List userId) {
    return userId.length == 16;
  }

  /// Validate timestamp
  static bool isValidTimestamp(int timestamp) {
    return timestamp > 0 && timestamp <= DateTime.now().millisecondsSinceEpoch + 86400000; // Allow 1 day future
  }

  /// Validate service name
  static bool isValidServiceName(String service) {
    return service.isNotEmpty && service.length <= 128 && !service.contains('\n');
  }

  /// Validate source name
  static bool isValidSourceName(String source) {
    return source.isNotEmpty && source.length <= 256 && !source.contains('\n');
  }
}

/// Utility functions
Uint8List _hexStringToBytes(String hex) {
  if (hex.length != 32) {
    throw const InvalidApiKeyError('API key must be 32 characters');
  }

  final bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    final hexByte = hex.substring(i, i + 2);
    final byte = int.tryParse(hexByte, radix: 16);
    if (byte == null) {
      throw const InvalidApiKeyError('API key must be valid hexadecimal');
    }
    bytes.add(byte);
  }

  return Uint8List.fromList(bytes);
}

bool _uint8ListEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
