// Copyright © 2024 UserCanal. All rights reserved.

/// Simple working test for UserCanal Flutter SDK
///
/// This test verifies core functionality that actually exists in the SDK
/// without testing methods that haven't been implemented yet.

import 'package:test/test.dart';
import '../lib/src/core/configuration.dart';
import '../lib/src/core/constants.dart';
import '../lib/src/errors/user_canal_error.dart';
import '../lib/src/models/event.dart';
import '../lib/src/models/log_entry.dart';
import '../lib/src/models/revenue.dart';
import '../lib/src/models/user_traits.dart';
import '../lib/src/models/properties.dart';

void main() {
  group('UserCanal Flutter SDK - Simple Tests', () {
    group('Configuration Tests', () {
      test('should create valid configuration', () {
        final config = UserCanalConfig(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
          endpoint: 'test.example.com',
        );

        expect(config.apiKey, equals('a1b2c3d4e5f6789012345678901234ab'));
        expect(config.endpoint, equals('test.example.com'));
        expect(config.port, equals(50000));
        expect(config.batchSize, equals(50));
      });

      test('should validate API key', () {
        expect(
          () => UserCanalConfig(
            apiKey: 'short',
            endpoint: 'test.example.com',
          ),
          throwsA(isA<InvalidApiKeyError>()),
        );
      });

      test('should create development preset', () {
        final config = UserCanalConfig.development(
          apiKey: 'a1b2c3d4e5f6789012345678901234ab',
        );

        expect(config.enableDebugLogging, isTrue);
        expect(config.logLevel, equals(SystemLogLevel.debug));
      });
    });

    group('Properties Tests', () {
      test('should create empty properties', () {
        const properties = Properties();
        expect(properties.isEmpty, isTrue);
        expect(properties.length, equals(0));
      });

      test('should create properties from map', () {
        final properties = Properties.fromMap({
          'string_prop': 'hello',
          'int_prop': 42,
          'bool_prop': true,
        });

        expect(properties.length, equals(3));
        expect(properties.string('string_prop'), equals('hello'));
        expect(properties.integer('int_prop'), equals(42));
        expect(properties.boolean('bool_prop'), isTrue);
      });

      test('should handle type-safe access', () {
        final properties = Properties.fromMap({
          'name': 'John',
          'age': 30,
          'active': true,
        });

        expect(properties.string('name'), equals('John'));
        expect(properties.integer('age'), equals(30));
        expect(properties.boolean('active'), isTrue);
        expect(properties.string('nonexistent'), isNull);
      });

      test('should support immutable operations', () {
        final original = Properties.fromMap({'key1': 'value1'});
        final modified = original.withProperty('key2', 'value2');

        expect(original.length, equals(1));
        expect(modified.length, equals(2));
        expect(modified.string('key2'), equals('value2'));
      });
    });

    group('Event Tests', () {
      test('should create valid event', () {
        final event = Event(
          name: EventName.custom('test_event'),
          userId: 'user123',
          eventType: EventType.track,
          properties: Properties.fromMap({'key': 'value'}),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        expect(event.name.value, equals('test_event'));
        expect(event.userId, equals('user123'));
        expect(event.eventType, equals(EventType.track));
        expect(event.properties.string('key'), equals('value'));
      });

      test('should validate event data', () {
        final event = Event(
          name: EventName.custom('valid_event'),
          userId: 'user123',
          eventType: EventType.track,
          properties: Properties.empty,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        expect(() => event.validate(), returnsNormally);
      });

      test('should use event builder', () {
        final event = EventBuilder()
            .name(EventName.userSignedUp)
            .userId('user123')
            .eventType(EventType.track)
            .property('method', 'email')
            .build();

        expect(event.name, equals(EventName.userSignedUp));
        expect(event.userId, equals('user123'));
        expect(event.properties.string('method'), equals('email'));
      });
    });

    group('Log Entry Tests', () {
      test('should create valid log entry', () {
        final logEntry = LogEntryModel(
          level: LogLevel.info,
          message: 'Test message',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          source: 'test',
          service: 'app',
          data: Properties.fromMap({'key': 'value'}),
        );

        expect(logEntry.level, equals(LogLevel.info));
        expect(logEntry.message, equals('Test message'));
        expect(logEntry.source, equals('test'));
        expect(logEntry.service, equals('app'));
      });

      test('should create log with factory methods', () {
        final infoLog = LogEntryModel.info('Info message');
        final errorLog = LogEntryModel.error('Error message');

        expect(infoLog.level, equals(LogLevel.info));
        expect(infoLog.message, equals('Info message'));
        expect(errorLog.level, equals(LogLevel.error));
        expect(errorLog.message, equals('Error message'));
      });

      test('should validate log entry', () {
        final logEntry = LogEntryModel(
          level: LogLevel.info,
          message: 'Valid message',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          source: 'test',
          service: 'app',
          data: Properties.empty,
        );

        expect(() => logEntry.validate(), returnsNormally);
      });
    });

    group('Revenue Tests', () {
      test('should create basic revenue', () {
        final revenue = Revenue(
          amount: 99.99,
          currency: Currency.usd,
          orderId: 'order123',
        );

        expect(revenue.amount, equals(99.99));
        expect(revenue.currency, equals(Currency.usd));
        expect(revenue.orderId, equals('order123'));
      });

      test('should validate revenue', () {
        final revenue = Revenue(
          amount: 99.99,
          currency: Currency.usd,
          orderId: 'order123',
        );

        expect(() => revenue.validate(), returnsNormally);
      });

      test('should use revenue builder', () {
        final revenue = RevenueBuilder()
            .amount(149.99)
            .currency(Currency.eur)
            .orderId('order_builder')
            .build();

        expect(revenue.amount, equals(149.99));
        expect(revenue.currency, equals(Currency.eur));
        expect(revenue.orderId, equals('order_builder'));
      });
    });

    group('User Traits Tests', () {
      test('should create basic user traits', () {
        final traits = UserTraits(
          userId: 'user123',
          email: 'user@example.com',
          name: 'Test User',
        );

        expect(traits.userId, equals('user123'));
        expect(traits.email, equals('user@example.com'));
        expect(traits.name, equals('Test User'));
      });

      test('should create traits from map', () {
        final traits = UserTraits.fromMap({
          'user_id': 'user123',
          'email': 'user@example.com',
          'name': 'Test User',
          'custom_field': 'custom_value',
        });

        expect(traits.userId, equals('user123'));
        expect(traits.email, equals('user@example.com'));
        expect(traits.name, equals('Test User'));
      });

      test('should validate user traits', () {
        final traits = UserTraits(
          userId: 'user123',
          email: 'valid@example.com',
          name: 'Valid User',
        );

        expect(() => traits.validate(), returnsNormally);
      });
    });

    group('Error Handling Tests', () {
      test('should create configuration errors', () {
        const error = InvalidApiKeyError('Invalid API key');

        expect(error.code, equals('INVALID_API_KEY'));
        expect(error.message, equals('Invalid API key'));
        expect(error, isA<ConfigurationError>());
      });

      test('should create network errors', () {
        const connectionError = ConnectionError('server.com');
        const timeoutError = ConnectionTimeoutError(Duration(seconds: 30));

        expect(connectionError.code, equals('CONNECTION_ERROR'));
        expect(connectionError, isA<NetworkError>());
        expect(timeoutError.code, equals('CONNECTION_TIMEOUT'));
        expect(timeoutError, isA<NetworkError>());
      });

      test('should convert exceptions', () {
        final argumentError = ArgumentError('Invalid argument');
        final converted = ErrorUtils.fromException(argumentError);

        expect(converted, isA<ValidationError>());
        expect(converted.message, contains('Invalid argument'));
      });
    });

    group('Constants Tests', () {
      test('should have predefined event names', () {
        expect(EventName.userSignedUp.value, equals('User Signed Up'));
        expect(EventName.userSignedIn.value, equals('User Signed In'));
        expect(EventName.orderCompleted.value, equals('Order Completed'));
      });

      test('should have log levels', () {
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

      test('should have currencies', () {
        expect(Currency.usd.code, equals('USD'));
        expect(Currency.usd.symbol, equals('\$'));
        expect(Currency.eur.code, equals('EUR'));
        expect(Currency.eur.symbol, equals('€'));
      });
    });
  });
}
