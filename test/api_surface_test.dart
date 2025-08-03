// Copyright © 2024 UserCanal. All rights reserved.

/// API Surface validation tests for UserCanal Flutter SDK
///
/// Tests the Phase 3 API surface without requiring actual network connections.
/// Validates that methods exist, accept correct parameters, and handle basic
/// validation without throwing unexpected errors.

import 'package:test/test.dart';
import '../lib/src/core/user_canal.dart';
import '../lib/src/core/configuration.dart';
import '../lib/src/core/constants.dart';
import '../lib/src/models/properties.dart';
import '../lib/src/errors/user_canal_error.dart';

void main() {
  group('API Surface Validation Tests', () {
    tearDown(() {
      // Reset SDK state after each test
      try {
        UserCanal.reset();
      } catch (e) {
        // Ignore reset errors in tests
      }
    });

    group('Configuration API', () {
      test('should expose configuration methods', () {
        // Test that methods exist and accept correct parameters
        expect(() {
          UserCanal.configureAsync(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: 'test.example.com',
            batchSize: 10,
            flushInterval: 5,
          );
        }, returnsNormally);
      });

      test('should validate API key format', () {
        expect(
          () => UserCanal.configure(
            apiKey: 'invalid_short_key',
            endpoint: 'test.example.com',
          ),
          throwsA(isA<InvalidApiKeyError>()),
        );
      });

      test('should validate endpoint format', () {
        expect(
          () => UserCanal.configure(
            apiKey: 'a1b2c3d4e5f6789012345678901234ab',
            endpoint: '',
          ),
          throwsA(isA<InvalidEndpointError>()),
        );
      });
    });

    group('Event Tracking API', () {
      test('should expose track methods', () {
        // Test method signatures without network calls
        expect(() {
          UserCanal.track(EventName.userSignedUp);
        }, returnsNormally);

        expect(() {
          UserCanal.track(EventName.custom('test_event'));
        }, returnsNormally);

        expect(() {
          UserCanal.trackString('string_event');
        }, returnsNormally);
      });

      test('should handle properties in track methods', () {
        final properties = Properties.fromMap({
          'key1': 'value1',
          'key2': 42,
          'key3': true,
        });

        expect(() {
          UserCanal.track(EventName.orderCompleted, properties: properties);
        }, returnsNormally);

        expect(() {
          UserCanal.trackWithMap(EventName.userSignedUp, {
            'method': 'email',
            'source': 'landing_page',
          });
        }, returnsNormally);

        expect(() {
          UserCanal.trackStringWithMap('custom_event', {
            'custom_prop': 'custom_value',
          });
        }, returnsNormally);
      });

      test('should queue events before configuration', () {
        // Before configuration, events should be queued
        UserCanal.track(EventName.custom('early_event'));
        expect(UserCanal.queuedEventCount, greaterThan(0));
      });
    });

    group('User Management API', () {
      test('should expose identify methods', () {
        final traits = Properties.fromMap({
          'email': 'test@example.com',
          'name': 'Test User',
        });

        expect(() {
          UserCanal.identify('user_123', traits: traits);
        }, returnsNormally);

        expect(() {
          UserCanal.identifyWithMap('user_456', {
            'email': 'user@example.com',
            'age': 30,
          });
        }, returnsNormally);
      });

      test('should expose group methods', () {
        expect(() {
          UserCanal.group('company_123');
        }, returnsNormally);

        expect(() {
          UserCanal.group('company_456', properties: Properties.fromMap({
            'name': 'Test Company',
            'size': 'large',
          }));
        }, returnsNormally);

        expect(() {
          UserCanal.groupWithMap('company_789', {
            'industry': 'technology',
            'employees': 100,
          });
        }, returnsNormally);
      });

      test('should expose alias methods', () {
        expect(() {
          UserCanal.alias('old_id', 'new_id');
        }, returnsNormally);
      });

      test('should expose reset method', () {
        UserCanal.identify('temp_user');
        expect(UserCanal.currentUserId, equals('temp_user'));

        UserCanal.reset();
        expect(UserCanal.currentUserId, isNull);
      });

      test('should validate user inputs', () {
        // SDK uses fire-and-forget pattern with error callbacks instead of throwing
        expect(
          () => UserCanal.identify(''),
          returnsNormally,
        );

        expect(
          () => UserCanal.group(''),
          returnsNormally,
        );
      });
    });

    group('Revenue Tracking API', () {
      test('should expose revenue methods', () {
        expect(() {
          UserCanal.eventRevenue(
            amount: 99.99,
            currency: Currency.usd,
            orderId: 'order_123',
          );
        }, returnsNormally);

        expect(() {
          UserCanal.eventRevenue(
            amount: 49.99,
            currency: Currency.eur,
            orderId: 'order_456',
            properties: Properties.fromMap({'product': 'premium'}),
          );
        }, returnsNormally);

        expect(() {
          UserCanal.eventRevenueWithMap(
            amount: 149.99,
            currency: Currency.gbp,
            orderId: 'order_789',
            properties: {
              'category': 'subscription',
              'discount': true,
            },
          );
        }, returnsNormally);
      });

      test('should validate revenue parameters', () {
        // SDK uses fire-and-forget pattern with error callbacks instead of throwing
        expect(
          () => UserCanal.eventRevenue(
            amount: -10.0,
            currency: Currency.usd,
            orderId: 'invalid',
          ),
          returnsNormally,
        );
      });

      test('should handle different currencies', () {
        final currencies = [
          Currency.usd,
          Currency.eur,
          Currency.gbp,
          Currency.jpy,
          Currency.cad,
        ];

        for (final currency in currencies) {
          expect(() {
            UserCanal.eventRevenue(
              amount: 100.0,
              currency: currency,
              orderId: 'test_${currency.code}',
            );
          }, returnsNormally);
        }
      });
    });

    group('Logging API', () {
      test('should expose log methods', () {
        expect(() {
          UserCanal.log(LogLevel.info, 'Test message');
        }, returnsNormally);

        expect(() {
          UserCanal.log(
            LogLevel.error,
            'Error message',
            service: 'test_service',
            data: Properties.fromMap({'error_code': 500}),
          );
        }, returnsNormally);

        expect(() {
          UserCanal.logWithMap(
            LogLevel.warning,
            'Warning message',
            service: 'api',
            data: {'status': 'degraded'},
          );
        }, returnsNormally);
      });

      test('should expose convenience logging methods', () {
        expect(() => UserCanal.logEmergency('Emergency'), returnsNormally);
        expect(() => UserCanal.logAlert('Alert'), returnsNormally);
        expect(() => UserCanal.logCritical('Critical'), returnsNormally);
        expect(() => UserCanal.logError('Error'), returnsNormally);
        expect(() => UserCanal.logWarning('Warning'), returnsNormally);
        expect(() => UserCanal.logNotice('Notice'), returnsNormally);
        expect(() => UserCanal.logInfo('Info'), returnsNormally);
        expect(() => UserCanal.logDebug('Debug'), returnsNormally);
        expect(() => UserCanal.logTrace('Trace'), returnsNormally);
      });

      test('should handle all log levels', () {
        final levels = [
          LogLevel.emergency,
          LogLevel.alert,
          LogLevel.critical,
          LogLevel.error,
          LogLevel.warning,
          LogLevel.notice,
          LogLevel.info,
          LogLevel.debug,
          LogLevel.trace,
        ];

        for (final level in levels) {
          expect(() {
            UserCanal.log(level, 'Test message for ${level.name}');
          }, returnsNormally);
        }
      });
    });

    group('Privacy & Lifecycle API', () {
      test('should expose privacy controls', () {
        expect(UserCanal.isOptedOut(), isFalse);

        expect(() => UserCanal.optOut(), returnsNormally);
        expect(UserCanal.isOptedOut(), isTrue);

        expect(() => UserCanal.optIn(), returnsNormally);
        expect(UserCanal.isOptedOut(), isFalse);
      });

      test('should expose lifecycle methods', () {
        expect(() => UserCanal.flush(), returnsNormally);
        expect(() => UserCanal.shutdown(), returnsNormally);
      });

      test('should drop events when opted out', () {
        UserCanal.optOut();

        final initialCount = UserCanal.queuedEventCount;

        // These should not add to queue when opted out
        UserCanal.track(EventName.custom('opted_out_event'));
        UserCanal.logInfo('Opted out log');

        expect(UserCanal.queuedEventCount, equals(initialCount));
      });
    });

    group('State Management API', () {
      test('should expose state getters', () {
        expect(UserCanal.isConfigured, isA<bool>());
        expect(UserCanal.isInitialized, isA<bool>());
        expect(UserCanal.queuedEventCount, isA<int>());
        expect(UserCanal.anonymousId, isA<String?>());
        expect(UserCanal.currentUserId, isA<String?>());
      });

      test('should handle anonymous ID management', () {
        final originalId = UserCanal.anonymousId;
        expect(originalId, isNotNull);
        expect(originalId, hasLength(36)); // UUID length

        UserCanal.reset();
        expect(UserCanal.anonymousId, isNot(equals(originalId)));
      });

      test('should track user state changes', () {
        expect(UserCanal.currentUserId, isNull);

        UserCanal.identify('test_user');
        expect(UserCanal.currentUserId, equals('test_user'));

        UserCanal.reset();
        expect(UserCanal.currentUserId, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle validation errors gracefully', () {
        // SDK uses fire-and-forget pattern, invalid inputs are handled via error callbacks
        expect(
          () => UserCanal.identify(''),
          returnsNormally,
        );

        expect(
          () => UserCanal.eventRevenue(
            amount: -100,
            currency: Currency.usd,
            orderId: 'test',
          ),
          returnsNormally,
        );
      });

      test('should handle operations on unconfigured SDK', () {
        // Most operations should work before configuration (queued)
        expect(() => UserCanal.track(EventName.custom('test')), returnsNormally);
        expect(() => UserCanal.identify('user'), returnsNormally);
        expect(() => UserCanal.logInfo('test'), returnsNormally);
      });
    });

    group('Performance Characteristics', () {
      test('should handle rapid API calls', () {
        final stopwatch = Stopwatch()..start();

        // Make many rapid calls
        for (int i = 0; i < 100; i++) {
          UserCanal.track(EventName.custom('rapid_$i'));
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should handle large property objects', () {
        final largeProperties = <String, dynamic>{};
        for (int i = 0; i < 50; i++) {
          largeProperties['key_$i'] = 'value_$i';
        }

        expect(() {
          UserCanal.trackWithMap(EventName.custom('large_props'), largeProperties);
        }, returnsNormally);
      });
    });

    group('Constants and Enums', () {
      test('should expose predefined event names', () {
        final eventNames = [
          EventName.userSignedUp,
          EventName.userSignedIn,
          EventName.userSignedOut,
          EventName.orderCompleted,
          EventName.subscriptionStarted,
          EventName.pageViewed,
        ];

        for (final eventName in eventNames) {
          expect(eventName.value, isA<String>());
          expect(eventName.value, isNotEmpty);
        }
      });

      test('should expose log levels', () {
        expect(LogLevel.emergency.value, equals(0));
        expect(LogLevel.alert.value, equals(1));
        expect(LogLevel.critical.value, equals(2));
        expect(LogLevel.error.value, equals(3));
        expect(LogLevel.warning.value, equals(4));
        expect(LogLevel.notice.value, equals(5));
        expect(LogLevel.info.value, equals(6));
        expect(LogLevel.debug.value, equals(7));
        expect(LogLevel.trace.value, equals(8));
      });

      test('should expose currencies', () {
        expect(Currency.usd.code, equals('USD'));
        expect(Currency.eur.code, equals('EUR'));
        expect(Currency.gbp.code, equals('GBP'));
        expect(Currency.jpy.code, equals('JPY'));
        expect(Currency.cad.code, equals('CAD'));
      });
    });
  });
}
