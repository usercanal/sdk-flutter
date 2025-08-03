// device_context.dart
// UserCanal Flutter SDK - Device Context Collection
//
// Copyright © 2024 UserCanal. All rights reserved.
//

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../system_logging/logging.dart';
import 'device_constants.dart';

/// Device context collection for automatic enrichment of events
/// Matches Swift SDK DeviceContext functionality with Flutter-specific implementations
class DeviceContext {
  // MARK: - Cached Context

  Map<String, Object?>? _cachedContext;
  DateTime? _lastUpdateTime;
  static const Duration _cacheInterval = Duration(minutes: 5);

  // MARK: - Singleton

  static DeviceContext? _instance;
  static DeviceContext get instance => _instance ??= DeviceContext._();

  DeviceContext._();

  // MARK: - Device Info Instances

  late final DeviceInfoPlugin _deviceInfo;
  late final Connectivity _connectivity;

  // MARK: - Initialization

  /// Initialize device context collector
  Future<void> initialize() async {
    _deviceInfo = DeviceInfoPlugin();
    _connectivity = Connectivity();

    SDKLogger.debug('Device context collector initialized', category: LogCategory.device);
  }

  // MARK: - Public Interface

  /// Get current device context as properties
  /// Returns cached context if available and within cache interval
  Future<Map<String, Object?>> getContext() async {
    try {
      // Check if cache is still valid
      if (_cachedContext != null &&
          _lastUpdateTime != null &&
          DateTime.now().difference(_lastUpdateTime!) < _cacheInterval) {
        SDKLogger.trace('Returning cached device context', category: LogCategory.device);
        return Map<String, Object?>.from(_cachedContext!);
      }

      // Collect fresh context
      SDKLogger.debug('Collecting fresh device context', category: LogCategory.device);
      final context = await _collectDeviceContext();

      // Cache the result
      _cachedContext = context;
      _lastUpdateTime = DateTime.now();

      SDKLogger.debug('Device context collected: ${context.keys.length} properties', category: LogCategory.device);
      return context;
    } catch (e) {
      SDKLogger.error('Failed to collect device context', error: e, category: LogCategory.device);
      return {};
    }
  }

  /// Force refresh of device context cache
  Future<void> refreshContext() async {
    SDKLogger.debug('Forcing device context refresh', category: LogCategory.device);
    _cachedContext = null;
    _lastUpdateTime = null;
    await getContext();
  }

  /// Get a minimal device context for performance-critical scenarios
  Future<Map<String, Object?>> getMinimalContext() async {
    try {
      final Map<String, Object?> context = {};

      // Basic device information
      context[DeviceContextKeys.deviceType] = (await _getDeviceType()).value;
      context[DeviceContextKeys.operatingSystem] = _getOperatingSystem().value;
      context[DeviceContextKeys.osVersion] = await _getOSVersion();

      // App information
      final appInfo = await _getAppInfo();
      context[DeviceContextKeys.appVersion] = appInfo[DeviceContextKeys.appVersion];

      return context;
    } catch (e) {
      SDKLogger.error('Failed to collect minimal device context', error: e, category: LogCategory.device);
      return {};
    }
  }

  /// Check if device context has changed since last collection
  bool hasContextChanged() {
    if (_lastUpdateTime == null) return true;
    return DateTime.now().difference(_lastUpdateTime!) >= _cacheInterval;
  }

  // MARK: - Context Collection

  Future<Map<String, Object?>> _collectDeviceContext() async {
    final Map<String, Object?> context = {};

    try {
      // Basic device information
      context[DeviceContextKeys.deviceType] = (await _getDeviceType()).value;
      context[DeviceContextKeys.operatingSystem] = _getOperatingSystem().value;
      context[DeviceContextKeys.osVersion] = await _getOSVersion();

      final deviceInfo = await _getDeviceInfo();
      context.addAll(deviceInfo);

      // App information
      final appInfo = await _getAppInfo();
      context.addAll(appInfo);

      // Screen information
      final screenInfo = _getScreenInfo();
      context.addAll(screenInfo);

      // Memory information (limited on mobile platforms)
      final memoryInfo = await _getMemoryInfo();
      context.addAll(memoryInfo);

      // Network information
      final networkInfo = await _getNetworkInfo();
      context.addAll(networkInfo);

      // Locale and timezone
      final localeInfo = _getLocaleInfo();
      context.addAll(localeInfo);

      // App state
      context[DeviceContextKeys.appState] = _getAppState().value;

      // System information
      final systemInfo = _getSystemInfo();
      context.addAll(systemInfo);

    } catch (e) {
      SDKLogger.error('Error during device context collection', error: e, category: LogCategory.device);
    }

    return context;
  }

  // MARK: - Device Type Detection

  Future<DeviceType> _getDeviceType() async {
    try {
      if (kIsWeb) {
        return DeviceType.desktop; // Web is typically desktop
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Check if it's a tablet based on screen size or specific models
        final shortestSide = ui.window.physicalSize.shortestSide / ui.window.devicePixelRatio;
        return shortestSide >= 600 ? DeviceType.tablet : DeviceType.mobile;
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final model = iosInfo.model.toLowerCase();
        if (model.contains('ipad')) {
          return DeviceType.tablet;
        } else if (model.contains('iphone')) {
          return DeviceType.mobile;
        } else if (model.contains('apple tv')) {
          return DeviceType.tv;
        } else if (model.contains('watch')) {
          return DeviceType.watch;
        }
        return DeviceType.mobile;
      }

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return DeviceType.desktop;
      }

      return DeviceType.unknown;
    } catch (e) {
      SDKLogger.error('Failed to determine device type', error: e, category: LogCategory.device);
      return DeviceType.unknown;
    }
  }

  OSType _getOperatingSystem() {
    if (kIsWeb) return OSType.web;
    if (Platform.isAndroid) return OSType.android;
    if (Platform.isIOS) return OSType.iOS;
    if (Platform.isMacOS) return OSType.macOS;
    if (Platform.isWindows) return OSType.windows;
    if (Platform.isLinux) return OSType.linux;
    return OSType.unknown;
  }

  Future<String> _getOSVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.systemVersion;
      }

      if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return '${macInfo.majorVersion}.${macInfo.minorVersion}.${macInfo.patchVersion}';
      }

      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}.${windowsInfo.buildNumber}';
      }

      if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.version ?? 'Unknown';
      }

      return 'Unknown';
    } catch (e) {
      SDKLogger.error('Failed to get OS version', error: e, category: LogCategory.device);
      return 'Unknown';
    }
  }

  // MARK: - Device Information

  Future<Map<String, Object?>> _getDeviceInfo() async {
    final Map<String, Object?> info = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info[DeviceContextKeys.deviceModel] = androidInfo.model;
        info[DeviceContextKeys.deviceManufacturer] = androidInfo.manufacturer;
        info[DeviceContextKeys.deviceName] = androidInfo.device;
        info[DeviceContextKeys.isPhysicalDevice] = androidInfo.isPhysicalDevice;
        info[DeviceContextKeys.isEmulator] = !androidInfo.isPhysicalDevice;
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info[DeviceContextKeys.deviceModel] = iosInfo.model;
        info[DeviceContextKeys.deviceName] = iosInfo.name;
        info[DeviceContextKeys.isPhysicalDevice] = iosInfo.isPhysicalDevice;
        info[DeviceContextKeys.isEmulator] = !iosInfo.isPhysicalDevice;
      }

      if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        info[DeviceContextKeys.deviceModel] = macInfo.model;
        info[DeviceContextKeys.deviceName] = macInfo.computerName;
        info[DeviceContextKeys.cpuArchitecture] = macInfo.arch;
      }

      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        info[DeviceContextKeys.deviceName] = windowsInfo.computerName;
        info[DeviceContextKeys.processorCount] = windowsInfo.numberOfCores;
      }

      if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        info[DeviceContextKeys.deviceName] = linuxInfo.name;
        info[DeviceContextKeys.deviceModel] = linuxInfo.prettyName;
      }
    } catch (e) {
      SDKLogger.error('Failed to get device information', error: e, category: LogCategory.device);
    }

    return info;
  }

  // MARK: - App Information

  Future<Map<String, Object?>> _getAppInfo() async {
    final Map<String, Object?> info = {};

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      info[DeviceContextKeys.appName] = packageInfo.appName;
      info[DeviceContextKeys.appVersion] = packageInfo.version;
      info[DeviceContextKeys.appBuild] = packageInfo.buildNumber;
      info[DeviceContextKeys.appBundleId] = packageInfo.packageName;
    } catch (e) {
      SDKLogger.error('Failed to get app information', error: e, category: LogCategory.device);
      info[DeviceContextKeys.appVersion] = 'Unknown';
      info[DeviceContextKeys.appBuild] = 'Unknown';
    }

    return info;
  }

  // MARK: - Screen Information

  Map<String, Object?> _getScreenInfo() {
    final Map<String, Object?> info = {};

    try {
      final physicalSize = ui.window.physicalSize;
      final devicePixelRatio = ui.window.devicePixelRatio;
      final logicalSize = physicalSize / devicePixelRatio;

      info[DeviceContextKeys.screenWidth] = physicalSize.width.toInt();
      info[DeviceContextKeys.screenHeight] = physicalSize.height.toInt();
      info[DeviceContextKeys.screenScale] = devicePixelRatio;
      info[DeviceContextKeys.screenLogicalWidth] = logicalSize.width.toInt();
      info[DeviceContextKeys.screenLogicalHeight] = logicalSize.height.toInt();
      info[DeviceContextKeys.screenDensity] = devicePixelRatio;
    } catch (e) {
      SDKLogger.error('Failed to get screen information', error: e, category: LogCategory.device);
    }

    return info;
  }

  // MARK: - Memory Information

  Future<Map<String, Object?>> _getMemoryInfo() async {
    final Map<String, Object?> info = {};

    try {
      // Memory information is limited on mobile platforms for privacy/security
      // We can only get basic information through platform channels
      if (Platform.isAndroid) {
        // Android memory info would require platform channel implementation
        // For now, we'll skip detailed memory information
      }

      if (Platform.isIOS) {
        // iOS memory info would require platform channel implementation
        // For now, we'll skip detailed memory information
      }

      // For desktop platforms, we could implement more detailed memory info
      // but it would require platform-specific implementations

    } catch (e) {
      SDKLogger.error('Failed to get memory information', error: e, category: LogCategory.device);
    }

    return info;
  }

  // MARK: - Network Information

  Future<Map<String, Object?>> _getNetworkInfo() async {
    final Map<String, Object?> info = {};

    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      info[DeviceContextKeys.networkConnected] = connectivityResult != ConnectivityResult.none;

      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          info[DeviceContextKeys.networkType] = NetworkType.wifi.value;
          break;
        case ConnectivityResult.mobile:
          info[DeviceContextKeys.networkType] = NetworkType.mobile.value;
          break;
        case ConnectivityResult.ethernet:
          info[DeviceContextKeys.networkType] = NetworkType.ethernet.value;
          break;
        case ConnectivityResult.bluetooth:
          info[DeviceContextKeys.networkType] = NetworkType.bluetooth.value;
          break;
        case ConnectivityResult.vpn:
          info[DeviceContextKeys.networkType] = NetworkType.vpn.value;
          break;
        case ConnectivityResult.none:
          info[DeviceContextKeys.networkType] = NetworkType.none.value;
          break;
        case ConnectivityResult.other:
          info[DeviceContextKeys.networkType] = NetworkType.unknown.value;
          break;
      }
    } catch (e) {
      SDKLogger.error('Failed to get network information', error: e, category: LogCategory.device);
      info[DeviceContextKeys.networkConnected] = false;
      info[DeviceContextKeys.networkType] = NetworkType.unknown.value;
    }

    return info;
  }

  // MARK: - Locale Information

  Map<String, Object?> _getLocaleInfo() {
    final Map<String, Object?> info = {};

    try {
      final locale = ui.window.locale;

      info[DeviceContextKeys.locale] = locale.toString();
      info[DeviceContextKeys.language] = locale.languageCode;
      info[DeviceContextKeys.country] = locale.countryCode ?? 'Unknown';

      // Timezone information
      final timezone = DateTime.now().timeZoneName;
      final timezoneOffset = DateTime.now().timeZoneOffset;
      info[DeviceContextKeys.timezone] = timezone;
    } catch (e) {
      SDKLogger.error('Failed to get locale information', error: e, category: LogCategory.device);
      info[DeviceContextKeys.locale] = 'Unknown';
      info[DeviceContextKeys.language] = 'Unknown';
    }

    return info;
  }

  // MARK: - App State

  AppState _getAppState() {
    try {
      // In Flutter, we can get app lifecycle state through WidgetsBinding
      // However, this requires the widget tree to be initialized
      // For now, we'll return unknown as this is typically handled by lifecycle manager
      return AppState.unknown;
    } catch (e) {
      SDKLogger.error('Failed to get app state', error: e, category: LogCategory.device);
      return AppState.unknown;
    }
  }

  // MARK: - System Information

  Map<String, Object?> _getSystemInfo() {
    final Map<String, Object?> info = {};

    try {
      info[DeviceContextKeys.isPhysicalDevice] = !kDebugMode || kReleaseMode;

      // Platform-specific system information
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile platforms - limited system info for privacy
        info[DeviceContextKeys.processorCount] = Platform.numberOfProcessors;
      }

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // Desktop platforms - more system info available
        info[DeviceContextKeys.processorCount] = Platform.numberOfProcessors;
      }
    } catch (e) {
      SDKLogger.error('Failed to get system information', error: e, category: LogCategory.device);
    }

    return info;
  }

  // MARK: - Cleanup

  /// Dispose of device context resources
  void dispose() {
    _cachedContext = null;
    _lastUpdateTime = null;
    SDKLogger.debug('Device context collector disposed', category: LogCategory.device);
  }
}
