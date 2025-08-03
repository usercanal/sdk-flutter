// Copyright © 2024 UserCanal. All rights reserved.

/// Main UserCanal SDK interface for Flutter applications
///
/// This module provides the primary SDK interface for tracking events,
/// logging messages, and managing user identification. Updated to match
/// Swift SDK design patterns with proper method signatures, anonymous ID
/// management, and event queueing.

import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../core/configuration.dart';
import '../system_logging/logging.dart';
import '../core/constants.dart';
import '../errors/user_canal_error.dart';
import '../models/event.dart';
import '../models/log_entry.dart';
import '../models/properties.dart';
import '../models/revenue.dart';
import '../models/user_traits.dart';
import '../networking/user_canal_client.dart';
import '../lifecycle/lifecycle_manager.dart';
import '../storage/storage_manager.dart';
import '../device/device_context.dart';

/// Initialization state for UserCanal SDK
enum InitializationState {
  notStarted,
  inProgress,
  ready,
  failed,
}

/// Main UserCanal SDK class - singleton interface for analytics and logging
/// Matches Swift SDK design with event queueing and anonymous ID management
class UserCanal {
  UserCanal._internal();

  static final UserCanal _instance = UserCanal._internal();

  /// Singleton instance of UserCanal SDK
  static UserCanal get instance => _instance;

  /// Convenient static access to the shared instance
  static UserCanal get shared => _instance;

  // MARK: - Private State

  UserCanalConfig? _config;
  String? _apiKey;
  InitializationState _initializationState = InitializationState.notStarted;
  String? _currentUserId;
  String? _anonymousId;
  UserTraits? _currentUserTraits;
  bool _isOptedOut = false;
  bool _sessionStarted = false;
  bool _deviceContextSent = false;
  DateTime? _lastDeviceContextTime;
  DateTime? _sessionStartTime;
  String? _sessionId;
  int _sessionEventCount = 0;
  bool _isOnline = true;
  bool _hasConsent = false;
  UserCanalErrorCallback? _errorCallback;

  // Event queue for pre-initialization events
  final EventQueue _eventQueue = EventQueue();
  static const int _maxQueueSize = 1000;

  // Phase 2: Networking components
  UserCanalClient? _client;

  // Device context timer for periodic refresh
  Timer? _deviceContextTimer;

  // MARK: - Initialization State

  /// Check if SDK is ready
  bool get _isReady => _initializationState == InitializationState.ready;

  /// Get current effective user ID (current user or anonymous)
  String get _effectiveUserId => _currentUserId ?? _anonymousId ?? 'anonymous';

  // MARK: - Configuration

  /// Configure UserCanal with API key and optional settings (async)
  /// Matches Swift SDK configure method signature
  static Future<void> configure({
    required String apiKey,
    String? endpoint,
    int? batchSize,
    int? flushInterval,
    bool? defaultOptOut,
    bool? generateEventIds,
    SystemLogLevel? logLevel,
    UserCanalErrorCallback? onError,
  }) async {
    try {
      await _instance._configure(
        apiKey: apiKey,
        endpoint: endpoint,
        batchSize: batchSize,
        flushInterval: flushInterval,
        defaultOptOut: defaultOptOut,
        generateEventIds: generateEventIds,
        logLevel: logLevel,
        onError: onError,
      );
    } catch (e) {
      final error = ErrorUtils.fromException(e);
      onError?.call(error);
      rethrow;
    }
  }

  /// Configure with a complete UserCanalConfig object
  static Future<void> configureWith(
    UserCanalConfig config, {
    required String apiKey,
    UserCanalErrorCallback? onError,
  }) async {
    try {
      await _instance._configureWithConfig(config, apiKey, onError);
    } catch (e) {
      final error = ErrorUtils.fromException(e);
      onError?.call(error);
      rethrow;
    }
  }

  /// Configure UserCanal (fire-and-forget version)
  /// Matches Swift SDK configureAsync method
  static void configureAsync({
    required String apiKey,
    String? endpoint,
    int? batchSize,
    int? flushInterval,
    bool? defaultOptOut,
    bool? generateEventIds,
    SystemLogLevel? logLevel,
  }) {
    _instance._configureAsync(
      apiKey: apiKey,
      endpoint: endpoint,
      batchSize: batchSize,
      flushInterval: flushInterval,
      defaultOptOut: defaultOptOut,
      generateEventIds: generateEventIds,
      logLevel: logLevel,
    );
  }

  /// Internal async configuration method
  Future<void> _configure({
    required String apiKey,
    String? endpoint,
    int? batchSize,
    int? flushInterval,
    bool? defaultOptOut,
    bool? generateEventIds,
    SystemLogLevel? logLevel,
    UserCanalErrorCallback? onError,
  }) async {
    // Configure system logging first
    final finalLogLevel = logLevel ?? SystemLogLevel.info;
    final debugEnabled = finalLogLevel == SystemLogLevel.debug || finalLogLevel == SystemLogLevel.trace;
    final sdkLogLevel = _convertToSDKLogLevel(finalLogLevel);
    SDKLogger.configure(debugEnabled: debugEnabled, level: sdkLogLevel);

    SDKLogger.info('SDK configuration starting', category: LogCategory.client);
    if (_initializationState == InitializationState.ready) {
      SDKLogger.warning('SDK already initialized, throwing error', category: LogCategory.client);
      throw const SdkAlreadyInitializedError();
    }

    if (apiKey.isEmpty) {
      SDKLogger.error('Empty API key provided', category: LogCategory.config);
      throw const InvalidApiKeyError('API key cannot be empty');
    }

    _apiKey = apiKey;
    _errorCallback = onError;
    _initializationState = InitializationState.inProgress;

    SDKLogger.debug('API key set, initialization in progress', category: LogCategory.client);

    try {
      // Auto-enable debug logging when debug level is set
      final finalLogLevel = logLevel ?? SystemLogLevel.info;
      final autoDebugLogging = finalLogLevel == SystemLogLevel.debug || finalLogLevel == SystemLogLevel.trace;

      final configEndpoint = endpoint ?? 'collect.usercanal.com:50000';
      SDKLogger.info('Creating configuration with endpoint: $configEndpoint', category: LogCategory.config);

      _config = UserCanalConfig(
        apiKey: apiKey,
        endpoint: configEndpoint,
        batchSize: batchSize ?? 100,
        flushInterval: Duration(seconds: flushInterval ?? 30),
        enableDebugLogging: autoDebugLogging,
        logLevel: finalLogLevel,
        defaultOptOut: defaultOptOut ?? false,
        generateEventIds: generateEventIds ?? false,
      );

      // Generate or load anonymous ID
      _anonymousId = _getOrCreateAnonymousId();
      SDKLogger.debug('Anonymous ID initialized: $_anonymousId', category: LogCategory.client);

      // Initialize opt-out state
      _initializeOptOutState();
      SDKLogger.debug('Opt-out state initialized: $_isOptedOut', category: LogCategory.client);

      // Initialize consent state
      _initializeConsentState();
      SDKLogger.debug('Consent state initialized', category: LogCategory.client);

      // Phase 2 - Initialize client
      SDKLogger.info('Initializing UserCanal client', category: LogCategory.client);
      _client = await UserCanalClient.create(
        apiKey: apiKey,
        config: _config!,
        onError: _errorCallback ?? _handleError,
      );

      // Initialize device context if enabled
      if (_config!.collectDeviceContext) {
        await DeviceContext.instance.initialize();
        _startDeviceContextTimer();
        SDKLogger.debug('Device context collection enabled', category: LogCategory.device);
      }

      // Mark as ready and process queued events
      _initializationState = InitializationState.ready;
      SDKLogger.info('Processing queued events', category: LogCategory.events);
      await _processQueuedEvents();

      SDKLogger.info('SDK configured successfully', category: LogCategory.client);
    } catch (e) {
      _initializationState = InitializationState.failed;
      SDKLogger.error('SDK configuration failed', error: e, category: LogCategory.client);
      _handleError(ErrorUtils.fromException(e));
      rethrow;
    }
  }

  /// Internal configuration with config object
  Future<void> _configureWithConfig(
    UserCanalConfig config,
    String apiKey,
    UserCanalErrorCallback? onError,
  ) async {
    if (_initializationState == InitializationState.ready) {
      throw const SdkAlreadyInitializedError();
    }

    _apiKey = apiKey;
    _errorCallback = onError;
    _config = config.copyWith(apiKey: apiKey);
    _initializationState = InitializationState.inProgress;

    try {
      _config!.validate();

      // Generate or load anonymous ID
      _anonymousId = _getOrCreateAnonymousId();

      // Initialize opt-out state
      _initializeOptOutState();

      // Initialize consent state
      _initializeConsentState();

      // Phase 2 - Initialize client
      _client = await UserCanalClient.create(
        apiKey: apiKey,
        config: config,
        onError: onError ?? _handleError,
      );

      // Mark as ready and process queued events
      _initializationState = InitializationState.ready;
      await _processQueuedEvents();

      _logDebug('SDK configured successfully');
    } catch (e) {
      _initializationState = InitializationState.failed;
      _handleError(ErrorUtils.fromException(e));
      rethrow;
    }
  }

  /// Fire-and-forget configuration
  void _configureAsync({
    required String apiKey,
    String? endpoint,
    int? batchSize,
    int? flushInterval,
    bool? defaultOptOut,
    bool? generateEventIds,
    SystemLogLevel? logLevel,
  }) {
    unawaited(Future(() async {
      try {
        await _configure(
          apiKey: apiKey,
          endpoint: endpoint,
          batchSize: batchSize,
          flushInterval: flushInterval,
          defaultOptOut: defaultOptOut,
          generateEventIds: generateEventIds,
          logLevel: logLevel,
        );
      } catch (e) {
        _initializationState = InitializationState.failed;
        _handleError(ErrorUtils.fromException(e));
      }
    }));
  }

  // MARK: - Event Tracking (Matches Swift SDK signatures)

  /// Track an event with EventName and Properties
  /// Matches Swift SDK: track(_ eventName: EventName, properties: Properties = Properties())
  static void track(EventName eventName, {Properties properties = Properties.empty}) {
    _instance._track(eventName, properties);
  }

  /// Track an event with string name
  /// Matches Swift SDK: track(_ eventName: String, properties: Properties = Properties())
  static void trackString(String eventName, {Properties properties = Properties.empty}) {
    _instance._track(EventName.custom(eventName), properties);
  }

  /// Track an event with EventName and dictionary properties (convenience)
  /// Matches Swift SDK: track(_ eventName: EventName, properties: [String: Any])
  static void trackWithMap(EventName eventName, Map<String, Object?> properties) {
    _instance._track(eventName, Properties.fromMap(properties));
  }

  /// Track an event with string name and dictionary properties
  /// Matches Swift SDK: track(_ eventName: String, properties: [String: Any])
  static void trackStringWithMap(String eventName, Map<String, Object?> properties) {
    _instance._track(EventName.custom(eventName), Properties.fromMap(properties));
  }

  /// Internal track method
  void _track(EventName eventName, Properties properties) {
    if (_isOptedOut) {
      SDKLogger.debug('Event dropped - user opted out', category: LogCategory.events);
      return;
    }

    if (_requiresConsentAndNotGranted()) {
      SDKLogger.debug('Event dropped - consent required but not granted', category: LogCategory.events);
      return;
    }

    final propertiesInfo = properties.isNotEmpty ? ': ${properties.keys.take(3).join(", ")}' : '';
    SDKLogger.debug('Tracked event "${eventName.value}"$propertiesInfo', category: LogCategory.events);

    // If ready, process immediately
    if (_isReady) {
      _ensureSessionStarted();
      _incrementSessionEventCount();
      _client?.event(
        userID: _effectiveUserId,
        eventName: eventName,
        properties: properties,
      );
    } else {
      // Queue the event for later processing
      _eventQueue.enqueue(
        QueuedEvent.track(eventName: eventName, properties: properties),
        _maxQueueSize,
      );
    }
  }

  // MARK: - Revenue Tracking

  /// Track a revenue event
  /// Matches Swift SDK: eventRevenue(amount:currency:orderID:properties:)
  static void eventRevenue({
    required double amount,
    required Currency currency,
    required String orderId,
    Properties properties = Properties.empty,
  }) {
    _instance._eventRevenue(amount, currency, orderId, properties);
  }

  /// Track revenue with dictionary properties (convenience)
  static void eventRevenueWithMap({
    required double amount,
    required Currency currency,
    required String orderId,
    required Map<String, Object?> properties,
  }) {
    _instance._eventRevenue(amount, currency, orderId, Properties.fromMap(properties));
  }

  /// Internal revenue tracking
  void _eventRevenue(double amount, Currency currency, String orderId, Properties properties) {
    if (_isOptedOut) {
      _logDebug('Revenue event dropped - user opted out');
      return;
    }

    if (_requiresConsentAndNotGranted()) {
      _logDebug('Revenue event dropped - consent required but not granted');
      return;
    }

    final propertiesInfo = properties.isNotEmpty ? ': $properties' : '';
    _logDebug('Tracked revenue $amount ${currency.code} for order "$orderId"$propertiesInfo');

    // If ready, process immediately
    if (_isReady) {
      _ensureSessionStarted();
      _incrementSessionEventCount();
      _client?.eventRevenue(
        userID: _effectiveUserId,
        orderID: orderId,
        amount: amount,
        currency: currency,
        properties: properties,
      );
    } else {
      // Queue the event for later processing
      _eventQueue.enqueue(
        QueuedEvent.revenue(
          userId: _effectiveUserId,
          orderId: orderId,
          amount: amount,
          currency: currency,
          properties: properties,
        ),
        _maxQueueSize,
      );
    }
  }

  // MARK: - User Management

  /// Identify the current user
  /// Matches Swift SDK: identify(_ userID: String, traits: Properties = Properties())
  static void identify(String userId, {Properties traits = Properties.empty}) {
    _instance._identify(userId, traits);
  }

  /// Identify user with dictionary traits (convenience)
  /// Matches Swift SDK: identify(_ userID: String, traits: [String: Any])
  static void identifyWithMap(String userId, Map<String, Object?> traits) {
    _instance._identify(userId, Properties.fromMap(traits));
  }

  /// Internal identify method
  void _identify(String userId, Properties traits) {
    if (_isOptedOut) {
      SDKLogger.debug('Identify event dropped - user opted out', category: LogCategory.events);
      return;
    }

    if (_requiresConsentAndNotGranted()) {
      SDKLogger.debug('Identify event dropped - consent required but not granted', category: LogCategory.events);
      return;
    }

    if (userId.isEmpty) {
      SDKLogger.error('Empty user ID provided for identify', category: LogCategory.events);
      _handleError(const InvalidUserIdError('User ID cannot be empty'));
      return;
    }

    final traitsInfo = traits.isNotEmpty ? ': ${traits.keys.take(3).join(", ")}' : '';
    SDKLogger.debug('Identified user "$userId"$traitsInfo', category: LogCategory.events);

    _currentUserId = userId;
    _currentUserTraits = UserTraits.fromMap({'user_id': userId, ...traits.toMap()});

    // If ready, process immediately
    if (_isReady) {
      _ensureSessionStarted();
      _incrementSessionEventCount();
      _client?.eventIdentify(userID: userId, traits: traits);
    } else {
      // Queue the event for later processing
      _eventQueue.enqueue(
        QueuedEvent.identify(userId: userId, traits: traits),
        _maxQueueSize,
      );
    }
  }

  /// Reset user session (logout)
  /// Matches Swift SDK: reset()
  static void reset() {
    _instance._reset();
  }

  /// Internal reset method
  void _reset() {
    _currentUserId = null;
    _currentUserTraits = null;
    _anonymousId = _generateAnonymousId();
    _saveAnonymousId(_anonymousId!);
    _sessionStarted = false;
    _deviceContextSent = false;
    _sessionStartTime = null;
    _sessionId = null;
    _sessionEventCount = 0;

    // Reset opt-out state to default
    _isOptedOut = _config?.defaultOptOut ?? false;
    _saveOptOutState(_isOptedOut);

    _logDebug('User session reset');
  }

  /// Associate user with a group
  /// Matches Swift SDK: group(_ groupID: String, properties: Properties = Properties())
  static void group(String groupId, {Properties properties = Properties.empty}) {
    _instance._group(groupId, properties);
  }

  /// Associate user with group using dictionary properties (convenience)
  /// Matches Swift SDK: group(_ groupID: String, properties: [String: Any])
  static void groupWithMap(String groupId, Map<String, Object?> properties) {
    _instance._group(groupId, Properties.fromMap(properties));
  }

  /// Internal group method
  void _group(String groupId, Properties properties) {
    if (_isOptedOut) {
      _logDebug('Group event dropped - user opted out');
      return;
    }

    if (_requiresConsentAndNotGranted()) {
      _logDebug('Group event dropped - consent required but not granted');
      return;
    }

    if (groupId.isEmpty) {
      SDKLogger.error('Empty group ID provided', category: LogCategory.events);
      _handleError(const InvalidEventError('Group ID cannot be empty'));
      return;
    }

    final propertiesInfo = properties.isNotEmpty ? ': $properties' : '';
    _logDebug('Associated user with group "$groupId"$propertiesInfo');

    // If ready, process immediately
    if (_isReady) {
      _ensureSessionStarted();
      _incrementSessionEventCount();
      _client?.eventGroup(
        userID: _effectiveUserId,
        groupID: groupId,
        properties: properties,
      );
    } else {
      // Queue the event for later processing
      _eventQueue.enqueue(
        QueuedEvent.group(groupId: groupId, properties: properties),
        _maxQueueSize,
      );
    }
  }

  /// Alias user (identity resolution) - connects previous ID to new user ID
  /// Matches Swift SDK: alias(_ previousId: String, _ userId: String)
  static void alias(String previousId, String userId) {
    _instance._alias(previousId, userId);
  }

  /// Internal alias method
  void _alias(String previousId, String userId) {
    if (_isOptedOut) {
      _logDebug('Alias event dropped - user opted out');
      return;
    }

    if (_requiresConsentAndNotGranted()) {
      _logDebug('Alias event dropped - consent required but not granted');
      return;
    }

    if (previousId.isEmpty || userId.isEmpty) {
      SDKLogger.error('Empty user IDs provided for alias', category: LogCategory.events);
      _handleError(const InvalidEventError('User IDs cannot be empty'));
      return;
    }

    final propertiesInfo = '';
    _logDebug('Aliased user "$previousId" to "$userId"$propertiesInfo');

    // Update current user ID if aliasing from current user
    if (_currentUserId == previousId) {
      _currentUserId = userId;
    }

    // If ready, process immediately
    if (_isReady) {
      _ensureSessionStarted();
      _incrementSessionEventCount();
      _client?.eventAlias(previousId: previousId, userId: userId);
    } else {
      // Queue the alias for later processing
      _eventQueue.enqueue(
        QueuedEvent.alias(previousId: previousId, userId: userId),
        _maxQueueSize,
      );
    }
  }

  // MARK: - Structured Logging

  /// Log a message with specified level
  /// Matches Swift SDK: log(_ level: LogLevel, _ message: String, service: String = "app", data: Properties = Properties())
  static void log(
    LogLevel level,
    String message, {
    String service = 'app',
    Properties data = Properties.empty,
  }) {
    _instance._log(level, message, service, data);
  }



  /// Log message with dictionary data (convenience)
  /// Matches Swift SDK: log(_ level: LogLevel, _ message: String, service: String = "app", data: [String: Any])
  static void logWithMap(
    LogLevel level,
    String message, {
    String service = 'app',
    required Map<String, Object?> data,
  }) {
    _instance._log(level, message, service, Properties.fromMap(data));
  }

  // Convenience logging methods (match Swift SDK)
  static void logInfo(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.info, message, service, data);
  }

  static void logError(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.error, message, service, data);
  }

  static void logDebug(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.debug, message, service, data);
  }

  static void logWarning(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.warning, message, service, data);
  }

  static void logCritical(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.critical, message, service, data);
  }

  static void logAlert(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.alert, message, service, data);
  }

  static void logEmergency(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.emergency, message, service, data);
  }

  static void logNotice(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.notice, message, service, data);
  }

  static void logTrace(String message, {String service = 'app', Properties data = Properties.empty}) {
    _instance._log(LogLevel.trace, message, service, data);
  }

  /// Internal log method
  void _log(LogLevel level, String message, String service, Properties data) {
    // Logs are for error reporting and debugging - they are NOT subject to privacy controls
    final dataInfo = data.isNotEmpty ? ': $data' : '';
    _logDebug('Log $level: $message [service: $service]$dataInfo');

    if (!_isReady) {
      return; // Don't queue logs
    }

    try {
      final logEntry = LogEntryModel(
        level: level,
        message: message,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        source: 'flutter-app', // TODO: Phase 7 - Get from device context
        service: service,
        contextId: _anonymousId?.hashCode,
        data: data,
      );

      logEntry.validate();

      // Phase 2 - Send to client
      switch (level) {
        case LogLevel.info:
          _client?.logInfo(service, message, data: data);
          break;
        case LogLevel.error:
          _client?.logError(service, message, data: data);
          break;
        case LogLevel.debug:
          _client?.logDebug(service, message, data: data);
          break;
        case LogLevel.warning:
          _client?.logWarning(service, message, data: data);
          break;
        case LogLevel.critical:
          _client?.logCritical(service, message, data: data);
          break;
        case LogLevel.alert:
          _client?.logAlert(service, message, data: data);
          break;
        case LogLevel.emergency:
          _client?.logEmergency(service, message, data: data);
          break;
        case LogLevel.notice:
          _client?.logNotice(service, message, data: data);
          break;
        case LogLevel.trace:
          _client?.logTrace(service, message, data: data);
          break;
      }

      SDKLogger.trace('Log entry sent: ${level.label} - $message', category: LogCategory.events);
    } catch (e) {
      _handleError(ErrorUtils.fromException(e));
    }
  }

  // MARK: - Privacy Controls

  /// Opt user out of data collection
  static void optOut() {
    _instance._setOptOut(true);
  }

  /// Opt user in to data collection
  static void optIn() {
    _instance._setOptOut(false);
  }

  /// Check if user is opted out
  static bool isOptedOut() {
    return _instance._isOptedOut;
  }

  /// Clear all local user data (GDPR compliance)
  /// This removes all stored user information and resets to anonymous state
  static void clearUserData() {
    _instance._clearUserData();
  }

  /// Delete all stored events and logs
  /// This clears the local queue but doesn't affect server-side data
  static void clearLocalData() {
    _instance._clearLocalData();
  }

  /// Export user data for GDPR compliance
  /// Returns a map of all user data that would be sent to servers
  static Map<String, dynamic> exportUserData() {
    return _instance._exportUserData();
  }

  /// Check if explicit consent is required
  static bool get requiresConsent => _instance._config?.privacyConfig.requireExplicitConsent ?? false;

  /// Grant explicit consent for data collection
  static void grantConsent() {
    _instance._grantConsent();
  }

  /// Revoke consent and opt out
  static void revokeConsent() {
    _instance._revokeConsent();
  }

  /// Check if consent has been granted
  static bool get hasConsent => _instance._hasConsent;

  /// Internal opt-out method
  void _setOptOut(bool optOut) {
    _isOptedOut = optOut;
    _saveOptOutState(optOut);

    if (optOut) {
      SDKLogger.info('User opted out of data collection', category: LogCategory.client);
      // Clear local data when opting out
      _clearLocalData();
      _endSession();
    } else {
      SDKLogger.info('User opted in to data collection', category: LogCategory.client);
    }
  }

  // MARK: - Lifecycle Management

  /// Manually flush pending events and logs
  static Future<void> flush() async {
    await _instance._flush();
  }

  /// Internal flush method
  Future<void> _flush() async {
    if (!_isReady) {
      SDKLogger.warning('Flush requested but SDK not ready', category: LogCategory.client);
      return;
    }

    try {
      SDKLogger.debug('Flushing pending events and logs', category: LogCategory.client);
      await _client?.flush();
      SDKLogger.debug('Flush completed successfully', category: LogCategory.client);
    } catch (e) {
      SDKLogger.error('Flush failed', error: e, category: LogCategory.client);
      _handleError(ErrorUtils.fromException(e));
    }
  }

  /// End current session manually
  static void endSession() {
    SDKLogger.debug('Ending session manually', category: LogCategory.client);
    _instance._endSession();
  }

  /// Shutdown the SDK gracefully
  static Future<void> shutdown() async {
    SDKLogger.info('SDK shutdown initiated', category: LogCategory.client);
    await _instance._shutdown();
  }

  /// Internal shutdown method
  Future<void> _shutdown() async {
    if (_initializationState == InitializationState.notStarted) return;

    try {
      // Cancel device context timer
      _deviceContextTimer?.cancel();
      _deviceContextTimer = null;

      // Dispose device context
      if (_config?.collectDeviceContext == true) {
        DeviceContext.instance.dispose();
      }

      // End current session
      _endSession();

      // Flush pending data
      await _flush();

      // Phase 2 - Close network connections
      await _client?.close();

      SDKLogger.info('UserCanal SDK shutdown completed', category: LogCategory.client);
    } catch (e) {
      _handleError(ErrorUtils.fromException(e));
    } finally {
      _initializationState = InitializationState.notStarted;
      _config = null;
      _apiKey = null;
      _currentUserId = null;
      _currentUserTraits = null;
      _errorCallback = null;
      _sessionStarted = false;
      _sessionStartTime = null;
      _sessionId = null;
      _sessionEventCount = 0;
    }
  }

  // MARK: - Getters

  /// Check if SDK is initialized
  static bool get isInitialized => _instance._initializationState == InitializationState.ready;

  /// Check if SDK is configured (alias for isInitialized)
  static bool get isConfigured => isInitialized;

  /// Get queued event count
  static int get queuedEventCount => _instance._eventQueue.length;



  /// Get current configuration
  static UserCanalConfig? get config => _instance._config;

  /// Get current user ID
  static String? get currentUserId => _instance._currentUserId;

  /// Get current anonymous ID
  static String? get anonymousId => _instance._anonymousId;

  /// Get current effective user ID
  static String get effectiveUserId => _instance._effectiveUserId;

  /// Get current user traits
  static UserTraits? get currentUserTraits => _instance._currentUserTraits;

  /// Get current session ID
  static String? get currentSessionId => _instance._sessionId;

  /// Get session event count
  static int get sessionEventCount => _instance._sessionEventCount;

  /// Check if session is active
  static bool get isSessionActive => _instance._sessionStarted;

  /// Check if device is online
  static bool get isOnline => _instance._isOnline;

  // MARK: - Private Helper Methods

  void _ensureSessionStarted() {
    if (!_sessionStarted && _config?.enableSessionTracking == true) {
      _sessionStarted = true;
      _sessionStartTime = DateTime.now();
      _sessionId = _generateSessionId();
      _sessionEventCount = 0;

      // Send session started event
      _client?.event(
        userID: _effectiveUserId,
        eventName: EventName.sessionStarted,
        properties: Properties.fromMap({
          'session_id': _sessionId!,
          'started_at': _sessionStartTime!.millisecondsSinceEpoch,
          'user_id': _currentUserId,
          'anonymous_id': _anonymousId,
        }),
      );

      // Send device context enrichment once per session
      if (_config?.collectDeviceContext == true) {
        _sendDeviceContextIfNeeded();
        SDKLogger.debug('Session started for user: ${getCurrentUserId()}', category: LogCategory.events);
      }
    }
  }

  void _incrementSessionEventCount() {
    if (_sessionStarted) {
      _sessionEventCount++;
    }
  }

  String _generateSessionId() {
    return const Uuid().v4();
  }

  void _endSession() {
    if (_sessionStarted && _config?.enableSessionTracking == true) {
      final sessionDuration = _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inMilliseconds
          : 0;

      // Send session ended event
      _client?.event(
        userID: _effectiveUserId,
        eventName: EventName.sessionEnded,
        properties: Properties.fromMap({
          'session_id': _sessionId!,
          'ended_at': DateTime.now().millisecondsSinceEpoch,
          'duration_ms': sessionDuration,
          'event_count': _sessionEventCount,
          'user_id': _currentUserId,
          'anonymous_id': _anonymousId,
        }),
      );

      _logDebug('Session ended: $_sessionId (duration: ${sessionDuration}ms, events: $_sessionEventCount)');

      _sessionStarted = false;
      _sessionStartTime = null;
      _sessionId = null;
      _sessionEventCount = 0;
    }
  }

  void _checkSessionTimeout() {
    if (_sessionStarted &&
        _sessionStartTime != null &&
        _config?.sessionTimeout != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!);
      if (elapsed > _config!.sessionTimeout) {
        _endSession();
      }
    }
  }

  String _getOrCreateAnonymousId() {
    // TODO: Phase 5 - Load from persistent storage
    return _generateAnonymousId();
  }

  String _generateAnonymousId() {
    return const Uuid().v4();
  }

  void _saveAnonymousId(String anonymousId) {
    // TODO: Phase 5 - Save to persistent storage
  }

  void _initializeOptOutState() {
    // Load saved opt-out state from persistent storage
    getPrivacyDataManager().loadOptOutState().then((savedState) {
      if (savedState != null) {
        _isOptedOut = savedState;
      } else {
        _isOptedOut = _config?.defaultOptOut ?? false;
        _saveOptOutState(_isOptedOut);
      }

      final status = _isOptedOut ? 'opted out' : 'opted in';
      _logDebug('User is $status for data collection');
    }).catchError((e) {
      _logDebug('Failed to load opt-out state: $e');
      _isOptedOut = _config?.defaultOptOut ?? false;
    });
  }

  void _saveOptOutState(bool optOut) {
    // Save opt-out state to persistent storage
    getPrivacyDataManager().saveOptOutState(optOut).then((_) {
      _logDebug('Opt-out state saved: $optOut');
    }).catchError((e) {
      _logDebug('Failed to save opt-out state: $e');
    });
  }

  // MARK: - Privacy and Data Management

  void _clearUserData() {
    _currentUserId = null;
    _currentUserTraits = null;
    _anonymousId = _generateAnonymousId();
    _saveAnonymousId(_anonymousId!);
    _endSession();
    _clearLocalData();

    // Reset consent state
    _hasConsent = false;
    _saveConsentState(false);

    _logDebug('All user data cleared');
  }

  void _clearLocalData() {
    _eventQueue.clear();
    _logDebug('Local data cleared');
  }

  Map<String, dynamic> _exportUserData() {
    return {
      'user_id': _currentUserId,
      'anonymous_id': _anonymousId,
      'user_traits': _currentUserTraits?.toMap(),
      'session_id': _sessionId,
      'session_event_count': _sessionEventCount,
      'session_started_at': _sessionStartTime?.millisecondsSinceEpoch,
      'is_opted_out': _isOptedOut,
      'has_consent': _hasConsent,
      'queued_events_count': _eventQueue.length,
      'sdk_version': SDKInfo.version,
      'configuration': {
        'endpoint': _config?.endpoint,
        'enable_session_tracking': _config?.enableSessionTracking,
        'default_opt_out': _config?.defaultOptOut,
        'privacy_config': {
          'require_explicit_consent': _config?.privacyConfig.requireExplicitConsent,
          'minimize_data_collection': _config?.privacyConfig.minimizeDataCollection,
          'data_retention_days': _config?.privacyConfig.dataRetentionDays,
        }
      }
    };
  }

  void _grantConsent() {
    _hasConsent = true;
    _saveConsentState(true);
    _logDebug('User consent granted');

    // If user was opted out due to lack of consent, opt them back in
    if (_isOptedOut && _config?.privacyConfig.requireExplicitConsent == true) {
      _setOptOut(false);
    }
  }

  void _revokeConsent() {
    _hasConsent = false;
    _saveConsentState(false);
    _clearUserData();
    _setOptOut(true);
    _logDebug('User consent revoked');
  }

  bool _requiresConsentAndNotGranted() {
    return _config?.privacyConfig.requireExplicitConsent == true && !_hasConsent;
  }

  void _saveConsentState(bool hasConsent) {
    getPrivacyDataManager().saveConsentState(hasConsent).then((_) {
      _logDebug('Consent state saved: $hasConsent');
    }).catchError((e) {
      _logDebug('Failed to save consent state: $e');
    });
  }

  void _initializeConsentState() {
    getPrivacyDataManager().loadConsentState().then((savedConsent) {
      if (savedConsent != null) {
        _hasConsent = savedConsent;
      } else {
        // Default consent state based on privacy configuration
        _hasConsent = !(_config?.privacyConfig.requireExplicitConsent ?? false);
        _saveConsentState(_hasConsent);
      }

      _logDebug('Consent state initialized: $_hasConsent');
    }).catchError((e) {
      _logDebug('Failed to load consent state: $e');
      _hasConsent = !(_config?.privacyConfig.requireExplicitConsent ?? false);
    });
  }

  Future<void> _processQueuedEvents() async {
    if (_eventQueue.isEmpty) return;

    final events = _eventQueue.dequeueAll();
    for (final event in events) {
      await _processEventImmediate(event);
    }
  }

  Future<void> _processEventImmediate(QueuedEvent event) async {
    if (_client == null) return;

    try {
      switch (event.type) {
        case QueuedEventType.track:
          if (event.eventName != null && event.properties != null) {
            await _client!.event(
              userID: _effectiveUserId,
              eventName: event.eventName!,
              properties: event.properties!,
            );
          }
          break;
        case QueuedEventType.identify:
          if (event.userId != null && event.traits != null) {
            await _client!.eventIdentify(
              userID: event.userId!,
              traits: event.traits!,
            );
          }
          break;
        case QueuedEventType.group:
          if (event.groupId != null && event.properties != null) {
            await _client!.eventGroup(
              userID: _effectiveUserId,
              groupID: event.groupId!,
              properties: event.properties!,
            );
          }
          break;
        case QueuedEventType.alias:
          if (event.previousId != null && event.userId != null) {
            await _client!.eventAlias(
              previousId: event.previousId!,
              userId: event.userId!,
            );
          }
          break;
        case QueuedEventType.revenue:
          if (event.userId != null && event.orderId != null &&
              event.amount != null && event.currency != null &&
              event.properties != null) {
            await _client!.eventRevenue(
              userID: event.userId!,
              orderID: event.orderId!,
              amount: event.amount!,
              currency: event.currency!,
              properties: event.properties!,
            );
          }
          break;
        case QueuedEventType.enrich:
          if (event.eventName != null && event.properties != null) {
            await _client!.enrichEvent(
              userID: event.userId ?? _effectiveUserId,
              eventName: event.eventName!,
              properties: event.properties!,
            );
          }
          break;
      }
    } catch (e) {
      _handleError(ErrorUtils.fromException(e));
    }
  }

  void _handleError(UserCanalError error) {
    SDKLogger.error('SDK error [${error.code}]: ${error.message}', category: LogCategory.error);
    _errorCallback?.call(error);
  }

  void _logDebug(String message) {
    SDKLogger.debug(message, category: LogCategory.general);
  }

  /// Convert SystemLogLevel to SDKLogLevel
  static SDKLogLevel _convertToSDKLogLevel(SystemLogLevel level) {
    switch (level) {
      case SystemLogLevel.emergency:
        return SDKLogLevel.emergency;
      case SystemLogLevel.alert:
        return SDKLogLevel.alert;
      case SystemLogLevel.critical:
        return SDKLogLevel.critical;
      case SystemLogLevel.error:
        return SDKLogLevel.error;
      case SystemLogLevel.warning:
        return SDKLogLevel.warning;
      case SystemLogLevel.notice:
        return SDKLogLevel.notice;
      case SystemLogLevel.info:
        return SDKLogLevel.info;
      case SystemLogLevel.debug:
        return SDKLogLevel.debug;
      case SystemLogLevel.trace:
        return SDKLogLevel.trace;
    }
  }

  // MARK: - Device Context Management

  /// Send device context enrichment if needed
  void _sendDeviceContextIfNeeded() {
    final now = DateTime.now();

    // Send if never sent, or if 24+ hours since last send
    final shouldSend = !_deviceContextSent ||
        (_lastDeviceContextTime != null &&
            now.difference(_lastDeviceContextTime!).inHours >= 24);

    if (!shouldSend) {
      SDKLogger.trace('Device context already sent recently', category: LogCategory.device);
      return;
    }

    _deviceContextSent = true;
    _lastDeviceContextTime = now;

    // Send device context as enrichment event asynchronously
    Future(() async {
      try {
        final deviceContext = DeviceContext.instance;
        final contextData = await deviceContext.getContext();

        if (contextData.isNotEmpty) {
          // Create device context enrichment event
          final enrichmentEvent = Event(
            userId: getCurrentUserId(),
            name: EventName.custom('device_context_enrichment'),
            eventType: EventType.enrich,
            properties: Properties.fromMap(contextData),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            eventId: _config?.generateEventIds == true ? _generateEventId() : null,
          );

          // Send as enrichment (internal method)
          await _enrich(enrichmentEvent);

          SDKLogger.debug('Device context enrichment sent', category: LogCategory.device);
        }
      } catch (e) {
        SDKLogger.error('Failed to send device context enrichment', error: e, category: LogCategory.device);
        // Reset flags to retry next time
        _deviceContextSent = false;
        _lastDeviceContextTime = null;
      }
    });
  }

  /// Start device context refresh timer (24 hour intervals)
  void _startDeviceContextTimer() {
    _deviceContextTimer?.cancel();

    _deviceContextTimer = Timer.periodic(const Duration(hours: 24), (_) {
      if (_config?.collectDeviceContext == true) {
        SDKLogger.debug('Device context timer triggered', category: LogCategory.device);
        _sendDeviceContextIfNeeded();
      }
    });

    SDKLogger.debug('Device context refresh timer started (24h interval)', category: LogCategory.device);
  }

  /// Internal enrichment method (similar to Swift SDK)
  Future<void> _enrich(Event event) async {
    if (_isOptedOut) {
      SDKLogger.debug('Enrichment dropped - user opted out', category: LogCategory.events);
      return;
    }

    if (_requiresConsentAndNotGranted()) {
      SDKLogger.debug('Enrichment dropped - consent required but not granted', category: LogCategory.events);
      return;
    }

    final propertiesInfo = event.properties.isNotEmpty ? ': ${event.properties.keys.take(3).join(", ")}' : '';
    SDKLogger.debug('Enriched with ${event.name.value.replaceAll("_", " ")}$propertiesInfo', category: LogCategory.events);
    SDKLogger.trace('Enrich event: ${event.name.value}', category: LogCategory.events);

    // If ready, process immediately
    if (_isReady) {
      try {
        await _client?.enrichEvent(
          userID: event.userId,
          eventName: event.name,
          properties: event.properties,
        );
      } catch (e) {
        _handleError(ErrorUtils.fromException(e));
      }
    } else {
      // Queue the enrichment for later processing
      _eventQueue.enqueue(
        QueuedEvent.enrich(
          eventName: event.name,
          properties: event.properties,
          userId: event.userId,
        ),
        _maxQueueSize,
      );
      SDKLogger.trace('Queueing enrichment event', category: LogCategory.events);
    }
  }

  // MARK: - Static Utility Methods

  /// Get SDK version information
  static String get version => SDKInfo.version;

  /// Get SDK name
  static String get name => SDKInfo.name;

  /// Get user agent string
  static String get userAgent => SDKInfo.userAgent;

  /// Create a configuration builder
  static UserCanalConfigBuilder configBuilder() => UserCanalConfigBuilder();

  /// Create an event builder
  static EventBuilder eventBuilder() => EventBuilder();

  /// Create a log entry builder
  static LogEntryBuilder logBuilder() => LogEntryBuilder();

  /// Create a revenue builder
  static RevenueBuilder revenueBuilder() => RevenueBuilder();

  /// Create a user traits builder
  static UserTraitsBuilder traitsBuilder() => UserTraitsBuilder();

  /// Create a properties builder
  static PropertiesBuilder propertiesBuilder() => PropertiesBuilder();
}

// MARK: - Event Queue

/// Event queue for storing events before SDK initialization
class EventQueue {
  final List<QueuedEvent> _events = [];

  bool get isEmpty => _events.isEmpty;
  int get length => _events.length;

  void enqueue(QueuedEvent event, int maxSize) {
    if (_events.length >= maxSize) {
      _events.removeAt(0); // Remove oldest event
    }
    _events.add(event);
  }

  List<QueuedEvent> dequeueAll() {
    final events = List<QueuedEvent>.from(_events);
    _events.clear();
    return events;
  }

  void clear() {
    _events.clear();
  }
}

/// Queued event types
enum QueuedEventType {
  track,
  identify,
  group,
  alias,
  revenue,
  enrich,
}

/// Queued event for pre-initialization storage
@immutable
class QueuedEvent {
  const QueuedEvent._({
    required this.type,
    this.eventName,
    this.properties,
    this.userId,
    this.traits,
    this.groupId,
    this.previousId,
    this.orderId,
    this.amount,
    this.currency,
  });

  final QueuedEventType type;
  final EventName? eventName;
  final Properties? properties;
  final String? userId;
  final Properties? traits;
  final String? groupId;
  final String? previousId;
  final String? orderId;
  final double? amount;
  final Currency? currency;

  factory QueuedEvent.track({
    required EventName eventName,
    required Properties properties,
  }) {
    return QueuedEvent._(
      type: QueuedEventType.track,
      eventName: eventName,
      properties: properties,
    );
  }

  factory QueuedEvent.identify({
    required String userId,
    required Properties traits,
  }) {
    return QueuedEvent._(
      type: QueuedEventType.identify,
      userId: userId,
      traits: traits,
    );
  }

  factory QueuedEvent.group({
    required String groupId,
    required Properties properties,
  }) {
    return QueuedEvent._(
      type: QueuedEventType.group,
      groupId: groupId,
      properties: properties,
    );
  }

  factory QueuedEvent.alias({
    required String previousId,
    required String userId,
  }) {
    return QueuedEvent._(
      type: QueuedEventType.alias,
      previousId: previousId,
      userId: userId,
    );
  }

  factory QueuedEvent.revenue({
    required String userId,
    required String orderId,
    required double amount,
    required Currency currency,
    required Properties properties,
  }) {
    return QueuedEvent._(
      type: QueuedEventType.revenue,
      userId: userId,
      orderId: orderId,
      amount: amount,
      currency: currency,
      properties: properties,
    );
  }

  factory QueuedEvent.enrich({
    required EventName eventName,
    required Properties properties,
    String? userId,
  }) {
    return QueuedEvent._(
      type: QueuedEventType.enrich,
      eventName: eventName,
      properties: properties,
      userId: userId,
    );
  }
}

/// Helper for unawaited futures
void unawaited(Future<void> future) {
  // Intentionally ignore the future
}
