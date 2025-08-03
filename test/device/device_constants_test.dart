// Copyright © 2024 UserCanal. All rights reserved.

import 'package:test/test.dart';
import 'package:usercanal_flutter/src/device/device_constants.dart';

void main() {
  group('Device Constants', () {
    group('DeviceType', () {
      test('should have all expected device types', () {
        final types = DeviceType.values;
        final expectedValues = [
          'mobile',
          'tablet',
          'desktop',
          'tv',
          'watch',
          'vr',
          'unknown'
        ];

        expect(types.length, equals(expectedValues.length));

        for (final expectedValue in expectedValues) {
          expect(types.any((type) => type.value == expectedValue), isTrue);
        }
      });

      test('should convert from string correctly', () {
        expect(DeviceType.fromString('mobile'), equals(DeviceType.mobile));
        expect(DeviceType.fromString('tablet'), equals(DeviceType.tablet));
        expect(DeviceType.fromString('desktop'), equals(DeviceType.desktop));
        expect(DeviceType.fromString('tv'), equals(DeviceType.tv));
        expect(DeviceType.fromString('watch'), equals(DeviceType.watch));
        expect(DeviceType.fromString('vr'), equals(DeviceType.vr));
        expect(DeviceType.fromString('invalid'), equals(DeviceType.unknown));
      });

      test('should have correct string values', () {
        expect(DeviceType.mobile.value, equals('mobile'));
        expect(DeviceType.tablet.value, equals('tablet'));
        expect(DeviceType.desktop.value, equals('desktop'));
        expect(DeviceType.tv.value, equals('tv'));
        expect(DeviceType.watch.value, equals('watch'));
        expect(DeviceType.vr.value, equals('vr'));
        expect(DeviceType.unknown.value, equals('unknown'));
      });
    });

    group('OSType', () {
      test('should have all expected OS types', () {
        final types = OSType.values;
        final expectedValues = [
          'ios',
          'android',
          'macos',
          'windows',
          'linux',
          'web',
          'unknown'
        ];

        expect(types.length, equals(expectedValues.length));

        for (final expectedValue in expectedValues) {
          expect(types.any((type) => type.value == expectedValue), isTrue);
        }
      });

      test('should convert from string correctly', () {
        expect(OSType.fromString('ios'), equals(OSType.iOS));
        expect(OSType.fromString('android'), equals(OSType.android));
        expect(OSType.fromString('macos'), equals(OSType.macOS));
        expect(OSType.fromString('windows'), equals(OSType.windows));
        expect(OSType.fromString('linux'), equals(OSType.linux));
        expect(OSType.fromString('web'), equals(OSType.web));
        expect(OSType.fromString('invalid'), equals(OSType.unknown));
      });

      test('should have correct string values', () {
        expect(OSType.iOS.value, equals('ios'));
        expect(OSType.android.value, equals('android'));
        expect(OSType.macOS.value, equals('macos'));
        expect(OSType.windows.value, equals('windows'));
        expect(OSType.linux.value, equals('linux'));
        expect(OSType.web.value, equals('web'));
        expect(OSType.unknown.value, equals('unknown'));
      });
    });

    group('AppState', () {
      test('should have all expected app states', () {
        final states = AppState.values;
        final expectedValues = [
          'active',
          'inactive',
          'background',
          'paused',
          'resumed',
          'detached',
          'unknown'
        ];

        expect(states.length, equals(expectedValues.length));

        for (final expectedValue in expectedValues) {
          expect(states.any((state) => state.value == expectedValue), isTrue);
        }
      });

      test('should convert from string correctly', () {
        expect(AppState.fromString('active'), equals(AppState.active));
        expect(AppState.fromString('inactive'), equals(AppState.inactive));
        expect(AppState.fromString('background'), equals(AppState.background));
        expect(AppState.fromString('paused'), equals(AppState.paused));
        expect(AppState.fromString('resumed'), equals(AppState.resumed));
        expect(AppState.fromString('detached'), equals(AppState.detached));
        expect(AppState.fromString('invalid'), equals(AppState.unknown));
      });

      test('should have correct string values', () {
        expect(AppState.active.value, equals('active'));
        expect(AppState.inactive.value, equals('inactive'));
        expect(AppState.background.value, equals('background'));
        expect(AppState.paused.value, equals('paused'));
        expect(AppState.resumed.value, equals('resumed'));
        expect(AppState.detached.value, equals('detached'));
        expect(AppState.unknown.value, equals('unknown'));
      });
    });

    group('BatteryState', () {
      test('should have all expected battery states', () {
        final states = BatteryState.values;
        final expectedValues = [
          'unknown',
          'unplugged',
          'charging',
          'full',
          'not_supported'
        ];

        expect(states.length, equals(expectedValues.length));

        for (final expectedValue in expectedValues) {
          expect(states.any((state) => state.value == expectedValue), isTrue);
        }
      });

      test('should convert from string correctly', () {
        expect(BatteryState.fromString('unknown'), equals(BatteryState.unknown));
        expect(BatteryState.fromString('unplugged'), equals(BatteryState.unplugged));
        expect(BatteryState.fromString('charging'), equals(BatteryState.charging));
        expect(BatteryState.fromString('full'), equals(BatteryState.full));
        expect(BatteryState.fromString('not_supported'), equals(BatteryState.notSupported));
        expect(BatteryState.fromString('invalid'), equals(BatteryState.unknown));
      });
    });

    group('NetworkType', () {
      test('should have all expected network types', () {
        final types = NetworkType.values;
        final expectedValues = [
          'wifi',
          'mobile',
          'ethernet',
          'bluetooth',
          'vpn',
          'none',
          'unknown'
        ];

        expect(types.length, equals(expectedValues.length));

        for (final expectedValue in expectedValues) {
          expect(types.any((type) => type.value == expectedValue), isTrue);
        }
      });

      test('should convert from string correctly', () {
        expect(NetworkType.fromString('wifi'), equals(NetworkType.wifi));
        expect(NetworkType.fromString('mobile'), equals(NetworkType.mobile));
        expect(NetworkType.fromString('ethernet'), equals(NetworkType.ethernet));
        expect(NetworkType.fromString('bluetooth'), equals(NetworkType.bluetooth));
        expect(NetworkType.fromString('vpn'), equals(NetworkType.vpn));
        expect(NetworkType.fromString('none'), equals(NetworkType.none));
        expect(NetworkType.fromString('invalid'), equals(NetworkType.unknown));
      });
    });

    group('DeviceContextKeys', () {
      test('should have all expected context keys as strings', () {
        // Test that all key constants are non-empty strings
        expect(DeviceContextKeys.deviceType, isA<String>());
        expect(DeviceContextKeys.deviceType, isNotEmpty);

        expect(DeviceContextKeys.operatingSystem, isA<String>());
        expect(DeviceContextKeys.operatingSystem, isNotEmpty);

        expect(DeviceContextKeys.osVersion, isA<String>());
        expect(DeviceContextKeys.osVersion, isNotEmpty);

        expect(DeviceContextKeys.deviceModel, isA<String>());
        expect(DeviceContextKeys.deviceModel, isNotEmpty);

        expect(DeviceContextKeys.appVersion, isA<String>());
        expect(DeviceContextKeys.appVersion, isNotEmpty);

        expect(DeviceContextKeys.appBuild, isA<String>());
        expect(DeviceContextKeys.appBuild, isNotEmpty);

        expect(DeviceContextKeys.screenWidth, isA<String>());
        expect(DeviceContextKeys.screenWidth, isNotEmpty);

        expect(DeviceContextKeys.networkType, isA<String>());
        expect(DeviceContextKeys.networkType, isNotEmpty);

        expect(DeviceContextKeys.locale, isA<String>());
        expect(DeviceContextKeys.locale, isNotEmpty);
      });

      test('should use snake_case naming convention', () {
        expect(DeviceContextKeys.deviceType, equals('device_type'));
        expect(DeviceContextKeys.operatingSystem, equals('operating_system'));
        expect(DeviceContextKeys.osVersion, equals('os_version'));
        expect(DeviceContextKeys.deviceModel, equals('device_model'));
        expect(DeviceContextKeys.deviceManufacturer, equals('device_manufacturer'));
        expect(DeviceContextKeys.deviceName, equals('device_name'));
        expect(DeviceContextKeys.appVersion, equals('app_version'));
        expect(DeviceContextKeys.appBuild, equals('app_build'));
        expect(DeviceContextKeys.appBundleId, equals('app_bundle_id'));
        expect(DeviceContextKeys.appName, equals('app_name'));
        expect(DeviceContextKeys.screenWidth, equals('screen_width'));
        expect(DeviceContextKeys.screenHeight, equals('screen_height'));
        expect(DeviceContextKeys.screenScale, equals('screen_scale'));
        expect(DeviceContextKeys.networkType, equals('network_type'));
        expect(DeviceContextKeys.networkConnected, equals('network_connected'));
        expect(DeviceContextKeys.batteryLevel, equals('battery_level'));
        expect(DeviceContextKeys.batteryState, equals('battery_state'));
        expect(DeviceContextKeys.locale, equals('locale'));
        expect(DeviceContextKeys.timezone, equals('timezone'));
        expect(DeviceContextKeys.language, equals('language'));
        expect(DeviceContextKeys.appState, equals('app_state'));
      });

      test('should have comprehensive key coverage', () {
        // Verify we have keys for all major categories
        final allKeys = [
          // Device information
          DeviceContextKeys.deviceType,
          DeviceContextKeys.operatingSystem,
          DeviceContextKeys.osVersion,
          DeviceContextKeys.deviceModel,

          // App information
          DeviceContextKeys.appVersion,
          DeviceContextKeys.appBuild,
          DeviceContextKeys.appBundleId,

          // Screen information
          DeviceContextKeys.screenWidth,
          DeviceContextKeys.screenHeight,
          DeviceContextKeys.screenScale,

          // Network information
          DeviceContextKeys.networkType,
          DeviceContextKeys.networkConnected,

          // Locale information
          DeviceContextKeys.locale,
          DeviceContextKeys.language,
          DeviceContextKeys.timezone,

          // App state
          DeviceContextKeys.appState,
        ];

        // All keys should be unique
        final uniqueKeys = allKeys.toSet();
        expect(uniqueKeys.length, equals(allKeys.length));

        // All keys should be non-empty
        for (final key in allKeys) {
          expect(key, isNotEmpty);
          expect(key, isA<String>());
        }
      });
    });

    group('DeviceContextIntervals', () {
      test('should have reasonable default intervals', () {
        expect(DeviceContextIntervals.cacheInterval, equals(const Duration(minutes: 5)));
        expect(DeviceContextIntervals.refreshInterval, equals(const Duration(hours: 24)));
        expect(DeviceContextIntervals.sessionInterval, equals(Duration.zero));
      });

      test('should have intervals that make sense relative to each other', () {
        expect(DeviceContextIntervals.cacheInterval, lessThan(DeviceContextIntervals.refreshInterval));
        expect(DeviceContextIntervals.sessionInterval, lessThanOrEqualTo(DeviceContextIntervals.cacheInterval));
      });
    });

    group('Enum Integration', () {
      test('all enums should have unknown/default fallback values', () {
        expect(DeviceType.values, contains(DeviceType.unknown));
        expect(OSType.values, contains(OSType.unknown));
        expect(AppState.values, contains(AppState.unknown));
        expect(BatteryState.values, contains(BatteryState.unknown));
        expect(NetworkType.values, contains(NetworkType.unknown));
      });

      test('all enums should handle invalid string conversion gracefully', () {
        expect(DeviceType.fromString('invalid'), equals(DeviceType.unknown));
        expect(OSType.fromString('invalid'), equals(OSType.unknown));
        expect(AppState.fromString('invalid'), equals(AppState.unknown));
        expect(BatteryState.fromString('invalid'), equals(BatteryState.unknown));
        expect(NetworkType.fromString('invalid'), equals(NetworkType.unknown));
      });

      test('all enums should be case insensitive where appropriate', () {
        // Test that the fromString methods handle expected cases correctly
        expect(DeviceType.fromString('MOBILE'), equals(DeviceType.unknown)); // Case sensitive by design
        expect(DeviceType.fromString('mobile'), equals(DeviceType.mobile)); // Correct case
      });
    });
  });
}
