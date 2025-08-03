// Copyright © 2024 UserCanal. All rights reserved.

/// Basic Properties model tests for UserCanal Flutter SDK
///
/// Simple tests for the Properties class focusing on core functionality
/// that we know exists in the implementation.

import 'package:test/test.dart';
import '../../lib/src/models/properties.dart';

void main() {
  group('Properties Basic Tests', () {
    group('Construction', () {
      test('should create empty properties', () {
        const properties = Properties();

        expect(properties.isEmpty, isTrue);
        expect(properties.isNotEmpty, isFalse);
        expect(properties.length, equals(0));
      });

      test('should create properties from map', () {
        final properties = Properties.fromMap({
          'string_prop': 'hello',
          'int_prop': 42,
          'bool_prop': true,
        });

        expect(properties.length, equals(3));
        expect(properties.isNotEmpty, isTrue);
      });

      test('should create empty properties constant', () {
        const properties = Properties.empty;

        expect(properties.isEmpty, isTrue);
        expect(properties.length, equals(0));
      });
    });

    group('Type-Safe Access', () {
      late Properties properties;

      setUp(() {
        properties = Properties.fromMap({
          'name': 'John',
          'age': 30,
          'active': true,
          'score': 95.5,
          'null_value': null,
        });
      });

      test('should access string values', () {
        expect(properties.string('name'), equals('John'));
        expect(properties.string('nonexistent'), isNull);
        expect(properties.string('null_value'), isNull);
      });

      test('should access integer values', () {
        expect(properties.integer('age'), equals(30));
        expect(properties.integer('nonexistent'), isNull);
      });

      test('should access boolean values', () {
        expect(properties.boolean('active'), isTrue);
        expect(properties.boolean('nonexistent'), isNull);
      });

      test('should access number values', () {
        expect(properties.number('score'), equals(95.5));
        expect(properties.number('nonexistent'), isNull);
      });

      test('should check property existence', () {
        expect(properties.containsKey('name'), isTrue);
        expect(properties.containsKey('null_value'), isTrue);
        expect(properties.containsKey('nonexistent'), isFalse);
      });
    });

    group('Immutable Operations', () {
      test('should add property immutably', () {
        final original = Properties.fromMap({'key1': 'value1'});
        final modified = original.withProperty('key2', 'value2');

        expect(original.length, equals(1));
        expect(modified.length, equals(2));
        expect(modified.string('key1'), equals('value1'));
        expect(modified.string('key2'), equals('value2'));
      });

      test('should update existing property immutably', () {
        final original = Properties.fromMap({'key1': 'value1'});
        final modified = original.withProperty('key1', 'new_value');

        expect(original.string('key1'), equals('value1'));
        expect(modified.string('key1'), equals('new_value'));
        expect(modified.length, equals(1));
      });

      test('should remove property immutably', () {
        final original = Properties.fromMap({
          'key1': 'value1',
          'key2': 'value2',
        });

        final modified = original.without('key1');

        expect(original.length, equals(2));
        expect(modified.length, equals(1));
        expect(modified.containsKey('key1'), isFalse);
        expect(modified.string('key2'), equals('value2'));
      });
    });

    group('Serialization', () {
      test('should convert to map', () {
        final originalMap = {
          'string': 'hello',
          'number': 42,
          'boolean': true,
        };

        final properties = Properties.fromMap(originalMap);
        final convertedMap = properties.toMap();

        expect(convertedMap['string'], equals('hello'));
        expect(convertedMap['number'], equals(42));
        expect(convertedMap['boolean'], isTrue);
      });
    });

    group('Equality', () {
      test('should support equality comparison', () {
        final props1 = Properties.fromMap({
          'key1': 'value1',
          'key2': 42,
        });

        final props2 = Properties.fromMap({
          'key1': 'value1',
          'key2': 42,
        });

        final props3 = Properties.fromMap({
          'key1': 'value1',
          'key2': 43,
        });

        expect(props1, equals(props2));
        expect(props1, isNot(equals(props3)));
      });
    });
  });
}
