// Copyright © 2024 UserCanal. All rights reserved.

/// Minimal NetworkClient tests for UserCanal Flutter SDK
///
/// Simple tests that focus on what we can actually test without
/// real network connections or mocked dependencies.

import 'package:test/test.dart';
import 'dart:typed_data';
import '../../lib/src/networking/network_client.dart';
import '../../lib/src/core/configuration.dart';
import '../../lib/src/errors/user_canal_error.dart';

void main() {
  group('NetworkClient Minimal Tests', () {
    late UserCanalConfig testConfig;

    setUp(() {
      testConfig = UserCanalConfig(
        apiKey: 'a1b2c3d4e5f6789012345678901234ab',
        endpoint: 'test.example.com',
        port: 50000,
      );
    });

    group('Configuration', () {
      test('should accept valid configuration', () {
        expect(
          () => NetworkClient(
            config: testConfig,
            onError: (error) => print('Test error: $error'),
          ),
          returnsNormally,
        );
      });

      test('should require configuration', () {
        expect(
          () => NetworkClient(
            config: null as dynamic,
            onError: (error) => print(error),
          ),
          throwsA(isA<TypeError>()),
        );
      });

      test('should require error callback', () {
        expect(
          () => NetworkClient(
            config: testConfig,
            onError: null as dynamic,
          ),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('Basic API Surface', () {
      test('should expose expected interface', () {
        final client = NetworkClient(
          config: testConfig,
          onError: (error) => print('Test error: $error'),
        );

        // Should have basic properties
        expect(client.config, isA<UserCanalConfig>());
        expect(client.isConnected, isA<bool>());
        expect(client.isConnecting, isA<bool>());

        // Should have basic methods
        expect(client.connect, isA<Function>());
        expect(client.disconnect, isA<Function>());
        expect(client.send, isA<Function>());

        // Should have streams
        expect(client.incomingData, isA<Stream<Uint8List>>());
        expect(client.connectionStatus, isA<Stream<bool>>());
      });

      test('should start in disconnected state', () {
        final client = NetworkClient(
          config: testConfig,
          onError: (error) => print('Test error: $error'),
        );

        expect(client.isConnected, isFalse);
        expect(client.isConnecting, isFalse);
      });
    });

    group('Data Validation', () {
      test('should reject sending data when not connected', () async {
        final client = NetworkClient(
          config: testConfig,
          onError: (error) => print('Test error: $error'),
        );

        final data = Uint8List.fromList([1, 2, 3, 4]);

        expect(
          () => client.send(data),
          throwsA(isA<NetworkConnectivityError>()),
        );
      });

      test('should handle empty data', () async {
        final client = NetworkClient(
          config: testConfig,
          onError: (error) => print('Test error: $error'),
        );

        final emptyData = Uint8List(0);

        expect(
          () => client.send(emptyData),
          throwsA(isA<NetworkConnectivityError>()),
        );
      });
    });

    group('Error Handling', () {
      test('should call error callback on connection failures', () async {
        var errorCalled = false;
        UserCanalError? capturedError;

        final client = NetworkClient(
          config: testConfig,
          onError: (error) {
            errorCalled = true;
            capturedError = error;
          },
        );

        try {
          await client.connect();
        } catch (e) {
          // Expected to fail in test environment
        }

        expect(errorCalled, isTrue);
        expect(capturedError, isA<UserCanalError>());
      });

      test('should handle invalid endpoints', () async {
        final invalidConfig = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'invalid.nonexistent.domain.test',
          port: 50000,
        );

        final client = NetworkClient(
          config: invalidConfig,
          onError: (error) => print('Expected error: $error'),
        );

        expect(
          () => client.connect(),
          throwsA(isA<NetworkError>()),
        );
      });
    });

    group('Connection Pool', () {
      test('should support pooled connections', () {
        final client1 = NetworkClient.getPooledConnection(
          config: testConfig,
          onError: (error) => print('Pool error: $error'),
        );

        final client2 = NetworkClient.getPooledConnection(
          config: testConfig,
          onError: (error) => print('Pool error: $error'),
        );

        // Should return the same instance for same config
        expect(client1, same(client2));
      });

      test('should create different clients for different configs', () {
        final config1 = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'server1.example.com',
          port: 50000,
        );

        final config2 = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'server2.example.com',
          port: 50000,
        );

        final client1 = NetworkClient.getPooledConnection(
          config: config1,
          onError: (error) => print('Pool error: $error'),
        );

        final client2 = NetworkClient.getPooledConnection(
          config: config2,
          onError: (error) => print('Pool error: $error'),
        );

        // Should be different instances
        expect(client1, isNot(same(client2)));
      });
    });
  });
}
