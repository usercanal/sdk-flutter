// Copyright © 2024 UserCanal. All rights reserved.

/// Integration tests for UserCanal Flutter SDK
///
/// These tests verify the end-to-end functionality of the SDK
/// including configuration, event tracking, and networking without
/// requiring a real server connection.

import 'package:test/test.dart';
import 'dart:typed_data';
import '../lib/src/core/configuration.dart';
import '../lib/src/core/constants.dart';
import '../lib/src/models/event.dart';
import '../lib/src/models/log_entry.dart';
import '../lib/src/models/properties.dart';
import '../lib/src/models/revenue.dart';
import '../lib/src/models/user_traits.dart';
import '../lib/src/networking/network_client.dart';
import '../lib/src/networking/batch_manager.dart';
import '../lib/src/errors/user_canal_error.dart';

void main() {
  group('UserCanal SDK Integration Tests', () {
    late UserCanalConfig testConfig;

    setUp(() {
      testConfig = UserCanalConfig(
        apiKey: 'a1b2c3d4e5f6789012345678901234ab',
        endpoint: 'test.usercanal.com',
        port: 50000,
        batchSize: 5,
        flushInterval: const Duration(seconds: 1),
      );
    });

    group('Configuration Integration', () {
      test('should create valid configuration with all presets', () {
        final devConfig = UserCanalConfig.development(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
        );
        expect(devConfig.enableDebugLogging, isTrue);
        expect(devConfig.validate, returnsNormally);

        final prodConfig = UserCanalConfig.production(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'prod.usercanal.com',
        );
        expect(prodConfig.enableDebugLogging, isFalse);
        expect(prodConfig.validate, returnsNormally);

        final privacyConfig = UserCanalConfig.privacyFirst(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'privacy.usercanal.com',
        );
        expect(privacyConfig.defaultOptOut, isTrue);
        expect(privacyConfig.validate, returnsNormally);
      });

      test('should validate complex configurations', () {
        final complexConfig = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'complex.usercanal.com',
          port: 8080,
          batchSize: 100,
          flushInterval: const Duration(seconds: 30),
          maxRetries: 5,
          connectionTimeout: const Duration(seconds: 60),
          enableDebugLogging: true,
          collectDeviceContext: true,
          enableOfflineStorage: true,
          maxOfflineEvents: 1000,
        );

        expect(() => complexConfig.validate(), returnsNormally);
      });
    });

    group('Data Model Integration', () {
      test('should create and validate complete event with all properties', () {
        final properties = Properties.fromMap({
          'user_name': 'John Doe',
          'user_age': 30,
          'user_active': true,
          'user_score': 95.5,
          'signup_method': 'email',
          'plan_type': 'premium',
          'referrer': 'google',
          'campaign_id': 'summer2024',
        });

        final event = Event(
          name: EventName.userSignedUp,
          userId: 'user_12345',
          eventType: EventType.track,
          properties: properties,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        expect(() => event.validate(), returnsNormally);
        expect(event.name, equals(EventName.userSignedUp));
        expect(event.userId, equals('user_12345'));
        expect(event.properties.string('user_name'), equals('John Doe'));
        expect(event.properties.integer('user_age'), equals(30));
        expect(event.properties.boolean('user_active'), isTrue);
        expect(event.properties.number('user_score'), equals(95.5));
      });

      test('should create and validate complex log entry', () {
        final logData = Properties.fromMap({
          'request_id': 'req_abc123',
          'user_id': 'user_456',
          'endpoint': '/api/users',
          'method': 'POST',
          'status_code': 201,
          'response_time_ms': 150,
          'user_agent': 'UserCanal Flutter SDK/1.0',
        });

        final logEntry = LogEntryModel(
          level: LogLevel.info,
          message: 'User registration successful',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          source: 'auth_service',
          service: 'user_management',
          data: logData,
        );

        expect(() => logEntry.validate(), returnsNormally);
        expect(logEntry.level, equals(LogLevel.info));
        expect(logEntry.message, equals('User registration successful'));
        expect(logEntry.data?.string('request_id'), equals('req_abc123'));
        expect(logEntry.data?.integer('status_code'), equals(201));
      });

      test('should create and validate revenue tracking', () {
        final revenueProperties = Properties.fromMap({
          'product_id': 'prod_premium_monthly',
          'product_name': 'Premium Plan - Monthly',
          'category': 'subscription',
          'discount_code': 'SUMMER20',
          'discount_amount': 9.99,
          'payment_method': 'credit_card',
          'billing_country': 'US',
        });

        final revenue = Revenue(
          amount: 39.99,
          currency: Currency.usd,
          orderId: 'order_789abc',
          productId: 'prod_premium_monthly',
          quantity: 1,
          properties: revenueProperties,
        );

        expect(() => revenue.validate(), returnsNormally);
        expect(revenue.amount, equals(39.99));
        expect(revenue.currency, equals(Currency.usd));
        expect(revenue.orderId, equals('order_789abc'));
        expect(revenue.properties?.string('product_name'), equals('Premium Plan - Monthly'));
      });

      test('should create and validate user traits', () {
        final traits = UserTraits(
          userId: 'user_12345',
          email: 'john.doe@example.com',
          name: 'John Doe',
          firstName: 'John',
          lastName: 'Doe',
          phone: '+1-555-123-4567',
          avatar: 'https://example.com/avatars/john.jpg',
          createdAt: DateTime.now(),
          customTraits: Properties.fromMap({
            'company': 'Acme Corp',
            'job_title': 'Senior Developer',
            'years_experience': 8,
            'preferred_language': 'en',
            'timezone': 'America/New_York',
            'plan_type': 'premium',
            'onboarding_completed': true,
          }),
        );

        expect(() => traits.validate(), returnsNormally);
        expect(traits.userId, equals('user_12345'));
        expect(traits.email, equals('john.doe@example.com'));
        expect(traits.customTraits?.string('company'), equals('Acme Corp'));
        expect(traits.customTraits?.integer('years_experience'), equals(8));
      });
    });

    group('Properties Advanced Integration', () {
      test('should handle complex nested properties', () {
        final complexProperties = Properties.fromMap({
          'user': {
            'id': 'user_123',
            'profile': {
              'name': 'John Doe',
              'preferences': {
                'theme': 'dark',
                'notifications': {
                  'email': true,
                  'push': false,
                  'sms': true,
                }
              }
            }
          },
          'session': {
            'id': 'session_456',
            'started_at': 1640995200000,
            'events_count': 15,
          },
          'app': {
            'version': '1.2.3',
            'platform': 'ios',
            'features': ['analytics', 'push_notifications', 'offline_sync'],
          }
        });

        expect(() => complexProperties.validate(), returnsNormally);
        expect(complexProperties.value('user'), isA<Map>());
        expect(complexProperties.value('session'), isA<Map>());
        expect(complexProperties.value('app'), isA<Map>());
      });

      test('should handle properties transformations', () {
        final original = Properties.fromMap({
          'name': 'John',
          'age': 30,
          'active': true,
        });

        final updated = original
            .withProperty('name', 'Jane')
            .withProperty('location', 'New York')
            .without('age');

        expect(original.string('name'), equals('John'));
        expect(original.containsKey('age'), isTrue);
        expect(original.containsKey('location'), isFalse);

        expect(updated.string('name'), equals('Jane'));
        expect(updated.containsKey('age'), isFalse);
        expect(updated.string('location'), equals('New York'));
      });
    });

    group('Networking Integration', () {
      test('should handle network client lifecycle', () async {
        var errorCount = 0;
        final errors = <UserCanalError>[];

        final client = NetworkClient(
          config: testConfig,
          onError: (error) {
            errorCount++;
            errors.add(error);
          },
        );

        expect(client.isConnected, isFalse);
        expect(client.isConnecting, isFalse);

        // Should fail to connect (no server running)
        try {
          await client.connect();
        } catch (e) {
          expect(e, isA<NetworkError>());
        }

        expect(errorCount, greaterThan(0));
        expect(errors, isNotEmpty);
        expect(errors.first, isA<ConnectionError>());

        // Should handle disconnect gracefully
        await client.disconnect();
        expect(client.isConnected, isFalse);
      });

      test('should handle data transmission errors gracefully', () async {
        final client = NetworkClient(
          config: testConfig,
          onError: (error) => print('Expected error: $error'),
        );

        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Should reject sending when not connected
        expect(
          () => client.send(testData),
          throwsA(isA<NetworkConnectivityError>()),
        );

        await client.disconnect();
      });

      test('should validate connection pooling', () {
        final client1 = NetworkClient.getPooledConnection(
          config: testConfig,
          onError: (error) => print('Pool error: $error'),
        );

        final client2 = NetworkClient.getPooledConnection(
          config: testConfig,
          onError: (error) => print('Pool error: $error'),
        );

        // Same config should return same client
        expect(client1, same(client2));

        final differentConfig = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'different.usercanal.com',
          port: 50001,
        );

        final client3 = NetworkClient.getPooledConnection(
          config: differentConfig,
          onError: (error) => print('Pool error: $error'),
        );

        // Different config should return different client
        expect(client1, isNot(same(client3)));
      });
    });

    group('Batch Management Integration', () {
      test('should create and manage batches', () {
        final networkClient = NetworkClient(
          config: testConfig,
          onError: (error) => print('Network error: $error'),
        );

        final batchManager = BatchManager(
          config: testConfig,
          networkClient: networkClient,
          onError: (error) => print('Batch error: $error'),
        );

        expect(batchManager.eventBatchSize, equals(0));
        expect(batchManager.logBatchSize, equals(0));

        // Add events to batch
        final event1 = Event(
          name: EventName.custom('test_event_1'),
          userId: 'user_123',
          eventType: EventType.track,
          properties: Properties.fromMap({'key': 'value1'}),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        final event2 = Event(
          name: EventName.custom('test_event_2'),
          userId: 'user_123',
          eventType: EventType.track,
          properties: Properties.fromMap({'key': 'value2'}),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        batchManager.addEvent(event1);
        batchManager.addEvent(event2);

        expect(batchManager.eventBatchSize, equals(2));

        // Add logs to batch
        final log1 = LogEntryModel.info('Test log message 1');
        final log2 = LogEntryModel.error('Test log message 2');

        batchManager.addLogEntry(log1);
        batchManager.addLogEntry(log2);

        expect(batchManager.logBatchSize, equals(2));
      });

      test('should handle batch size limits', () {
        final smallBatchConfig = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.usercanal.com',
          batchSize: 2,
        );

        final networkClient = NetworkClient(
          config: smallBatchConfig,
          onError: (error) => print('Network error: $error'),
        );

        final batchManager = BatchManager(
          config: smallBatchConfig,
          networkClient: networkClient,
          onError: (error) => print('Batch error: $error'),
        );

        // Add events up to batch size
        for (int i = 0; i < 3; i++) {
          final event = Event(
            name: EventName.custom('test_event_$i'),
            userId: 'user_123',
            eventType: EventType.track,
            properties: Properties.fromMap({'index': i}),
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          batchManager.addEvent(event);
        }

        // Should handle batch size limits appropriately
        expect(batchManager.eventBatchSize, lessThanOrEqualTo(smallBatchConfig.batchSize));
      });
    });

    group('Error Handling Integration', () {
      test('should handle cascade of errors gracefully', () {
        final errors = <UserCanalError>[];

        final invalidConfig = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'invalid.nonexistent.domain.test.12345',
          port: 99999, // Invalid port that might cause issues
          connectionTimeout: const Duration(milliseconds: 100),
        );

        final client = NetworkClient(
          config: invalidConfig,
          onError: (error) => errors.add(error),
        );

        final networkClient = NetworkClient(
          config: invalidConfig,
          onError: (error) => errors.add(error),
        );

        final batchManager = BatchManager(
          config: invalidConfig,
          networkClient: networkClient,
          onError: (error) => errors.add(error),
        );

        // Try operations that should fail
        expect(() => client.connect(), throwsA(isA<NetworkError>()));

        // Add some data to batch manager
        final event = Event(
          name: EventName.custom('test_event'),
          userId: 'user_123',
          eventType: EventType.track,
          properties: Properties.empty,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        batchManager.addEvent(event);

        // Should have collected errors
        expect(errors, isNotEmpty);
        expect(errors.any((e) => e is NetworkError), isTrue);
      });

      test('should validate all error types exist', () {
        // Configuration errors
        expect(() => throw const InvalidApiKeyError('test'), throwsA(isA<ConfigurationError>()));
        expect(() => throw const InvalidEndpointError('test'), throwsA(isA<ConfigurationError>()));

        // Network errors
        expect(() => throw const ConnectionError('test'), throwsA(isA<NetworkError>()));
        expect(() => throw const NetworkConnectivityError(), throwsA(isA<NetworkError>()));

        // Validation errors
        expect(() => throw const InvalidPropertyError('test', 'test'), throwsA(isA<ValidationError>()));
        expect(() => throw const InvalidPropertyError('test', 'test'), throwsA(isA<ValidationError>()));

        // All should be UserCanalError
        expect(() => throw const InvalidApiKeyError('test'), throwsA(isA<UserCanalError>()));
        expect(() => throw const ConnectionError('test'), throwsA(isA<UserCanalError>()));
        expect(() => throw const InvalidPropertyError('test', 'test'), throwsA(isA<UserCanalError>()));
      });
    });

    group('Performance Integration', () {
      test('should handle large property collections efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Create large property collection
        final largeMap = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeMap['property_$i'] = {
            'string_value': 'test_string_$i',
            'number_value': i * 1.5,
            'boolean_value': i % 2 == 0,
            'nested': {
              'inner_value': 'inner_$i',
              'inner_number': i,
            }
          };
        }

        final properties = Properties.fromMap(largeMap);
        stopwatch.stop();

        expect(properties.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast

        // Test property access performance
        stopwatch.reset();
        stopwatch.start();

        for (int i = 0; i < 100; i++) {
          final value = properties.value('property_$i');
          expect(value, isNotNull);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be very fast
      });

      test('should handle rapid event creation', () {
        final events = <Event>[];
        final stopwatch = Stopwatch()..start();

        // Create many events rapidly
        for (int i = 0; i < 100; i++) {
          final event = Event(
            name: EventName.custom('rapid_event_$i'),
            userId: 'user_$i',
            eventType: EventType.track,
            properties: Properties.fromMap({
              'index': i,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'batch': 'performance_test',
            }),
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          events.add(event);
        }

        stopwatch.stop();

        expect(events, hasLength(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should create quickly

        // Validate all events
        final validationStopwatch = Stopwatch()..start();
        for (final event in events) {
          expect(() => event.validate(), returnsNormally);
        }
        validationStopwatch.stop();

        expect(validationStopwatch.elapsedMilliseconds, lessThan(50)); // Validation should be fast
      });
    });
  });
}
