// Copyright © 2024 UserCanal. All rights reserved.

/// Lifecycle Manager for UserCanal Flutter SDK
///
/// Optional lifecycle integration for Flutter apps that provides automatic
/// session tracking, app state monitoring, and connectivity detection.
/// This module is separate from the core SDK to avoid Flutter dependencies
/// in test environments.

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/user_canal.dart';
import '../core/constants.dart';
import '../models/properties.dart';

/// Optional lifecycle manager for automatic Flutter app integration
///
/// Usage:
/// ```dart
/// UserCanalLifecycleManager.initialize();
/// ```
class UserCanalLifecycleManager with WidgetsBindingObserver {
  UserCanalLifecycleManager._();

  static UserCanalLifecycleManager? _instance;
  static bool _isInitialized = false;

  // State tracking
  bool _isObserving = false;
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  DateTime? _lastBackgroundTime;

  /// Initialize the lifecycle manager
  /// Should be called after UserCanal.configure()
  static void initialize() {
    if (_isInitialized) return;

    _instance = UserCanalLifecycleManager._();
    _instance!._setupObservers();
    _isInitialized = true;
  }

  /// Shutdown the lifecycle manager
  static void shutdown() {
    if (!_isInitialized) return;

    _instance?._removeObservers();
    _instance = null;
    _isInitialized = false;
  }

  /// Check if lifecycle manager is active
  static bool get isActive => _isInitialized;

  /// Get current online status
  static bool get isOnline => _instance?._isOnline ?? true;

  // MARK: - Private Implementation

  void _setupObservers() {
    _setupLifecycleObserver();
    _setupConnectivityListener();
  }

  void _removeObservers() {
    _removeLifecycleObserver();
    _removeConnectivityListener();
  }

  void _setupLifecycleObserver() {
    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
      _logDebug('Lifecycle observer added');
    }
  }

  void _removeLifecycleObserver() {
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
      _logDebug('Lifecycle observer removed');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppForegrounded();
        break;
      case AppLifecycleState.paused:
        _handleAppBackgrounded();
        break;
      case AppLifecycleState.detached:
        _handleAppTermination();
        break;
      case AppLifecycleState.inactive:
        // Handle app becoming inactive (iOS specific)
        _logDebug('App became inactive');
        break;
      case AppLifecycleState.hidden:
        // Handle app being hidden (multi-window)
        _logDebug('App was hidden');
        break;
    }
  }

  void _handleAppForegrounded() {
    _logDebug('App foregrounded');

    // Check for session timeout if app was backgrounded
    if (_lastBackgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(_lastBackgroundTime!);
      _logDebug('App was backgrounded for ${backgroundDuration.inMinutes} minutes');
    }

    // Track app foregrounded event
    UserCanal.track(EventName.appForegrounded, properties: Properties.fromMap({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'session_id': UserCanal.currentSessionId,
      'background_duration_ms': _lastBackgroundTime != null
          ? DateTime.now().difference(_lastBackgroundTime!).inMilliseconds
          : 0,
    }));

    _lastBackgroundTime = null;
  }

  void _handleAppBackgrounded() {
    _logDebug('App backgrounded');
    _lastBackgroundTime = DateTime.now();

    // Track app backgrounded event
    UserCanal.track(EventName.appBackgrounded, properties: Properties.fromMap({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'session_id': UserCanal.currentSessionId,
      'session_event_count': UserCanal.sessionEventCount,
    }));

    // Flush data when app goes to background
    UserCanal.flush();
  }

  void _handleAppTermination() {
    _logDebug('App terminating - flushing data');

    // End current session
    UserCanal.endSession();

    // Final flush
    UserCanal.flush();
  }

  // MARK: - Connectivity Management

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _handleConnectivityChange(result);
    });

    // Check initial connectivity state
    Connectivity().checkConnectivity().then((result) {
      _handleConnectivityChange(result);
    });
  }

  void _removeConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (!wasOnline && _isOnline) {
      _logDebug('Device came back online');

      // Track connectivity restored event
      UserCanal.track(EventName.custom('connectivity_restored'), properties: Properties.fromMap({
        'connection_type': result.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));

    } else if (wasOnline && !_isOnline) {
      _logDebug('Device went offline');

      // Track connectivity lost event
      UserCanal.track(EventName.custom('connectivity_lost'), properties: Properties.fromMap({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }

  // MARK: - Logging

  void _logDebug(String message) {
    UserCanal.logDebug('[LifecycleManager] $message', service: 'lifecycle');
  }
}

/// Extension to add lifecycle convenience methods to UserCanal
extension UserCanalLifecycle on UserCanal {
  /// Enable automatic lifecycle tracking
  /// Call this after UserCanal.configure()
  static void enableLifecycleTracking() {
    UserCanalLifecycleManager.initialize();
  }

  /// Disable automatic lifecycle tracking
  static void disableLifecycleTracking() {
    UserCanalLifecycleManager.shutdown();
  }

  /// Check if lifecycle tracking is enabled
  static bool get isLifecycleTrackingEnabled => UserCanalLifecycleManager.isActive;
}
