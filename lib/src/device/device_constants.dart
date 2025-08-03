// device_constants.dart
// UserCanal Flutter SDK - Device Context Constants
//
// Copyright © 2024 UserCanal. All rights reserved.
//

/// Type of device used (for enrichment context only)
/// Matches Swift SDK DeviceType enum
enum DeviceType {
  /// Mobile phone
  mobile('mobile'),

  /// Tablet device
  tablet('tablet'),

  /// Desktop computer
  desktop('desktop'),

  /// Smart TV
  tv('tv'),

  /// Smartwatch
  watch('watch'),

  /// VR/AR headset
  vr('vr'),

  /// Unknown device type
  unknown('unknown');

  const DeviceType(this.value);

  final String value;

  /// Convert from string value
  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DeviceType.unknown,
    );
  }
}

/// Operating system type (for enrichment context only)
/// Matches Swift SDK OSType enum
enum OSType {
  /// iOS
  iOS('ios'),

  /// Android
  android('android'),

  /// macOS
  macOS('macos'),

  /// Windows
  windows('windows'),

  /// Linux
  linux('linux'),

  /// Web
  web('web'),

  /// Unknown OS
  unknown('unknown');

  const OSType(this.value);

  final String value;

  /// Convert from string value
  static OSType fromString(String value) {
    return OSType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OSType.unknown,
    );
  }
}

/// App state enumeration for context enrichment
enum AppState {
  /// App is active and in foreground
  active('active'),

  /// App is inactive (transitioning)
  inactive('inactive'),

  /// App is in background
  background('background'),

  /// App is paused (Android)
  paused('paused'),

  /// App is resumed (Android)
  resumed('resumed'),

  /// App is detached
  detached('detached'),

  /// Unknown state
  unknown('unknown');

  const AppState(this.value);

  final String value;

  /// Convert from string value
  static AppState fromString(String value) {
    return AppState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => AppState.unknown,
    );
  }
}

/// Battery state enumeration
enum BatteryState {
  /// Battery state unknown
  unknown('unknown'),

  /// Battery is unplugged
  unplugged('unplugged'),

  /// Battery is charging
  charging('charging'),

  /// Battery is full
  full('full'),

  /// Battery not supported
  notSupported('not_supported');

  const BatteryState(this.value);

  final String value;

  /// Convert from string value
  static BatteryState fromString(String value) {
    return BatteryState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => BatteryState.unknown,
    );
  }
}

/// Network connection type
enum NetworkType {
  /// WiFi connection
  wifi('wifi'),

  /// Mobile/cellular connection
  mobile('mobile'),

  /// Ethernet connection
  ethernet('ethernet'),

  /// Bluetooth connection
  bluetooth('bluetooth'),

  /// VPN connection
  vpn('vpn'),

  /// No connection
  none('none'),

  /// Unknown connection type
  unknown('unknown');

  const NetworkType(this.value);

  final String value;

  /// Convert from string value
  static NetworkType fromString(String value) {
    return NetworkType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NetworkType.unknown,
    );
  }
}

/// Device context collection interval constants
class DeviceContextIntervals {
  /// Cache interval for device context (5 minutes)
  static const Duration cacheInterval = Duration(minutes: 5);

  /// Refresh interval for periodic updates (24 hours)
  static const Duration refreshInterval = Duration(hours: 24);

  /// Session-based context update interval (once per session)
  static const Duration sessionInterval = Duration.zero;
}

/// Standard device context property keys
/// These match the Swift SDK property naming
class DeviceContextKeys {
  // Device information
  static const String deviceType = 'device_type';
  static const String operatingSystem = 'operating_system';
  static const String osVersion = 'os_version';
  static const String deviceModel = 'device_model';
  static const String deviceManufacturer = 'device_manufacturer';
  static const String deviceName = 'device_name';

  // App information
  static const String appVersion = 'app_version';
  static const String appBuild = 'app_build';
  static const String appBundleId = 'app_bundle_id';
  static const String appName = 'app_name';

  // Screen information
  static const String screenWidth = 'screen_width';
  static const String screenHeight = 'screen_height';
  static const String screenScale = 'screen_scale';
  static const String screenLogicalWidth = 'screen_logical_width';
  static const String screenLogicalHeight = 'screen_logical_height';
  static const String screenDensity = 'screen_density';

  // Memory information
  static const String memoryTotal = 'memory_total';
  static const String memoryAvailable = 'memory_available';

  // Storage information
  static const String storageTotal = 'storage_total';
  static const String storageAvailable = 'storage_available';

  // Network information
  static const String networkType = 'network_type';
  static const String networkConnected = 'network_connected';

  // Battery information
  static const String batteryLevel = 'battery_level';
  static const String batteryState = 'battery_state';

  // Locale and timezone
  static const String locale = 'locale';
  static const String timezone = 'timezone';
  static const String language = 'language';
  static const String country = 'country';

  // App state
  static const String appState = 'app_state';

  // System information
  static const String systemUptime = 'system_uptime';
  static const String isPhysicalDevice = 'is_physical_device';
  static const String isEmulator = 'is_emulator';

  // Performance metrics
  static const String cpuArchitecture = 'cpu_architecture';
  static const String processorCount = 'processor_count';
}
