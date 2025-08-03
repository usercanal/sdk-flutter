// Copyright © 2024 UserCanal. All rights reserved.

/// Configuration system for UserCanal Flutter SDK
///
/// This module provides comprehensive configuration management for the SDK,
/// including network settings, behavior options, performance tuning, and
/// privacy controls.

import 'package:meta/meta.dart';
import '../errors/user_canal_error.dart';

/// Main configuration class for UserCanal SDK
@immutable
class UserCanalConfig {
  /// Creates a new UserCanal configuration
  UserCanalConfig({
    required this.apiKey,
    this.endpoint = _Defaults.endpoint,
    this.port = _Defaults.port,
    this.batchSize = _Defaults.batchSize,
    this.flushInterval = _Defaults.flushInterval,
    this.maxRetries = _Defaults.maxRetries,
    this.maxRetryAttempts = _Defaults.maxRetryAttempts,
    this.retryBaseDelay = _Defaults.retryBaseDelay,
    this.retryMaxDelay = _Defaults.retryMaxDelay,
    this.connectionTimeout = _Defaults.connectionTimeout,
    this.networkTimeout = _Defaults.networkTimeout,
    this.closeTimeout = _Defaults.closeTimeout,
    this.enableAutoReconnect = _Defaults.enableAutoReconnect,
    this.enableDebugLogging = _Defaults.enableDebugLogging,
    this.logLevel = _Defaults.logLevel,
    this.collectDeviceContext = _Defaults.collectDeviceContext,
    this.enableOfflineStorage = _Defaults.enableOfflineStorage,
    this.maxOfflineEvents = _Defaults.maxOfflineEvents,
    this.deviceContextRefresh = _Defaults.deviceContextRefresh,
    this.defaultOptOut = _Defaults.defaultOptOut,
    this.generateEventIds = _Defaults.generateEventIds,
    this.enableSessionTracking = _Defaults.enableSessionTracking,
    this.sessionTimeout = _Defaults.sessionTimeout,
    this.maxBatchBytes = _Defaults.maxBatchBytes,
    this.compressionEnabled = _Defaults.compressionEnabled,
    this.networkConfig = const NetworkConfig(),
    this.performanceConfig = const PerformanceConfig(),
    this.privacyConfig = const PrivacyConfig(),
  }) {
    validate();
  }

  // MARK: - Core Configuration

  /// API key for authentication (required)
  final String apiKey;

  /// Server endpoint for data collection
  final String endpoint;

  /// Server port for TCP connection
  final int port;

  // MARK: - Batching Configuration

  /// Maximum number of events per batch
  final int batchSize;

  /// Time interval between automatic batch flushes
  final Duration flushInterval;

  /// Maximum size of a batch in bytes
  final int maxBatchBytes;

  /// Whether to enable compression for batch data
  final bool compressionEnabled;

  // MARK: - Network Configuration

  /// Maximum number of retries for failed requests
  final int maxRetries;

  /// Maximum number of retry attempts for batches
  final int maxRetryAttempts;

  /// Base delay for exponential backoff
  final Duration retryBaseDelay;

  /// Maximum delay for exponential backoff
  final Duration retryMaxDelay;

  /// Connection timeout for TCP connections
  final Duration connectionTimeout;

  /// Timeout for network operations
  final Duration networkTimeout;

  /// Timeout for graceful client shutdown
  final Duration closeTimeout;

  /// Whether to enable automatic reconnection
  final bool enableAutoReconnect;

  /// Network-specific configuration
  final NetworkConfig networkConfig;

  // MARK: - Behavior Configuration

  /// Whether to enable debug logging
  final bool enableDebugLogging;

  /// Log level for SDK internal logging
  final SystemLogLevel logLevel;

  /// Whether to collect device context automatically
  final bool collectDeviceContext;

  /// Device context refresh interval
  final Duration deviceContextRefresh;

  // MARK: - Storage Configuration

  /// Whether to persist events locally when offline
  final bool enableOfflineStorage;

  /// Maximum number of events to store offline
  final int maxOfflineEvents;

  // MARK: - Privacy Configuration

  /// Whether users are opted out by default
  final bool defaultOptOut;

  /// Privacy-specific configuration
  final PrivacyConfig privacyConfig;

  // MARK: - Event Configuration

  /// Whether to generate client-side event IDs
  final bool generateEventIds;

  /// Whether to enable automatic session tracking
  final bool enableSessionTracking;

  /// Session timeout duration
  final Duration sessionTimeout;

  // MARK: - Performance Configuration

  /// Performance tuning configuration
  final PerformanceConfig performanceConfig;

  // MARK: - Validation

  /// Validates the configuration and throws if invalid
  void validate() {
    if (apiKey.isEmpty) {
      throw const InvalidApiKeyError('API key cannot be empty');
    }

    if (apiKey.length != 32) {
      throw const InvalidApiKeyError('API key must be 32 characters long');
    }

    if (!_isValidEndpoint(endpoint)) {
      throw InvalidEndpointError(endpoint);
    }

    if (batchSize <= 0 || batchSize > 10000) {
      throw const InvalidConfigurationError(
        'batchSize',
        'must be between 1 and 10000',
      );
    }

    if (flushInterval.inSeconds <= 0 || flushInterval.inSeconds > 3600) {
      throw const InvalidConfigurationError(
        'flushInterval',
        'must be between 1 second and 1 hour',
      );
    }

    if (maxRetries < 0 || maxRetries > 10) {
      throw const InvalidConfigurationError(
        'maxRetries',
        'must be between 0 and 10',
      );
    }

    if (networkTimeout.inSeconds <= 0 || networkTimeout.inSeconds > 300) {
      throw const InvalidConfigurationError(
        'networkTimeout',
        'must be between 1 second and 5 minutes',
      );
    }

    if (maxOfflineEvents < 0 || maxOfflineEvents > 100000) {
      throw const InvalidConfigurationError(
        'maxOfflineEvents',
        'must be between 0 and 100000',
      );
    }

    if (maxBatchBytes <= 0 || maxBatchBytes > 100 * 1024 * 1024) {
      throw const InvalidConfigurationError(
        'maxBatchBytes',
        'must be between 1 byte and 100MB',
      );
    }

    if (sessionTimeout.inMinutes <= 0 || sessionTimeout.inHours > 24) {
      throw const InvalidConfigurationError(
        'sessionTimeout',
        'must be between 1 minute and 24 hours',
      );
    }
  }

  /// Creates a copy of this configuration with updated values
  UserCanalConfig copyWith({
    String? apiKey,
    String? endpoint,
    int? port,
    int? batchSize,
    Duration? flushInterval,
    int? maxRetries,
    int? maxRetryAttempts,
    Duration? retryBaseDelay,
    Duration? retryMaxDelay,
    Duration? connectionTimeout,
    Duration? networkTimeout,
    Duration? closeTimeout,
    bool? enableAutoReconnect,
    bool? enableDebugLogging,
    SystemLogLevel? logLevel,
    bool? collectDeviceContext,
    bool? enableOfflineStorage,
    int? maxOfflineEvents,
    Duration? deviceContextRefresh,
    bool? defaultOptOut,
    bool? generateEventIds,
    bool? enableSessionTracking,
    Duration? sessionTimeout,
    int? maxBatchBytes,
    bool? compressionEnabled,
    NetworkConfig? networkConfig,
    PerformanceConfig? performanceConfig,
    PrivacyConfig? privacyConfig,
  }) {
    return UserCanalConfig(
      apiKey: apiKey ?? this.apiKey,
      endpoint: endpoint ?? this.endpoint,
      port: port ?? this.port,
      batchSize: batchSize ?? this.batchSize,
      flushInterval: flushInterval ?? this.flushInterval,
      maxRetries: maxRetries ?? this.maxRetries,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      retryBaseDelay: retryBaseDelay ?? this.retryBaseDelay,
      retryMaxDelay: retryMaxDelay ?? this.retryMaxDelay,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      networkTimeout: networkTimeout ?? this.networkTimeout,
      closeTimeout: closeTimeout ?? this.closeTimeout,
      enableAutoReconnect: enableAutoReconnect ?? this.enableAutoReconnect,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      logLevel: logLevel ?? this.logLevel,
      collectDeviceContext: collectDeviceContext ?? this.collectDeviceContext,
      enableOfflineStorage: enableOfflineStorage ?? this.enableOfflineStorage,
      maxOfflineEvents: maxOfflineEvents ?? this.maxOfflineEvents,
      deviceContextRefresh: deviceContextRefresh ?? this.deviceContextRefresh,
      defaultOptOut: defaultOptOut ?? this.defaultOptOut,
      generateEventIds: generateEventIds ?? this.generateEventIds,
      enableSessionTracking: enableSessionTracking ?? this.enableSessionTracking,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      maxBatchBytes: maxBatchBytes ?? this.maxBatchBytes,
      compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      networkConfig: networkConfig ?? this.networkConfig,
      performanceConfig: performanceConfig ?? this.performanceConfig,
      privacyConfig: privacyConfig ?? this.privacyConfig,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCanalConfig &&
          runtimeType == other.runtimeType &&
          apiKey == other.apiKey &&
          endpoint == other.endpoint &&
          batchSize == other.batchSize &&
          flushInterval == other.flushInterval &&
          maxRetries == other.maxRetries &&
          networkTimeout == other.networkTimeout &&
          closeTimeout == other.closeTimeout &&
          enableDebugLogging == other.enableDebugLogging &&
          logLevel == other.logLevel &&
          collectDeviceContext == other.collectDeviceContext &&
          enableOfflineStorage == other.enableOfflineStorage &&
          maxOfflineEvents == other.maxOfflineEvents &&
          deviceContextRefresh == other.deviceContextRefresh &&
          defaultOptOut == other.defaultOptOut &&
          generateEventIds == other.generateEventIds &&
          enableSessionTracking == other.enableSessionTracking &&
          sessionTimeout == other.sessionTimeout &&
          maxBatchBytes == other.maxBatchBytes &&
          compressionEnabled == other.compressionEnabled &&
          networkConfig == other.networkConfig &&
          performanceConfig == other.performanceConfig &&
          privacyConfig == other.privacyConfig;

  @override
  int get hashCode => Object.hashAll([
        apiKey,
        endpoint,
        batchSize,
        flushInterval,
        maxRetries,
        networkTimeout,
        closeTimeout,
        enableDebugLogging,
        logLevel,
        collectDeviceContext,
        enableOfflineStorage,
        maxOfflineEvents,
        deviceContextRefresh,
        defaultOptOut,
        generateEventIds,
        enableSessionTracking,
        sessionTimeout,
        maxBatchBytes,
        compressionEnabled,
        networkConfig,
        performanceConfig,
        privacyConfig,
      ]);

  @override
  String toString() {
    return 'UserCanalConfig('
        'apiKey: ${apiKey.substring(0, 8)}...******, '
        'endpoint: $endpoint, '
        'batchSize: $batchSize, '
        'flushInterval: $flushInterval, '
        'maxRetries: $maxRetries, '
        'networkTimeout: $networkTimeout, '
        'enableDebugLogging: $enableDebugLogging, '
        'logLevel: $logLevel'
        ')';
  }

  /// Validates endpoint format
  static bool _isValidEndpoint(String endpoint) {
    if (endpoint.isEmpty) return false;

    // Basic validation for hostname/domain
    if (endpoint.contains(' ') || endpoint.contains('\n') || endpoint.contains('\t')) {
      return false;
    }

    // Check for invalid characters that shouldn't be in hostname
    if (endpoint.contains('://')) {
      return false; // No protocol should be included
    }

    // Must not be just dots or contain consecutive dots
    if (endpoint == '.' || endpoint == '..' || endpoint.contains('..')) {
      return false;
    }

    return true;
  }

  // MARK: - Presets

  /// Development configuration with debug settings enabled
  factory UserCanalConfig.development({
    required String apiKey,
    String? endpoint,
  }) {
    return UserCanalConfig(
      apiKey: apiKey,
      endpoint: endpoint ?? _Defaults.endpoint,
      batchSize: 10,
      flushInterval: const Duration(seconds: 2),
      enableDebugLogging: true,
      logLevel: SystemLogLevel.debug,
      networkConfig: const NetworkConfig(connectionPoolSize: 1, keepAliveInterval: Duration(seconds: 10)),
      performanceConfig: const PerformanceConfig(backgroundProcessingEnabled: false, memoryPressureThreshold: 0.5),
    );
  }

  /// Production configuration with optimized settings
  factory UserCanalConfig.production({
    required String apiKey,
    String? endpoint,
  }) {
    return UserCanalConfig(
      apiKey: apiKey,
      endpoint: endpoint ?? _Defaults.endpoint,
      networkConfig: const NetworkConfig(connectionPoolSize: 5, keepAliveInterval: Duration(seconds: 60)),
      performanceConfig: const PerformanceConfig(),
    );
  }

  /// Privacy-first configuration with strict privacy controls
  factory UserCanalConfig.privacyFirst({
    required String apiKey,
    String? endpoint,
  }) {
    return UserCanalConfig(
      apiKey: apiKey,
      endpoint: endpoint ?? _Defaults.endpoint,
      defaultOptOut: true,
      collectDeviceContext: false,
      generateEventIds: false,
      privacyConfig: const PrivacyConfig(
        requireExplicitConsent: true,
        minimizeDataCollection: true,
      ),
    );
  }
}

/// Network-specific configuration
@immutable
class NetworkConfig {
  const NetworkConfig({
    this.connectionPoolSize = 3,
    this.keepAliveInterval = const Duration(seconds: 30),
    this.enableHttpUpgrade = false,
    this.userAgent,
    this.additionalHeaders = const {},
  });

  /// Maximum number of concurrent connections
  final int connectionPoolSize;

  /// Keep-alive interval for connections
  final Duration keepAliveInterval;

  /// Whether to attempt HTTP upgrade (not recommended for production)
  final bool enableHttpUpgrade;

  /// Custom user agent string
  final String? userAgent;

  /// Additional headers to send with requests
  final Map<String, String> additionalHeaders;



  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkConfig &&
          runtimeType == other.runtimeType &&
          connectionPoolSize == other.connectionPoolSize &&
          keepAliveInterval == other.keepAliveInterval &&
          enableHttpUpgrade == other.enableHttpUpgrade &&
          userAgent == other.userAgent &&
          _mapEquals(additionalHeaders, other.additionalHeaders);

  @override
  int get hashCode => Object.hash(
        connectionPoolSize,
        keepAliveInterval,
        enableHttpUpgrade,
        userAgent,
        Object.hashAll(additionalHeaders.entries.map((e) => Object.hash(e.key, e.value))),
      );
}

/// Performance tuning configuration
@immutable
class PerformanceConfig {
  const PerformanceConfig({
    this.backgroundProcessingEnabled = true,
    this.memoryPressureThreshold = 0.8,
    this.cpuThrottleThreshold = 0.9,
    this.batchCompressionThreshold = 1024,
    this.enableLazyInitialization = true,
  });

  /// Whether to enable background processing
  final bool backgroundProcessingEnabled;

  /// Memory usage threshold before throttling (0.0-1.0)
  final double memoryPressureThreshold;

  /// CPU usage threshold before throttling (0.0-1.0)
  final double cpuThrottleThreshold;

  /// Minimum batch size to enable compression (bytes)
  final int batchCompressionThreshold;

  /// Whether to enable lazy initialization of components
  final bool enableLazyInitialization;



  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceConfig &&
          runtimeType == other.runtimeType &&
          backgroundProcessingEnabled == other.backgroundProcessingEnabled &&
          memoryPressureThreshold == other.memoryPressureThreshold &&
          cpuThrottleThreshold == other.cpuThrottleThreshold &&
          batchCompressionThreshold == other.batchCompressionThreshold &&
          enableLazyInitialization == other.enableLazyInitialization;

  @override
  int get hashCode => Object.hash(
        backgroundProcessingEnabled,
        memoryPressureThreshold,
        cpuThrottleThreshold,
        batchCompressionThreshold,
        enableLazyInitialization,
      );
}

/// Privacy and compliance configuration
@immutable
class PrivacyConfig {
  const PrivacyConfig({
    this.requireExplicitConsent = false,
    this.minimizeDataCollection = false,
    this.dataRetentionDays,
    this.allowedDataTypes = const {
      DataType.events,
      DataType.logs,
      DataType.deviceContext,
    },
    this.personalDataFields = const <String>{},
  });

  /// Whether explicit user consent is required
  final bool requireExplicitConsent;

  /// Whether to minimize data collection
  final bool minimizeDataCollection;

  /// Data retention period (null = server default)
  final int? dataRetentionDays;

  /// Types of data allowed to be collected
  final Set<DataType> allowedDataTypes;

  /// Fields considered as personal data (for extra protection)
  final Set<String> personalDataFields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyConfig &&
          runtimeType == other.runtimeType &&
          requireExplicitConsent == other.requireExplicitConsent &&
          minimizeDataCollection == other.minimizeDataCollection &&
          dataRetentionDays == other.dataRetentionDays &&
          _setEquals(allowedDataTypes, other.allowedDataTypes) &&
          _setEquals(personalDataFields, other.personalDataFields);

  @override
  int get hashCode => Object.hash(
        requireExplicitConsent,
        minimizeDataCollection,
        dataRetentionDays,
        Object.hashAll(allowedDataTypes),
        Object.hashAll(personalDataFields),
      );
}

/// Types of data that can be collected
enum DataType {
  events,
  logs,
  deviceContext,
  sessionData,
  performanceMetrics,
}

/// System log levels for SDK internal logging
enum SystemLogLevel {
  emergency,
  alert,
  critical,
  error,
  warning,
  notice,
  info,
  debug,
  trace,
}

/// Configuration builder for fluent API
class UserCanalConfigBuilder {
  String? _apiKey;
  String _endpoint = _Defaults.endpoint;
  int _batchSize = _Defaults.batchSize;
  Duration _flushInterval = _Defaults.flushInterval;
  int _maxRetries = _Defaults.maxRetries;
  Duration _networkTimeout = _Defaults.networkTimeout;
  Duration _closeTimeout = _Defaults.closeTimeout;
  bool _enableDebugLogging = _Defaults.enableDebugLogging;
  SystemLogLevel _logLevel = _Defaults.logLevel;
  bool _collectDeviceContext = _Defaults.collectDeviceContext;
  bool _enableOfflineStorage = _Defaults.enableOfflineStorage;
  int _maxOfflineEvents = _Defaults.maxOfflineEvents;
  Duration _deviceContextRefresh = _Defaults.deviceContextRefresh;
  bool _defaultOptOut = _Defaults.defaultOptOut;
  bool _generateEventIds = _Defaults.generateEventIds;
  bool _enableSessionTracking = _Defaults.enableSessionTracking;
  Duration _sessionTimeout = _Defaults.sessionTimeout;
  int _maxBatchBytes = _Defaults.maxBatchBytes;
  bool _compressionEnabled = _Defaults.compressionEnabled;
  NetworkConfig _networkConfig = const NetworkConfig();
  PerformanceConfig _performanceConfig = const PerformanceConfig();
  PrivacyConfig _privacyConfig = const PrivacyConfig();

  UserCanalConfigBuilder apiKey(String apiKey) {
    _apiKey = apiKey;
    return this;
  }

  UserCanalConfigBuilder endpoint(String endpoint) {
    _endpoint = endpoint;
    return this;
  }

  UserCanalConfigBuilder batchSize(int batchSize) {
    _batchSize = batchSize;
    return this;
  }

  UserCanalConfigBuilder flushInterval(Duration flushInterval) {
    _flushInterval = flushInterval;
    return this;
  }

  UserCanalConfigBuilder maxRetries(int maxRetries) {
    _maxRetries = maxRetries;
    return this;
  }

  UserCanalConfigBuilder networkTimeout(Duration networkTimeout) {
    _networkTimeout = networkTimeout;
    return this;
  }

  UserCanalConfigBuilder enableDebugLogging([bool enabled = true]) {
    _enableDebugLogging = enabled;
    return this;
  }

  UserCanalConfigBuilder logLevel(SystemLogLevel logLevel) {
    _logLevel = logLevel;
    return this;
  }

  UserCanalConfigBuilder collectDeviceContext([bool enabled = true]) {
    _collectDeviceContext = enabled;
    return this;
  }

  UserCanalConfigBuilder enableOfflineStorage([bool enabled = true]) {
    _enableOfflineStorage = enabled;
    return this;
  }

  UserCanalConfigBuilder defaultOptOut([bool optOut = true]) {
    _defaultOptOut = optOut;
    return this;
  }

  UserCanalConfigBuilder generateEventIds([bool enabled = true]) {
    _generateEventIds = enabled;
    return this;
  }

  UserCanalConfigBuilder networkConfig(NetworkConfig config) {
    _networkConfig = config;
    return this;
  }

  UserCanalConfigBuilder performanceConfig(PerformanceConfig config) {
    _performanceConfig = config;
    return this;
  }

  UserCanalConfigBuilder privacyConfig(PrivacyConfig config) {
    _privacyConfig = config;
    return this;
  }

  /// Build the configuration
  UserCanalConfig build() {
    if (_apiKey == null) {
      throw const InvalidApiKeyError('API key is required');
    }

    final config = UserCanalConfig(
      apiKey: _apiKey!,
      endpoint: _endpoint,
      batchSize: _batchSize,
      flushInterval: _flushInterval,
      maxRetries: _maxRetries,
      networkTimeout: _networkTimeout,
      closeTimeout: _closeTimeout,
      enableDebugLogging: _enableDebugLogging,
      logLevel: _logLevel,
      collectDeviceContext: _collectDeviceContext,
      enableOfflineStorage: _enableOfflineStorage,
      maxOfflineEvents: _maxOfflineEvents,
      deviceContextRefresh: _deviceContextRefresh,
      defaultOptOut: _defaultOptOut,
      generateEventIds: _generateEventIds,
      enableSessionTracking: _enableSessionTracking,
      sessionTimeout: _sessionTimeout,
      maxBatchBytes: _maxBatchBytes,
      compressionEnabled: _compressionEnabled,
      networkConfig: _networkConfig,
      performanceConfig: _performanceConfig,
      privacyConfig: _privacyConfig,
    );

    config.validate();
    return config;
  }
}

/// Default configuration values
class _Defaults {
  static const String endpoint = 'collect.usercanal.com';
  static const int port = 50000;
  static const int batchSize = 50;
  static const Duration flushInterval = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const int maxRetryAttempts = 5;
  static const Duration retryBaseDelay = Duration(seconds: 1);
  static const Duration retryMaxDelay = Duration(seconds: 60);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration closeTimeout = Duration(seconds: 5);
  static const bool enableAutoReconnect = true;
  static const bool enableDebugLogging = false;
  static const SystemLogLevel logLevel = SystemLogLevel.info;
  static const bool collectDeviceContext = true;
  static const bool enableOfflineStorage = true;
  static const int maxOfflineEvents = 1000;
  static const Duration deviceContextRefresh = Duration(hours: 24);
  static const bool defaultOptOut = false;
  static const bool generateEventIds = true;
  static const bool enableSessionTracking = true;
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const int maxBatchBytes = 512 * 1024; // 512KB
  static const bool compressionEnabled = true;
}

/// Utility functions for equality checking
bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
