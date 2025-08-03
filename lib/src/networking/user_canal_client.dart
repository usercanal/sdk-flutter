// Copyright © 2024 UserCanal. All rights reserved.

/// UserCanal Client for Flutter SDK
///
/// This module provides the main client interface that coordinates between
/// the batch manager and network client, handling the complete data flow
/// from events/logs to network transmission with proper error handling.

import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import '../core/configuration.dart';
import '../core/constants.dart';
import '../errors/user_canal_error.dart';
import '../models/event.dart';
import '../models/log_entry.dart';
import '../models/properties.dart';
import '../system_logging/logging.dart';
import 'network_client.dart';
import 'batch_manager.dart';
import 'interfaces.dart';

/// Main client that coordinates networking and batching
class UserCanalClient {
  UserCanalClient._({
    required this.apiKey,
    required this.config,
    required this.onError,
  });

  final String apiKey;
  final UserCanalConfig config;
  final UserCanalErrorCallback onError;

  late final INetworkClient _networkClient;
  late final BatchManager _batchManager;

  bool _isInitialized = false;
  bool _isShuttingDown = false;

  // Connection state management
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _incomingDataSubscription;

  // Performance tracking
  int _eventsSent = 0;
  int _logsSent = 0;
  DateTime? _lastActivityTime;

  /// Create and initialize a new UserCanal client
  static Future<UserCanalClient> create({
    required String apiKey,
    required UserCanalConfig config,
    required UserCanalErrorCallback onError,
  }) async {
    SDKLogger.info('Creating UserCanal client with endpoint: ${config.endpoint}', category: LogCategory.client);

    final client = UserCanalClient._(
      apiKey: apiKey,
      config: config,
      onError: onError,
    );

    await client._initialize();
    SDKLogger.info('UserCanal client created successfully', category: LogCategory.client);
    return client;
  }

  // MARK: - Event Tracking Interface

  /// Send a track event
  Future<void> event({
    required String userID,
    required EventName eventName,
    Properties properties = Properties.empty,
  }) async {
    if (_isShuttingDown) {
      SDKLogger.warning('Event dropped - client is shutting down', category: LogCategory.events);
      return;
    }

    try {
      SDKLogger.trace('Processing event: ${eventName.value}', category: LogCategory.events);

      final event = Event(
        userId: userID,
        name: eventName,
        eventType: EventType.track,
        properties: properties,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventId: config.generateEventIds ? _generateEventId() : null,
      );

      await _batchManager.addEvent(event);
      _eventsSent++;
      _lastActivityTime = DateTime.now();

      SDKLogger.trace('Event queued successfully: ${eventName.value}', category: LogCategory.events);

    } catch (e) {
      _handleError(e, 'Failed to send track event');
    }
  }

  /// Send an identify event
  Future<void> eventIdentify({
    required String userID,
    Properties traits = Properties.empty,
  }) async {
    if (_isShuttingDown) return;

    try {
      final event = Event(
        userId: userID,
        name: EventName.custom('identify'),
        eventType: EventType.identify,
        properties: traits,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventId: config.generateEventIds ? _generateEventId() : null,
      );

      await _batchManager.addEvent(event);
      _eventsSent++;
      _lastActivityTime = DateTime.now();

      SDKLogger.trace('Queued identify event for user: $userID', category: LogCategory.events);

    } catch (e) {
      _handleError(e, 'Failed to send identify event');
    }
  }

  /// Send a group event
  Future<void> eventGroup({
    required String userID,
    required String groupID,
    Properties properties = Properties.empty,
  }) async {
    if (_isShuttingDown) return;

    try {
      final groupProperties = Properties.fromMap({
        'group_id': groupID,
        ...properties.toMap(),
      });

      final event = Event(
        userId: userID,
        name: EventName.custom('group'),
        eventType: EventType.group,
        properties: groupProperties,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventId: config.generateEventIds ? _generateEventId() : null,
      );

      await _batchManager.addEvent(event);
      _eventsSent++;
      _lastActivityTime = DateTime.now();

      SDKLogger.trace('Queued group event: $userID -> $groupID', category: LogCategory.events);

    } catch (e) {
      _handleError(e, 'Failed to send group event');
    }
  }

  /// Send an alias event
  Future<void> eventAlias({
    required String previousId,
    required String userId,
  }) async {
    if (_isShuttingDown) return;

    try {
      final aliasProperties = Properties.fromMap({
        'previous_id': previousId,
        'user_id': userId,
      });

      final event = Event(
        userId: userId,
        name: EventName.custom('alias'),
        eventType: EventType.alias,
        properties: aliasProperties,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventId: config.generateEventIds ? _generateEventId() : null,
      );

      await _batchManager.addEvent(event);
      _eventsSent++;
      _lastActivityTime = DateTime.now();

      SDKLogger.trace('Queued alias event: $previousId -> $userId', category: LogCategory.events);

    } catch (e) {
      _handleError(e, 'Failed to send alias event');
    }
  }

  /// Send a revenue event
  Future<void> eventRevenue({
    required String userID,
    required String orderID,
    required double amount,
    required Currency currency,
    Properties properties = Properties.empty,
  }) async {
    if (_isShuttingDown) return;

    try {
      final revenueProperties = Properties.fromMap({
        'order_id': orderID,
        'revenue': amount,
        'currency': currency.code,
        ...properties.toMap(),
      });

      final event = Event(
        userId: userID,
        name: EventName.custom('revenue'),
        eventType: EventType.track,
        properties: revenueProperties,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventId: config.generateEventIds ? _generateEventId() : null,
      );

      await _batchManager.addEvent(event);
      _eventsSent++;
      _lastActivityTime = DateTime.now();

      SDKLogger.trace('Queued revenue event: $amount ${currency.code}', category: LogCategory.events);

    } catch (e) {
      _handleError(e, 'Failed to send revenue event');
    }
  }

  /// Send an enrichment event
  Future<void> enrichmentEvent({
    required String userID,
    required EventName eventName,
    required EventType eventType,
    Properties properties = Properties.empty,
  }) async {
    if (_isShuttingDown) return;

    try {
      final event = Event(
        userId: userID,
        name: eventName,
        eventType: eventType,
        properties: properties,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventId: config.generateEventIds ? _generateEventId() : null,
      );

      await _batchManager.addEvent(event);
      _eventsSent++;
      _lastActivityTime = DateTime.now();

      SDKLogger.trace('Queued ${eventType.name} event: ${eventName.value}', category: LogCategory.events);

    } catch (e) {
      _handleError(e, 'Failed to send enrichment event');
    }
  }

  /// Send an enrichment event (device context, etc.)
  Future<void> enrichEvent({
    required String userID,
    required EventName eventName,
    Properties properties = Properties.empty,
  }) async {
    await enrichmentEvent(
      userID: userID,
      eventName: eventName,
      eventType: EventType.enrich,
      properties: properties,
    );
  }

  // MARK: - Structured Logging Interface

  /// Send an info log
  Future<void> logInfo(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.info, service, message, data);
  }

  /// Send an error log
  Future<void> logError(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.error, service, message, data);
  }

  /// Send a debug log
  Future<void> logDebug(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.debug, service, message, data);
  }

  /// Send a warning log
  Future<void> logWarning(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.warning, service, message, data);
  }

  /// Send a critical log
  Future<void> logCritical(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.critical, service, message, data);
  }

  /// Send an alert log
  Future<void> logAlert(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.alert, service, message, data);
  }

  /// Send an emergency log
  Future<void> logEmergency(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.emergency, service, message, data);
  }

  /// Send a notice log
  Future<void> logNotice(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.notice, service, message, data);
  }

  /// Send a trace log
  Future<void> logTrace(String service, String message, {Properties data = Properties.empty}) async {
    await _sendLog(LogLevel.trace, service, message, data);
  }

  // MARK: - Lifecycle Management

  /// Flush all pending batches
  Future<void> flush() async {
    if (_isShuttingDown) return;

    try {
      await _batchManager.flush();
      SDKLogger.debug('Flushed all pending batches', category: LogCategory.batching);
    } catch (e) {
      _handleError(e, 'Failed to flush batches');
    }
  }

  /// Close the client and cleanup resources
  Future<void> close() async {
    if (_isShuttingDown) return;
    _isShuttingDown = true;

    SDKLogger.info('Shutting down UserCanal client...', category: LogCategory.client);

    try {
      // Flush pending data
      await _batchManager.flush();

      // Cancel subscriptions
      await _connectionStatusSubscription?.cancel();
      await _incomingDataSubscription?.cancel();

      // Shutdown components
      await _batchManager.shutdown();
      await _networkClient.disconnect();

      SDKLogger.info('UserCanal client shutdown complete', category: LogCategory.client);

    } catch (e) {
      _logError('Error during client shutdown: $e');
    }
  }

  // MARK: - Private Implementation

  /// Initialize the client
  Future<void> _initialize() async {
    SDKLogger.debug('Initializing UserCanal client', category: LogCategory.client);

    try {
      // Create network client
      SDKLogger.debug('Creating network client', category: LogCategory.network);
      final networkClient = NetworkClient.getPooledConnection(
        config: config,
        onError: onError,
      );
      _networkClient = networkClient;
      SDKLogger.debug('Network client created successfully', category: LogCategory.network);

      // Create batch manager
      SDKLogger.debug('Creating batch manager', category: LogCategory.batching);
      _batchManager = BatchManager(
        config: config,
        networkClient: _networkClient,
        onError: onError,
      );
      SDKLogger.debug('Batch manager created successfully', category: LogCategory.batching);

      // Set up connection monitoring
      SDKLogger.debug('Setting up connection monitoring', category: LogCategory.network);
      _setupConnectionMonitoring();

      // Connect to server
      SDKLogger.info('Connecting to server: ${config.endpoint}', category: LogCategory.network);
      await _networkClient.connect();

      _isInitialized = true;
      SDKLogger.info('UserCanal client initialized successfully', category: LogCategory.client);

    } catch (e) {
      SDKLogger.error('Client initialization failed', error: e, category: LogCategory.client);
      _handleError(e, 'Failed to initialize client');
      rethrow;
    }
  }

  /// Set up connection status monitoring
  void _setupConnectionMonitoring() {
    _connectionStatusSubscription = _networkClient.connectionStatus.listen(
      (isConnected) {
        _batchManager.setConnectionStatus(isConnected);
        SDKLogger.debug('Connection status changed: $isConnected', category: LogCategory.network);
      },
      onError: (error) {
        _handleError(error, 'Connection status error');
      },
    );

    _incomingDataSubscription = _networkClient.incomingData.listen(
      _handleIncomingData,
      onError: (error) {
        _handleError(error, 'Incoming data error');
      },
    );
  }

  /// Handle incoming data from server
  void _handleIncomingData(Uint8List data) {
    try {
      // TODO: Process server responses (acknowledgments, errors, etc.)
      // For now, just log that we received data
      SDKLogger.trace('Received ${data.length} bytes from server', category: LogCategory.network);
    } catch (e) {
      _handleError(e, 'Failed to process incoming data');
    }
  }

  /// Send a log entry
  Future<void> _sendLog(LogLevel level, String service, String message, Properties data) async {
    if (_isShuttingDown) return;

    try {
      final logEntry = LogEntryModel(
        level: level,
        message: message,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        source: 'flutter-app', // TODO: Get from device context
        service: service,
        contextId: DateTime.now().millisecondsSinceEpoch.hashCode, // TODO: Use proper session ID
        data: data,
      );

      await _batchManager.addLogEntry(logEntry);
      _logsSent++;
      _lastActivityTime = DateTime.now();

      SDKLogger.trace('Queued ${level.label} log: $message', category: LogCategory.events);

    } catch (e) {
      _handleError(e, 'Failed to send log');
    }
  }

  /// Generate a unique event ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    return '${timestamp.toRadixString(36)}_${random.toRadixString(36)}';
  }

  /// Handle errors consistently
  void _handleError(dynamic error, String context) {
    final userCanalError = ErrorUtils.fromException(error);
    _logError('$context: $error');
    onError(userCanalError);
  }

  /// Debug logging (deprecated - use SDKLogger instead)
  void _logDebug(String message) {
    SDKLogger.debug(message, category: LogCategory.client);
  }

  /// Error logging
  void _logError(String message) {
    print('[UserCanalClient] ERROR: $message');
  }

  // MARK: - Status and Statistics

  /// Check if client is connected
  bool get isConnected => _networkClient.isConnected;

  /// Check if client is initialized
  bool get isInitialized => _isInitialized;

  /// Get client statistics
  Map<String, dynamic> get statistics => {
    'initialized': _isInitialized,
    'connected': isConnected,
    'events_sent': _eventsSent,
    'logs_sent': _logsSent,
    'last_activity': _lastActivityTime?.toIso8601String(),
    'event_batch_size': _batchManager.eventBatchSize,
    'log_batch_size': _batchManager.logBatchSize,
    'pending_retries': _batchManager.pendingRetryCount,
  };
}
