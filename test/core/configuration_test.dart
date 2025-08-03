// Copyright © 2024 UserCanal. All rights reserved.

/// Configuration tests for UserCanal Flutter SDK
///
/// Tests for UserCanalConfig class including validation, presets,
/// and configuration management functionality.

import 'package:test/test.dart';
import '../../lib/src/core/configuration.dart';
import '../../lib/src/core/constants.dart';
import '../../lib/src/errors/user_canal_error.dart';

void main() {
  group('Configuration Tests', () {
    group('Basic Configuration', () {
      test('should create valid configuration with required parameters', () {
        final config = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
        );

        expect(config.apiKey, equals('a1b2c3d4e5f6789012345678901234ab'));
        expect(config.endpoint, equals('test.example.com'));
        expect(config.port, equals(50000)); // default port
        expect(config.batchSize, equals(50)); // default batch size
        expect(config.flushInterval, equals(const Duration(seconds: 30)));
        expect(config.enableDebugLogging, isFalse);
        expect(config.logLevel, equals(SystemLogLevel.info));
      });

      test('should create configuration with custom parameters', () {
        final config = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'custom.example.com',
          port: 51000,
          batchSize: 100,
          flushInterval: const Duration(minutes: 1),
          enableDebugLogging: true,
          logLevel: SystemLogLevel.debug,
        );

        expect(config.port, equals(51000));
        expect(config.batchSize, equals(100));
        expect(config.flushInterval, equals(const Duration(minutes: 1)));
        expect(config.enableDebugLogging, isTrue);
        expect(config.logLevel, equals(SystemLogLevel.debug));
      });

      test('should handle optional parameters correctly', () {
        final config = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
          maxRetries: 5,
          connectionTimeout: const Duration(seconds: 45),
        );

        expect(config.maxRetries, equals(5));
        expect(config.connectionTimeout, equals(const Duration(seconds: 45)));
      });
    });

    group('API Key Validation', () {
      test('should reject null API key', () {
        expect(
          () => UserCanalConfig(
            apiKey: null as dynamic,
            endpoint: 'test.example.com',
          ),
          throwsA(isA<TypeError>()),
        );
      });

      test('should reject empty API key', () {
        expect(
          () => UserCanalConfig(
            apiKey: '',
            endpoint: 'test.example.com',
          ),
          throwsA(isA<InvalidApiKeyError>()),
        );
      });

      test('should reject short API key', () {
        expect(
          () => UserCanalConfig(
            apiKey: 'short',
            endpoint: 'test.example.com',
          ),
          throwsA(isA<InvalidApiKeyError>()),
        );
      });

      test('should reject API key with invalid characters', () {
        expect(
          () => UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab!',
            endpoint: 'test.example.com',
          ),
          throwsA(isA<InvalidApiKeyError>()),
        );
      });

      test('should accept valid 32-character API key', () {
        final config = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
        );

        expect(config.apiKey, equals('a1b2c3d4e5f6789012345678901234ab'));
      });

      test('should reject 64-character API key', () {
        expect(
          () => UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab1234567890abcdef1234567890abcdef',
            endpoint: 'test.example.com',
          ),
          throwsA(isA<InvalidApiKeyError>()),
        );
      });
    });

    group('Endpoint Validation', () {
      test('should reject null endpoint', () {
        expect(
          () => UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: null as dynamic,
          ),
          throwsA(isA<TypeError>()),
        );
      });

      test('should reject empty endpoint', () {
        expect(
          () => UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: '',
          ),
          throwsA(isA<InvalidEndpointError>()),
        );
      });

      test('should accept valid hostnames', () {
        final testCases = [
          'example.com',
          'test.example.com',
          'collect.usercanal.com',
          '192.168.1.1',
          'localhost',
        ];

        for (final endpoint in testCases) {
          final config = UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: endpoint,
          );
          expect(config.endpoint, equals(endpoint));
        }
      });
    });

    group('Parameter Validation', () {
      test('should accept all valid port numbers', () {
        final validPorts = [1, 80, 443, 8080, 50000, 65535];

        for (final port in validPorts) {
          final config = UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: 'test.example.com',
            port: port,
          );
          expect(config.port, equals(port));
        }
      });

      test('should accept valid port numbers', () {
        final validPorts = [1, 80, 443, 8080, 50000, 65535];

        for (final port in validPorts) {
          final config = UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: 'test.example.com',
            port: port,
          );
          expect(config.port, equals(port));
        }
      });

      test('should reject invalid batch sizes', () {
        final invalidSizes = [0, -1, 10001];

        for (final size in invalidSizes) {
          expect(
            () => UserCanalConfig(
              apiKey: 'a1b2c3d4e5f6789012345678901234ab',
              endpoint: 'test.example.com',
              batchSize: size,
            ),
            throwsA(isA<ConfigurationError>()),
          );
        }
      });

      test('should accept valid batch sizes', () {
        final validSizes = [1, 10, 50, 100, 500, 1000, 10000];

        for (final size in validSizes) {
          final config = UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: 'test.example.com',
            batchSize: size,
          );
          expect(config.batchSize, equals(size));
        }
      });

      test('should reject invalid flush intervals', () {
        expect(
          () => UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: 'test.example.com',
            flushInterval: const Duration(seconds: 0),
          ),
          throwsA(isA<ConfigurationError>()),
        );

        expect(
          () => UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: 'test.example.com',
            flushInterval: const Duration(hours: 25),
          ),
          throwsA(isA<ConfigurationError>()),
        );
      });

      test('should accept valid flush intervals', () {
        final validIntervals = [
          const Duration(seconds: 1),
          const Duration(seconds: 30),
          const Duration(minutes: 1),
          const Duration(minutes: 10),
          const Duration(hours: 1),
        ];

        for (final interval in validIntervals) {
          final config = UserCanalConfig(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: 'test.example.com',
            flushInterval: interval,
          );
          expect(config.flushInterval, equals(interval));
        }
      });
    });

    group('Configuration Presets', () {
      test('should create development preset', () {
        final config = UserCanalConfig.development(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
        );

        expect(config.enableDebugLogging, isTrue);
        expect(config.logLevel, equals(SystemLogLevel.debug));
        expect(config.flushInterval, equals(const Duration(seconds: 2)));
        expect(config.batchSize, equals(10));
      });

      test('should create production preset', () {
        final config = UserCanalConfig.production(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'collect.usercanal.com',
        );

        expect(config.enableDebugLogging, isFalse);
        expect(config.endpoint, equals('collect.usercanal.com'));
      });

      test('should create privacy-first preset', () {
        final config = UserCanalConfig.privacyFirst(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'collect.usercanal.com',
        );

        expect(config.enableDebugLogging, isFalse);
        expect(config.endpoint, equals('collect.usercanal.com'));
      });

      test('should allow overriding preset values', () {
        final config = UserCanalConfig.development(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
        );

        expect(config.batchSize, equals(10)); // from preset
        expect(config.enableDebugLogging, isTrue); // from preset
        expect(config.logLevel, equals(SystemLogLevel.debug)); // from preset
      });
    });

    group('Configuration Comparison', () {
      test('should support equality comparison', () {
        final config1 = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
        );

        final config2 = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
        );

        final config3 = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'different.example.com',
        );

        expect(config1, equals(config2));
        expect(config1, isNot(equals(config3)));
      });

      test('should support hash code for sets and maps', () {
        final config1 = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
        );

        final config2 = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
        );

        expect(config1.hashCode, equals(config2.hashCode));

        final configSet = {config1};
        expect(configSet.contains(config2), isTrue);
      });
    });

    group('Configuration Serialization', () {
      test('should convert to string representation', () {
        final config = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
          port: 51000,
        );

        final configString = config.toString();
        expect(configString, contains('UserCanalConfig'));
        expect(configString, contains('test.example.com'));
        // API key should be masked in string representation
        expect(configString, isNot(contains('a1b2c3d4e5f6789012345678901234ab')));
      });

      test('should support configuration copying', () {
        final original = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
          port: 51000,
          enableDebugLogging: true,
        );

        final copy = original.copyWith(
          endpoint: 'new.example.com',
          port: 52000,
        );

        expect(copy.apiKey, equals(original.apiKey));
        expect(copy.endpoint, equals('new.example.com')); // changed
        expect(copy.port, equals(52000)); // changed
        expect(copy.enableDebugLogging, equals(original.enableDebugLogging)); // preserved
      });
    });
  });
}
