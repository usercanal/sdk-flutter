// Copyright © 2024 UserCanal. All rights reserved.

/// Network interfaces for UserCanal Flutter SDK
///
/// This module defines the network interfaces used throughout the networking
/// layer to avoid circular dependencies and enable proper dependency injection.

import 'dart:typed_data';

/// Network client interface for batch manager and other components
abstract class INetworkClient {
  Future<void> connect();
  Future<void> send(Uint8List data);
  Future<void> disconnect();
  bool get isConnected;
  Stream<Uint8List> get incomingData;
  Stream<bool> get connectionStatus;
}

/// Batch manager interface for dependency injection
abstract class IBatchManager {
  Future<void> addEvent(dynamic event);
  Future<void> addLogEntry(dynamic logEntry);
  Future<void> flush();
  Future<void> shutdown();
  void setConnectionStatus(bool connected);

  int get eventBatchSize;
  int get logBatchSize;
  int get pendingRetryCount;
  bool get isEmpty;
}

/// User canal client interface
abstract class IUserCanalClient {
  Future<void> event({
    required String userID,
    required dynamic eventName,
    dynamic properties,
  });

  Future<void> eventIdentify({
    required String userID,
    dynamic traits,
  });

  Future<void> eventGroup({
    required String userID,
    required String groupID,
    dynamic properties,
  });

  Future<void> eventAlias({
    required String previousId,
    required String userId,
  });

  Future<void> eventRevenue({
    required String userID,
    required String orderID,
    required double amount,
    required dynamic currency,
    dynamic properties,
  });

  Future<void> eventWithType({
    required String userID,
    required dynamic eventName,
    required dynamic eventType,
    dynamic properties,
  });

  // Logging methods
  Future<void> logInfo(String service, String message, {dynamic data});
  Future<void> logError(String service, String message, {dynamic data});
  Future<void> logDebug(String service, String message, {dynamic data});
  Future<void> logWarning(String service, String message, {dynamic data});
  Future<void> logCritical(String service, String message, {dynamic data});
  Future<void> logAlert(String service, String message, {dynamic data});
  Future<void> logEmergency(String service, String message, {dynamic data});
  Future<void> logNotice(String service, String message, {dynamic data});
  Future<void> logTrace(String service, String message, {dynamic data});

  // Lifecycle
  Future<void> flush();
  Future<void> close();

  // Status
  bool get isConnected;
  bool get isInitialized;
  Map<String, dynamic> get statistics;
}
