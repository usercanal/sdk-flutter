// Copyright © 2024 UserCanal. All rights reserved.

/// Log entry data model for UserCanal Flutter SDK
///
/// This module defines the log entry data structures used for structured
/// logging throughout the SDK, including log levels, metadata, and
/// serialization helpers.

import 'dart:convert';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import '../core/constants.dart';
import '../errors/user_canal_error.dart';
import 'properties.dart';

/// Core log entry class representing a structured log message
@immutable
class LogEntryModel {
  const LogEntryModel({
    required this.level,
    required this.message,
    required this.timestamp,
    required this.source,
    required this.service,
    this.contextId,
    this.data = Properties.empty,
    this.eventType = LogEventType.log,
  });

  /// Log severity level
  final LogLevel level;

  /// Log message
  final String message;

  /// Unix timestamp in milliseconds
  final int timestamp;

  /// Source hostname/instance identifier
  final String source;

  /// Service/application name
  final String service;

  /// Session/transaction ID for correlation
  final int? contextId;

  /// Additional structured data
  final Properties data;

  /// Log event type for routing
  final LogEventType eventType;

  /// Create an emergency log entry
  factory LogEntryModel.emergency(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.emergency,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create an alert log entry
  factory LogEntryModel.alert(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.alert,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create a critical log entry
  factory LogEntryModel.critical(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.critical,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create an error log entry
  factory LogEntryModel.error(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.error,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create a warning log entry
  factory LogEntryModel.warning(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.warning,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create a notice log entry
  factory LogEntryModel.notice(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.notice,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create an info log entry
  factory LogEntryModel.info(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.info,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create a debug log entry
  factory LogEntryModel.debug(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.debug,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create a trace log entry
  factory LogEntryModel.trace(
    String message, {
    String? service,
    String? source,
    int? contextId,
    Properties data = Properties.empty,
    int? timestamp,
  }) {
    return LogEntryModel(
      level: LogLevel.trace,
      message: message,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: data,
    );
  }

  /// Create a log entry from an exception
  factory LogEntryModel.fromException(
    Object exception, {
    StackTrace? stackTrace,
    LogLevel level = LogLevel.error,
    String? service,
    String? source,
    int? contextId,
    Properties additionalData = Properties.empty,
    int? timestamp,
  }) {
    final data = additionalData
        .withProperty('exception_type', exception.runtimeType.toString())
        .withProperty('exception_message', exception.toString());

    final finalData = stackTrace != null
        ? data.withProperty('stack_trace', stackTrace.toString())
        : data;

    return LogEntryModel(
      level: level,
      message: 'Exception occurred: ${exception.toString()}',
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: source ?? _getDefaultSource(),
      service: service ?? 'app',
      contextId: contextId,
      data: finalData,
    );
  }

  /// Validate the log entry data
  void validate() {
    if (message.isEmpty) {
      throw const InvalidLogEntryError('log message cannot be empty');
    }

    if (message.length > ValidationConstants.maxLogMessageLength) {
      throw InvalidLogEntryError(
        'log message too long (max ${ValidationConstants.maxLogMessageLength} characters)',
      );
    }

    if (source.isEmpty) {
      throw const InvalidLogEntryError('log source cannot be empty');
    }

    if (service.isEmpty) {
      throw const InvalidLogEntryError('log service cannot be empty');
    }

    if (service.length > ValidationConstants.maxServiceNameLength) {
      throw InvalidLogEntryError(
        'service name too long (max ${ValidationConstants.maxServiceNameLength} characters)',
      );
    }

    if (timestamp <= 0) {
      throw const InvalidLogEntryError('timestamp must be positive');
    }

    if (contextId != null && contextId! < 0) {
      throw const InvalidLogEntryError('context ID must be non-negative');
    }

    // Validate data properties
    try {
      data.validate();
    } catch (e) {
      throw InvalidLogEntryError('invalid data properties: $e');
    }
  }

  /// Serialize log entry payload to JSON bytes
  Uint8List serializePayload() {
    try {
      final payload = <String, dynamic>{
        'message': message,
        'level': level.value,
        'level_name': level.label,
        'data': data.toMap(),
        'timestamp_iso': DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String(),
      };

      final jsonString = json.encode(payload);
      return Uint8List.fromList(utf8.encode(jsonString));
    } catch (e) {
      throw JsonSerializationError('log entry payload serialization', e);
    }
  }

  /// Create a copy with updated fields
  LogEntryModel copyWith({
    LogLevel? level,
    String? message,
    int? timestamp,
    String? source,
    String? service,
    int? contextId,
    Properties? data,
    LogEventType? eventType,
  }) {
    return LogEntryModel(
      level: level ?? this.level,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      service: service ?? this.service,
      contextId: contextId ?? this.contextId,
      data: data ?? this.data,
      eventType: eventType ?? this.eventType,
    );
  }

  /// Add additional data to the log entry
  LogEntryModel withData(Properties additionalData) {
    return copyWith(data: data.withProperties(additionalData.toMap()));
  }

  /// Add context ID if not present
  LogEntryModel withContextId(int contextId) {
    return copyWith(contextId: contextId);
  }

  /// Check if this log level should be logged based on minimum level
  bool shouldLog(LogLevel minimumLevel) {
    return level.isAtLeastAsSevereAs(minimumLevel);
  }

  /// Get human-readable severity description
  String get severityDescription {
    switch (level) {
      case LogLevel.emergency:
        return 'System is unusable';
      case LogLevel.alert:
        return 'Action must be taken immediately';
      case LogLevel.critical:
        return 'Critical conditions';
      case LogLevel.error:
        return 'Error conditions';
      case LogLevel.warning:
        return 'Warning conditions';
      case LogLevel.notice:
        return 'Normal but significant condition';
      case LogLevel.info:
        return 'Informational messages';
      case LogLevel.debug:
        return 'Debug-level messages';
      case LogLevel.trace:
        return 'Detailed trace information';
    }
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'level': level.label,
      'message': message,
      'timestamp': timestamp,
      'source': source,
      'service': service,
      if (contextId != null) 'context_id': contextId,
      'data': data.toMap(),
      'event_type': eventType.name,
    };
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return dateTime.toIso8601String();
  }

  /// Get log entry size estimation in bytes
  int get estimatedBytes {
    final payload = serializePayload();
    return payload.length + 100; // Add overhead estimate
  }

  @override
  String toString() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '[${level.label}] ${dateTime.toIso8601String()} [$service@$source] $message';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntryModel &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          message == other.message &&
          timestamp == other.timestamp &&
          source == other.source &&
          service == other.service &&
          contextId == other.contextId &&
          data == other.data &&
          eventType == other.eventType;

  @override
  int get hashCode => Object.hash(
        level,
        message,
        timestamp,
        source,
        service,
        contextId,
        data,
        eventType,
      );



  static String _getDefaultSource() {
    // In a real implementation, this would get the actual device/app identifier
    return 'flutter-app';
  }
}

/// Log entry builder for fluent API
class LogEntryBuilder {
  LogLevel _level = LogLevel.info;
  String? _message;
  int? _timestamp;
  String _source = LogEntryModel._getDefaultSource();
  String _service = 'app';
  int? _contextId;
  Properties _data = Properties.empty;
  LogEventType _eventType = LogEventType.log;

  LogEntryBuilder level(LogLevel level) {
    _level = level;
    return this;
  }

  LogEntryBuilder message(String message) {
    _message = message;
    return this;
  }

  LogEntryBuilder timestamp(int timestamp) {
    _timestamp = timestamp;
    return this;
  }

  LogEntryBuilder source(String source) {
    _source = source;
    return this;
  }

  LogEntryBuilder service(String service) {
    _service = service;
    return this;
  }

  LogEntryBuilder contextId(int contextId) {
    _contextId = contextId;
    return this;
  }

  LogEntryBuilder data(Properties data) {
    _data = data;
    return this;
  }

  LogEntryBuilder dataField(String key, Object? value) {
    _data = _data.withProperty(key, value);
    return this;
  }

  LogEntryBuilder eventType(LogEventType eventType) {
    _eventType = eventType;
    return this;
  }

  LogEntryModel build() {
    if (_message == null) {
      throw const InvalidLogEntryError('log message is required');
    }

    final logEntry = LogEntryModel(
      level: _level,
      message: _message!,
      timestamp: _timestamp ?? DateTime.now().millisecondsSinceEpoch,
      source: _source,
      service: _service,
      contextId: _contextId,
      data: _data,
      eventType: _eventType,
    );

    logEntry.validate();
    return logEntry;
  }
}

/// Log entry collection for batching
class LogBatch {
  LogBatch({this.maxSize = 100});

  final int maxSize;
  final List<LogEntryModel> _logs = [];

  /// Add a log entry to the batch
  bool add(LogEntryModel logEntry) {
    if (_logs.length >= maxSize) {
      return false; // Batch is full
    }

    logEntry.validate();
    _logs.add(logEntry);
    return true;
  }

  /// Add multiple log entries
  List<LogEntryModel> addAll(Iterable<LogEntryModel> logs) {
    final rejected = <LogEntryModel>[];

    for (final log in logs) {
      if (!add(log)) {
        rejected.add(log);
      }
    }

    return rejected;
  }

  /// Get all log entries in the batch
  List<LogEntryModel> get logs => List.unmodifiable(_logs);

  /// Check if batch is empty
  bool get isEmpty => _logs.isEmpty;

  /// Check if batch is full
  bool get isFull => _logs.length >= maxSize;

  /// Get batch size
  int get length => _logs.length;

  /// Clear the batch
  void clear() => _logs.clear();

  /// Estimate batch size in bytes
  int get estimatedBytes {
    return _logs.fold<int>(0, (sum, log) {
      return sum + log.estimatedBytes;
    });
  }

  /// Filter logs by minimum level
  List<LogEntryModel> filterByLevel(LogLevel minimumLevel) {
    return _logs.where((log) => log.shouldLog(minimumLevel)).toList();
  }

  /// Group logs by service
  Map<String, List<LogEntryModel>> groupByService() {
    final grouped = <String, List<LogEntryModel>>{};
    for (final log in _logs) {
      grouped.putIfAbsent(log.service, () => []).add(log);
    }
    return grouped;
  }

  /// Group logs by level
  Map<LogLevel, List<LogEntryModel>> groupByLevel() {
    final grouped = <LogLevel, List<LogEntryModel>>{};
    for (final log in _logs) {
      grouped.putIfAbsent(log.level, () => []).add(log);
    }
    return grouped;
  }
}
