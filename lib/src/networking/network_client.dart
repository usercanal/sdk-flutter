// Copyright © 2024 UserCanal. All rights reserved.

/// Enhanced Network Client for UserCanal Flutter SDK
///
/// This module provides a robust TCP network client with connection pooling,
/// retry logic, exponential backoff, and proper error handling for the
/// UserCanal CDP platform.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import '../core/configuration.dart';
import '../errors/user_canal_error.dart';
import 'interfaces.dart';

/// Enhanced network client with connection management and retry logic
class NetworkClient implements INetworkClient {
  NetworkClient({
    required this.config,
    required this.onError,
  });

  final UserCanalConfig config;
  final UserCanalErrorCallback onError;

  // Connection state
  Socket? _socket;
  StreamSubscription? _socketSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  DateTime? _lastConnectionAttempt;
  int _connectionAttempts = 0;

  // Retry management
  Timer? _reconnectTimer;
  final Completer<void> _connectionCompleter = Completer<void>();

  // Data streams
  final StreamController<Uint8List> _incomingDataController =
      StreamController<Uint8List>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  // Connection pool management
  static final Map<String, NetworkClient> _connectionPool = {};
  static const int _maxPoolSize = 5;

  // MARK: - Public Interface

  /// Stream of incoming data from the server
  Stream<Uint8List> get incomingData => _incomingDataController.stream;

  /// Stream of connection status changes
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Check if currently connected
  bool get isConnected => _isConnected;

  /// Check if connection attempt is in progress
  bool get isConnecting => _isConnecting;

  /// Get connection pool key
  String get _poolKey => '${config.endpoint}:${config.port}';

  /// Get or create a pooled connection
  static NetworkClient getPooledConnection({
    required UserCanalConfig config,
    required UserCanalErrorCallback onError,
  }) {
    final key = '${config.endpoint}:${config.port}';

    if (_connectionPool.containsKey(key)) {
      return _connectionPool[key]!;
    }

    // Clean up pool if it's getting too large
    if (_connectionPool.length >= _maxPoolSize) {
      _cleanupOldestConnection();
    }

    final client = NetworkClient(config: config, onError: onError);
    _connectionPool[key] = client;
    return client;
  }

  /// Connect to the server with retry logic
  Future<void> connect() async {
    if (_isConnected) {
      return _connectionCompleter.future;
    }

    if (_isConnecting) {
      return _connectionCompleter.future;
    }

    _isConnecting = true;
    _connectionAttempts++;
    _lastConnectionAttempt = DateTime.now();

    try {
      await _attemptConnection();

      if (!_connectionCompleter.isCompleted) {
        _connectionCompleter.complete();
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Send data to the server
  Future<void> send(Uint8List data) async {
    if (!_isConnected) {
      throw const NetworkConnectivityError();
    }

    if (_socket == null) {
      throw const NetworkConnectivityError();
    }

    try {
      _socket!.add(data);
      await _socket!.flush();

      _logDebug('Sent ${data.length} bytes to server');
    } catch (e) {
      _logError('Failed to send data: $e');
      await _handleSocketError(e);
      throw NetworkConnectivityError();
    }
  }

  /// Disconnect from the server
  Future<void> disconnect() async {
    _logDebug('Disconnecting from server...');

    _isConnected = false;
    _isConnecting = false;

    // Cancel reconnect timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Close socket subscription
    await _socketSubscription?.cancel();
    _socketSubscription = null;

    // Close socket
    try {
      await _socket?.close();
    } catch (e) {
      _logError('Error closing socket: $e');
    }
    _socket = null;

    // Notify status change
    _connectionStatusController.add(false);

    // Complete connection completer with error if pending
    if (!_connectionCompleter.isCompleted) {
      _connectionCompleter.completeError(
        const NetworkConnectivityError()
      );
    }

    _logDebug('Disconnected from server');
  }

  /// Shutdown and cleanup resources
  Future<void> shutdown() async {
    await disconnect();

    await _incomingDataController.close();
    await _connectionStatusController.close();

    // Remove from connection pool
    _connectionPool.remove(_poolKey);
  }

  // MARK: - Private Implementation

  /// Attempt to establish connection
  Future<void> _attemptConnection() async {
    _logDebug('Connecting to ${config.endpoint}:${config.port}...');

    try {
      _socket = await Socket.connect(
        config.endpoint,
        config.port,
        timeout: config.connectionTimeout,
      );

      _setupSocketListeners();
      _isConnected = true;
      _connectionAttempts = 0; // Reset on successful connection

      _connectionStatusController.add(true);
      _logDebug('Connection established successfully');

    } on SocketException catch (e) {
      throw ConnectionError(config.endpoint, e);
    } on TimeoutException catch (e) {
      throw ConnectionTimeoutError(config.connectionTimeout);
    } catch (e) {
      throw ConnectionError(config.endpoint, e);
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    _socketSubscription = _socket!.listen(
      _handleIncomingData,
      onError: _handleSocketError,
      onDone: _handleSocketClosed,
      cancelOnError: false,
    );

    // Enable TCP keep-alive
    _socket!.setOption(SocketOption.tcpNoDelay, true);
  }

  /// Handle incoming data from socket
  void _handleIncomingData(List<int> data) {
    try {
      final bytes = Uint8List.fromList(data);
      _incomingDataController.add(bytes);
      _logDebug('Received ${bytes.length} bytes from server');
    } catch (e) {
      _logError('Error processing incoming data: $e');
      onError(ErrorUtils.fromException(e));
    }
  }

  /// Handle socket errors
  Future<void> _handleSocketError(dynamic error) async {
    _logError('Socket error: $error');

    _isConnected = false;
    _connectionStatusController.add(false);

    final userCanalError = ErrorUtils.fromException(error);
    onError(userCanalError);

    // Attempt reconnection if configured
    if (config.enableAutoReconnect && _shouldAttemptReconnect()) {
      _scheduleReconnect();
    }
  }

  /// Handle socket connection closed
  void _handleSocketClosed() {
    _logDebug('Socket connection closed by server');

    _isConnected = false;
    _connectionStatusController.add(false);

    // Attempt reconnection if configured
    if (config.enableAutoReconnect && _shouldAttemptReconnect()) {
      _scheduleReconnect();
    }
  }

  /// Handle connection errors with retry logic
  void _handleConnectionError(dynamic error) {
    _logError('Connection failed (attempt $_connectionAttempts): $error');

    final userCanalError = ErrorUtils.fromException(error);
    onError(userCanalError);

    if (_shouldAttemptReconnect()) {
      _scheduleReconnect();
    } else {
      if (!_connectionCompleter.isCompleted) {
        _connectionCompleter.completeError(userCanalError);
      }
    }
  }

  /// Determine if should attempt reconnection
  bool _shouldAttemptReconnect() {
    return _connectionAttempts < config.maxRetryAttempts &&
           config.enableAutoReconnect;
  }

  /// Schedule reconnection attempt with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already scheduled
    }

    final delay = _calculateBackoffDelay();
    _logDebug('Scheduling reconnection in ${delay.inSeconds} seconds');

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && !_isConnecting) {
        connect().catchError((e) {
          _logError('Reconnection failed: $e');
        });
      }
    });
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay() {
    final baseDelay = config.retryBaseDelay;
    final maxDelay = config.retryMaxDelay;

    // Exponential backoff: baseDelay * 2^(attempts-1)
    final delay = baseDelay * (1 << (_connectionAttempts - 1));
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Clean up oldest connection from pool
  static void _cleanupOldestConnection() {
    if (_connectionPool.isEmpty) return;

    final oldestKey = _connectionPool.keys.first;
    final oldestClient = _connectionPool.remove(oldestKey);

    oldestClient?.shutdown().catchError((e) {
      print('[NetworkClient] Error shutting down old connection: $e');
    });
  }

  /// Debug logging
  void _logDebug(String message) {
    if (config.enableDebugLogging) {
      print('[NetworkClient] $message');
    }
  }

  /// Error logging
  void _logError(String message) {
    print('[NetworkClient] ERROR: $message');
  }

  // MARK: - Static Utilities

  /// Clean up all pooled connections
  static Future<void> shutdownAll() async {
    final clients = List<NetworkClient>.from(_connectionPool.values);
    _connectionPool.clear();

    await Future.wait(
      clients.map((client) => client.shutdown()),
    );
  }

  /// Get connection pool statistics
  static Map<String, dynamic> getPoolStats() {
    return {
      'pool_size': _connectionPool.length,
      'max_pool_size': _maxPoolSize,
      'connections': _connectionPool.keys.toList(),
    };
  }
}

/// Mock network client for testing
class MockNetworkClient implements INetworkClient {
  MockNetworkClient({this.shouldFailConnection = false});

  final bool shouldFailConnection;
  bool _isConnected = false;

  final StreamController<Uint8List> _incomingDataController =
      StreamController<Uint8List>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  @override
  Stream<Uint8List> get incomingData => _incomingDataController.stream;

  @override
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect() async {
    if (shouldFailConnection) {
      throw const ConnectionError('mock-host');
    }

    _isConnected = true;
    _connectionStatusController.add(true);
  }

  @override
  Future<void> send(Uint8List data) async {
    if (!_isConnected) {
      throw const NetworkConnectivityError();
    }
    // Mock successful send
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _connectionStatusController.add(false);

    await _incomingDataController.close();
    await _connectionStatusController.close();
  }

  /// Simulate incoming data (for testing)
  void simulateIncomingData(Uint8List data) {
    if (_isConnected) {
      _incomingDataController.add(data);
    }
  }

  /// Simulate connection error (for testing)
  void simulateConnectionError() {
    _isConnected = false;
    _connectionStatusController.add(false);
  }
}
