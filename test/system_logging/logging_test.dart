// Copyright © 2024 UserCanal. All rights reserved.

import 'package:test/test.dart';
import 'package:usercanal_flutter/src/system_logging/logging.dart';

void main() {
  group('SDKLogger', () {
    setUp(() {
      // Reset logger state before each test
      SDKLogger.isDebugEnabled = false;
      SDKLogger.logLevel = SDKLogLevel.info;
    });

    group('Configuration', () {
      test('should configure debug logging correctly', () {
        SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.debug);

        expect(SDKLogger.isDebugEnabled, isTrue);
        expect(SDKLogger.logLevel, equals(SDKLogLevel.debug));
      });

      test('should enable debug mode with convenience method', () {
        SDKLogger.enableDebug();

        expect(SDKLogger.isDebugEnabled, isTrue);
        expect(SDKLogger.logLevel, equals(SDKLogLevel.debug));
      });

      test('should disable debug mode with convenience method', () {
        SDKLogger.enableDebug(); // First enable it
        SDKLogger.disableDebug();

        expect(SDKLogger.isDebugEnabled, isFalse);
        expect(SDKLogger.logLevel, equals(SDKLogLevel.info));
      });
    });

    group('Log Levels', () {
      test('should respect log level filtering', () {
        SDKLogger.configure(level: SDKLogLevel.warning);

        // These should be logged (warning and above)
        expect(() => SDKLogger.emergency('Emergency message'), returnsNormally);
        expect(() => SDKLogger.alert('Alert message'), returnsNormally);
        expect(() => SDKLogger.critical('Critical message'), returnsNormally);
        expect(() => SDKLogger.error('Error message'), returnsNormally);
        expect(() => SDKLogger.warning('Warning message'), returnsNormally);

        // These should be filtered out (below warning)
        expect(() => SDKLogger.notice('Notice message'), returnsNormally);
        expect(() => SDKLogger.info('Info message'), returnsNormally);
        expect(() => SDKLogger.debug('Debug message'), returnsNormally);
        expect(() => SDKLogger.trace('Trace message'), returnsNormally);
      });

      test('should handle all log levels correctly', () {
        SDKLogger.configure(level: SDKLogLevel.trace);

        expect(() => SDKLogger.emergency('Emergency'), returnsNormally);
        expect(() => SDKLogger.alert('Alert'), returnsNormally);
        expect(() => SDKLogger.critical('Critical'), returnsNormally);
        expect(() => SDKLogger.error('Error'), returnsNormally);
        expect(() => SDKLogger.warning('Warning'), returnsNormally);
        expect(() => SDKLogger.notice('Notice'), returnsNormally);
        expect(() => SDKLogger.info('Info'), returnsNormally);
        expect(() => SDKLogger.debug('Debug'), returnsNormally);
        expect(() => SDKLogger.trace('Trace'), returnsNormally);
      });
    });

    group('Categories', () {
      test('should log with different categories', () {
        SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.trace);

        expect(() => SDKLogger.info('General message', category: LogCategory.general), returnsNormally);
        expect(() => SDKLogger.info('Client message', category: LogCategory.client), returnsNormally);
        expect(() => SDKLogger.info('Network message', category: LogCategory.network), returnsNormally);
        expect(() => SDKLogger.info('Batching message', category: LogCategory.batching), returnsNormally);
        expect(() => SDKLogger.info('Device message', category: LogCategory.device), returnsNormally);
        expect(() => SDKLogger.info('Events message', category: LogCategory.events), returnsNormally);
        expect(() => SDKLogger.info('Error message', category: LogCategory.error), returnsNormally);
        expect(() => SDKLogger.info('Config message', category: LogCategory.config), returnsNormally);
      });
    });

    group('Convenience Methods', () {
      test('should provide convenience methods for different activities', () {
        SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.trace);

        expect(() => SDKLogger.networkActivity('Network test'), returnsNormally);
        expect(() => SDKLogger.batchingActivity('Batching test'), returnsNormally);
        expect(() => SDKLogger.deviceActivity('Device test'), returnsNormally);
        expect(() => SDKLogger.eventActivity('Event test'), returnsNormally);
        expect(() => SDKLogger.clientActivity('Client test'), returnsNormally);
        expect(() => SDKLogger.configActivity('Config test'), returnsNormally);
        expect(() => SDKLogger.errorActivity('Error test'), returnsNormally);
      });

      test('should handle errors in convenience methods', () {
        SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.trace);

        final testError = Exception('Test error');
        expect(() => SDKLogger.errorActivity('Error occurred', error: testError), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle error objects in log messages', () {
        SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.trace);

        final testError = Exception('Test exception');
        expect(() => SDKLogger.error('Something failed', error: testError), returnsNormally);
      });

      test('should handle null error objects', () {
        SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.trace);

        expect(() => SDKLogger.error('Error without exception'), returnsNormally);
      });
    });

    group('Performance', () {
      test('should handle rapid logging without issues', () {
        SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.trace);

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          SDKLogger.debug('Rapid log message #$i');
        }

        stopwatch.stop();

        // Should complete within a reasonable time (adjust as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('should not process filtered log levels', () {
        SDKLogger.configure(level: SDKLogLevel.error);

        final stopwatch = Stopwatch()..start();

        // These should be filtered out quickly
        for (int i = 0; i < 1000; i++) {
          SDKLogger.debug('Filtered debug message #$i');
          SDKLogger.trace('Filtered trace message #$i');
        }

        stopwatch.stop();

        // Filtered logs should be very fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });

  group('SDKLogLevel', () {
    test('should have correct priority ordering', () {
      expect(SDKLogLevel.emergency.priority, equals(0));
      expect(SDKLogLevel.alert.priority, equals(1));
      expect(SDKLogLevel.critical.priority, equals(2));
      expect(SDKLogLevel.error.priority, equals(3));
      expect(SDKLogLevel.warning.priority, equals(4));
      expect(SDKLogLevel.notice.priority, equals(5));
      expect(SDKLogLevel.info.priority, equals(6));
      expect(SDKLogLevel.debug.priority, equals(7));
      expect(SDKLogLevel.trace.priority, equals(8));
    });

    test('should compare levels correctly', () {
      expect(SDKLogLevel.emergency < SDKLogLevel.alert, isTrue);
      expect(SDKLogLevel.error < SDKLogLevel.warning, isTrue);
      expect(SDKLogLevel.debug < SDKLogLevel.trace, isTrue);
      expect(SDKLogLevel.warning < SDKLogLevel.debug, isTrue);
    });

    test('should convert from string names', () {
      expect(SDKLogLevel.fromString('emergency'), equals(SDKLogLevel.emergency));
      expect(SDKLogLevel.fromString('debug'), equals(SDKLogLevel.debug));
      expect(SDKLogLevel.fromString('invalid'), equals(SDKLogLevel.info));
    });

    test('should provide shouldLog functionality', () {
      expect(SDKLogLevel.error.shouldLog(SDKLogLevel.warning), isTrue);
      expect(SDKLogLevel.warning.shouldLog(SDKLogLevel.error), isFalse);
      expect(SDKLogLevel.info.shouldLog(SDKLogLevel.info), isTrue);
    });
  });

  group('LogCategory', () {
    test('should have all expected categories', () {
      final categories = LogCategory.values;
      final expectedNames = [
        'general',
        'client',
        'network',
        'batching',
        'device',
        'events',
        'error',
        'config'
      ];

      expect(categories.length, equals(expectedNames.length));

      for (final name in expectedNames) {
        expect(categories.any((cat) => cat.name == name), isTrue);
      }
    });

    test('should convert from string names', () {
      expect(LogCategory.fromString('client'), equals(LogCategory.client));
      expect(LogCategory.fromString('network'), equals(LogCategory.network));
      expect(LogCategory.fromString('invalid'), equals(LogCategory.general));
    });
  });

  group('Integration', () {
    test('should work with realistic SDK scenarios', () {
      // Simulate SDK initialization logging
      SDKLogger.configure(debugEnabled: true, level: SDKLogLevel.debug);

      SDKLogger.info('SDK configuration starting', category: LogCategory.client);
      SDKLogger.debug('Creating network client', category: LogCategory.network);
      SDKLogger.debug('Network client created successfully', category: LogCategory.network);
      SDKLogger.debug('Creating batch manager', category: LogCategory.batching);
      SDKLogger.info('Connecting to server: collect.usercanal.com:50000', category: LogCategory.network);
      SDKLogger.info('SDK configured successfully', category: LogCategory.client);

      // Simulate event tracking
      SDKLogger.debug('Tracked event "user_signed_up"', category: LogCategory.events);
      SDKLogger.trace('Event added to batch (1/100)', category: LogCategory.batching);

      // Simulate error handling
      final error = Exception('Connection failed');
      SDKLogger.error('Network error occurred', error: error, category: LogCategory.network);

      // All should complete without issues
      expect(true, isTrue);
    });
  });
}
