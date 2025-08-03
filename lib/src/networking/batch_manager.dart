// Copyright © 2024 UserCanal. All rights reserved.

/// Batch Manager for UserCanal Flutter SDK
///
/// This module handles batching and flushing of events and logs separately,
/// providing efficient network utilization with configurable batch sizes,
/// flush intervals, and retry logic.

import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import '../core/configuration.dart';
import '../core/constants.dart';
import '../errors/user_canal_error.dart';
import '../models/event.dart';
import '../models/log_entry.dart';
import '../schema/schema_types.dart';
import '../system_logging/logging.dart';
import 'interfaces.dart';

/// Manages batching and flushing of events and logs
class BatchManager {
  BatchManager({
    required this.config,
    required this.networkClient,
    required this.onError,
  }) {
    _startFlushTimers();
  }

  final UserCanalConfig config;
  final INetworkClient networkClient;
  final UserCanalErrorCallback onError;

  // Separate batches for events and logs
  final List<Event> _eventBatch = [];
  final List<LogEntryModel> _logBatch = [];

  // Batch state management
  int _eventBatchSequence = 0;
  int _logBatchSequence = 0;
  DateTime? _lastEventFlush;
  DateTime? _lastLogFlush;

  // Timers for automatic flushing
  Timer? _eventFlushTimer;
  Timer? _logFlushTimer;

  // Retry management
  final List<BatchRetryInfo> _pendingRetries = [];
  Timer? _retryTimer;

  // State management
  bool _isShuttingDown = false;
  bool _isConnected = false;

  // MARK: - Public Interface

  /// Add an event to the batch
  Future<void> addEvent(Event event) async {
    if (_isShuttingDown) {
      SDKLogger.warning('Event dropped - batch manager is shutting down', category: LogCategory.batching);
      return;
    }

    try {
      event.validate();

      _eventBatch.add(event);
      SDKLogger.trace('Event added to batch (${_eventBatch.length}/${config.batchSize})', category: LogCategory.batching);

      // Check if we should flush based on batch size
      if (_eventBatch.length >= config.batchSize) {
        SDKLogger.debug('Event batch full, flushing ${_eventBatch.length} events', category: LogCategory.batching);
        await _flushEvents();
      }
    } catch (e) {
      SDKLogger.error('Failed to add event to batch', error: e, category: LogCategory.batching);
      onError(ErrorUtils.fromException(e));
    }
  }

  /// Add a log entry to the batch
  Future<void> addLogEntry(LogEntryModel logEntry) async {
    if (_isShuttingDown) {
      SDKLogger.warning('Log entry dropped - batch manager is shutting down', category: LogCategory.batching);
      return;
    }

    try {
      logEntry.validate();

      _logBatch.add(logEntry);
      SDKLogger.trace('Log entry added to batch (${_logBatch.length}/${config.batchSize})', category: LogCategory.batching);

      // Check if we should flush based on batch size
      if (_logBatch.length >= config.batchSize) {
        SDKLogger.debug('Log batch full, flushing ${_logBatch.length} entries', category: LogCategory.batching);
        await _flushLogs();
      }
    } catch (e) {
      SDKLogger.error('Failed to add log entry to batch', error: e, category: LogCategory.batching);
      onError(ErrorUtils.fromException(e));
    }
  }

  /// Manually flush all pending batches
  Future<void> flush() async {
    await Future.wait([
      _flushEvents(),
      _flushLogs(),
    ]);
  }

  /// Shutdown the batch manager
  Future<void> shutdown() async {
    _isShuttingDown = true;

    // Cancel timers
    _eventFlushTimer?.cancel();
    _logFlushTimer?.cancel();
    _retryTimer?.cancel();

    // Flush remaining batches
    await flush();

    // Clear pending retries
    _pendingRetries.clear();
  }

  /// Set connection status
  void setConnectionStatus(bool connected) {
    _isConnected = connected;

    if (connected && _pendingRetries.isNotEmpty) {
      _scheduleRetries();
    }
  }

  // MARK: - Private Implementation

  /// Start automatic flush timers
  void _startFlushTimers() {
    final flushInterval = config.flushInterval;

    _eventFlushTimer = Timer.periodic(flushInterval, (_) {
      if (_eventBatch.isNotEmpty) {
        _flushEvents();
      }
    });

    _logFlushTimer = Timer.periodic(flushInterval, (_) {
      if (_logBatch.isNotEmpty) {
        _flushLogs();
      }
    });
  }

  /// Flush events batch
  Future<void> _flushEvents() async {
    if (_eventBatch.isEmpty || _isShuttingDown) return;

    final events = List<Event>.from(_eventBatch);
    _eventBatch.clear();

    SDKLogger.debug('Flushing ${events.length} events (batch #${_eventBatchSequence + 1})', category: LogCategory.batching);

    final batchInfo = EventBatchInfo(
      events: events,
      sequence: ++_eventBatchSequence,
      timestamp: DateTime.now(),
      attempt: 1,
    );

    await _sendEventBatch(batchInfo);
    _lastEventFlush = DateTime.now();

    SDKLogger.trace('Event batch flushed successfully', category: LogCategory.batching);
  }

  /// Flush logs batch
  Future<void> _flushLogs() async {
    if (_logBatch.isEmpty || _isShuttingDown) return;

    final logs = List<LogEntryModel>.from(_logBatch);
    _logBatch.clear();

    SDKLogger.debug('Flushing ${logs.length} log entries (batch #${_logBatchSequence + 1})', category: LogCategory.batching);

    final batchInfo = LogBatchInfo(
      logs: logs,
      sequence: ++_logBatchSequence,
      timestamp: DateTime.now(),
      attempt: 1,
    );

    await _sendLogBatch(batchInfo);
    _lastLogFlush = DateTime.now();
  }

  /// Send event batch over network
  Future<void> _sendEventBatch(EventBatchInfo batchInfo) async {
    try {
      if (!_isConnected) {
        throw const NetworkConnectivityError();
      }

      // Create FlatBuffer batch
      final batchBytes = await _serializeEventBatch(batchInfo);

      // Send via network client
      await networkClient.send(batchBytes);

      _logDebug('Sent event batch ${batchInfo.sequence} with ${batchInfo.events.length} events');

    } catch (e) {
      _handleBatchError(BatchRetryInfo.fromEventBatch(batchInfo), e);
    }
  }

  /// Send log batch over network
  Future<void> _sendLogBatch(LogBatchInfo batchInfo) async {
    try {
      if (!_isConnected) {
        throw const NetworkConnectivityError();
      }

      // Create FlatBuffer batch
      final batchBytes = await _serializeLogBatch(batchInfo);

      // Send via network client
      await networkClient.send(batchBytes);

      _logDebug('Sent log batch ${batchInfo.sequence} with ${batchInfo.logs.length} logs');

    } catch (e) {
      _handleBatchError(BatchRetryInfo.fromLogBatch(batchInfo), e);
    }
  }

  /// Serialize event batch to FlatBuffer bytes
  Future<Uint8List> _serializeEventBatch(EventBatchInfo batchInfo) async {
    // TODO: Implement FlatBuffer serialization
    // This will be implemented when we add the generated FlatBuffer code

    // For now, create a placeholder binary format
    final buffer = <int>[];

    // Header: batch type (1 = events), sequence, count
    buffer.addAll([0x01]); // Schema type: EVENT
    buffer.addAll(_intToBytes(batchInfo.sequence));
    buffer.addAll(_intToBytes(batchInfo.events.length));
    buffer.addAll(_intToBytes(batchInfo.timestamp.millisecondsSinceEpoch));

    // Serialize each event
    for (final event in batchInfo.events) {
      final eventBytes = _serializeEvent(event);
      buffer.addAll(_intToBytes(eventBytes.length));
      buffer.addAll(eventBytes);
    }

    return Uint8List.fromList(buffer);
  }

  /// Serialize log batch to FlatBuffer bytes
  Future<Uint8List> _serializeLogBatch(LogBatchInfo batchInfo) async {
    // TODO: Implement FlatBuffer serialization
    // This will be implemented when we add the generated FlatBuffer code

    // For now, create a placeholder binary format
    final buffer = <int>[];

    // Header: batch type (2 = logs), sequence, count
    buffer.addAll([0x02]); // Schema type: LOG
    buffer.addAll(_intToBytes(batchInfo.sequence));
    buffer.addAll(_intToBytes(batchInfo.logs.length));
    buffer.addAll(_intToBytes(batchInfo.timestamp.millisecondsSinceEpoch));

    // Serialize each log entry
    for (final log in batchInfo.logs) {
      final logBytes = _serializeLogEntry(log);
      buffer.addAll(_intToBytes(logBytes.length));
      buffer.addAll(logBytes);
    }

    return Uint8List.fromList(buffer);
  }

  /// Serialize single event (placeholder implementation)
  List<int> _serializeEvent(Event event) {
    // TODO: Replace with FlatBuffer serialization
    final data = {
      'user_id': event.userId,
      'event_name': event.name.value,
      'event_type': event.eventType.name,
      'properties': event.properties.toMap(),
      'timestamp': event.timestamp,
      'event_id': event.eventId,
    };

    final jsonString = data.toString(); // Simplified for now
    return jsonString.codeUnits;
  }

  /// Serialize single log entry (placeholder implementation)
  List<int> _serializeLogEntry(LogEntryModel log) {
    // TODO: Replace with FlatBuffer serialization
    final data = {
      'level': log.level.value,
      'message': log.message,
      'timestamp': log.timestamp,
      'source': log.source,
      'service': log.service,
      'context_id': log.contextId,
      'data': log.data.toMap(),
    };

    final jsonString = data.toString(); // Simplified for now
    return jsonString.codeUnits;
  }

  /// Convert integer to bytes (little-endian)
  List<int> _intToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  /// Handle batch sending errors
  void _handleBatchError(BatchRetryInfo retryInfo, dynamic error) {
    final userCanalError = ErrorUtils.fromException(error);

    // Determine if we should retry
    if (_shouldRetry(userCanalError, retryInfo.attempt)) {
      retryInfo.attempt++;
      retryInfo.nextRetryTime = DateTime.now().add(_getRetryDelay(retryInfo.attempt));
      _pendingRetries.add(retryInfo);
      _scheduleRetries();

      _logDebug('Batch ${retryInfo.sequence} failed, will retry (attempt ${retryInfo.attempt})');
    } else {
      _logError('Batch ${retryInfo.sequence} failed permanently: $error');
      onError(userCanalError);
    }
  }

  /// Determine if error is retryable
  bool _shouldRetry(UserCanalError error, int attempt) {
    if (attempt >= config.maxRetryAttempts) return false;

    // Retry network errors, timeouts, and server errors (5xx)
    return error is NetworkError ||
           error is ConnectionTimeoutError ||
           error is RequestTimeoutError ||
           (error is ServerError && error.statusCode >= 500);
  }

  /// Get exponential backoff delay
  Duration _getRetryDelay(int attempt) {
    final baseDelay = config.retryBaseDelay;
    final maxDelay = config.retryMaxDelay;

    // Exponential backoff: baseDelay * 2^(attempt-1)
    final delay = baseDelay * (1 << (attempt - 1));
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Schedule retry attempts
  void _scheduleRetries() {
    if (_retryTimer != null && _retryTimer!.isActive) return;
    if (_pendingRetries.isEmpty) return;

    // Find next retry time
    final now = DateTime.now();
    final nextRetry = _pendingRetries
        .where((r) => r.nextRetryTime.isAfter(now))
        .fold<DateTime?>(null, (earliest, retry) {
          if (earliest == null || retry.nextRetryTime.isBefore(earliest)) {
            return retry.nextRetryTime;
          }
          return earliest;
        });

    if (nextRetry != null) {
      final delay = nextRetry.difference(now);
      _retryTimer = Timer(delay, _processRetries);
    }
  }

  /// Process pending retries
  void _processRetries() {
    final now = DateTime.now();
    final readyRetries = _pendingRetries
        .where((r) => r.nextRetryTime.isBefore(now) || r.nextRetryTime.isAtSameMomentAs(now))
        .toList();

    for (final retry in readyRetries) {
      _pendingRetries.remove(retry);

      if (retry.type == BatchType.events) {
        _sendEventBatch(retry.eventBatchInfo!);
      } else {
        _sendLogBatch(retry.logBatchInfo!);
      }
    }

    // Schedule next round if more retries pending
    if (_pendingRetries.isNotEmpty) {
      _scheduleRetries();
    }
  }

  /// Debug logging
  void _logDebug(String message) {
    if (config.enableDebugLogging) {
      print('[BatchManager] $message');
    }
  }

  /// Error logging
  void _logError(String message) {
    print('[BatchManager] ERROR: $message');
  }

  // MARK: - Getters

  /// Get current event batch size
  int get eventBatchSize => _eventBatch.length;

  /// Get current log batch size
  int get logBatchSize => _logBatch.length;

  /// Get pending retry count
  int get pendingRetryCount => _pendingRetries.length;

  /// Check if batches are empty
  bool get isEmpty => _eventBatch.isEmpty && _logBatch.isEmpty;
}

// MARK: - Supporting Classes

/// Information about an event batch
@immutable
class EventBatchInfo {
  const EventBatchInfo({
    required this.events,
    required this.sequence,
    required this.timestamp,
    required this.attempt,
  });

  final List<Event> events;
  final int sequence;
  final DateTime timestamp;
  final int attempt;
}

/// Information about a log batch
@immutable
class LogBatchInfo {
  const LogBatchInfo({
    required this.logs,
    required this.sequence,
    required this.timestamp,
    required this.attempt,
  });

  final List<LogEntryModel> logs;
  final int sequence;
  final DateTime timestamp;
  final int attempt;
}

/// Batch type enumeration
enum BatchType { events, logs }

/// Retry information for failed batches
class BatchRetryInfo {
  BatchRetryInfo({
    required this.type,
    required this.sequence,
    required this.attempt,
    required this.nextRetryTime,
    this.eventBatchInfo,
    this.logBatchInfo,
  });

  final BatchType type;
  final int sequence;
  int attempt;
  DateTime nextRetryTime;
  final EventBatchInfo? eventBatchInfo;
  final LogBatchInfo? logBatchInfo;

  factory BatchRetryInfo.fromEventBatch(EventBatchInfo batchInfo) {
    return BatchRetryInfo(
      type: BatchType.events,
      sequence: batchInfo.sequence,
      attempt: batchInfo.attempt,
      nextRetryTime: DateTime.now(),
      eventBatchInfo: batchInfo,
    );
  }

  factory BatchRetryInfo.fromLogBatch(LogBatchInfo batchInfo) {
    return BatchRetryInfo(
      type: BatchType.logs,
      sequence: batchInfo.sequence,
      attempt: batchInfo.attempt,
      nextRetryTime: DateTime.now(),
      logBatchInfo: batchInfo,
    );
  }
}
