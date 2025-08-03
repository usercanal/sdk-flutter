// Copyright © 2024 UserCanal. All rights reserved.

/// Properties system for UserCanal Flutter SDK
///
/// This module provides a type-safe property collection system that matches
/// the Swift SDK's Properties implementation, allowing for structured data
/// with type-safe access patterns.

import 'dart:convert';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import '../errors/user_canal_error.dart';
import '../core/constants.dart';

/// A type-safe property collection for events and logs
/// Equivalent to Swift SDK's Properties struct
@immutable
class Properties {
  const Properties._(this._storage);

  final Map<String, PropertyValue> _storage;

  /// Create empty properties
  const Properties() : _storage = const {};

  /// Create empty properties (static instance for default values)
  static const empty = Properties();

  /// Create properties from a dictionary
  factory Properties.fromMap(Map<String, dynamic> map) {
    final storage = <String, PropertyValue>{};
    for (final entry in map.entries) {
      try {
        storage[entry.key] = PropertyValue._fromDynamic(entry.value);
      } catch (e) {
        throw InvalidPropertyError(
          entry.key,
          'Failed to convert value: ${entry.value}',
        );
      }
    }
    return Properties._(storage);
  }

  /// Create properties from dictionary literal support
  factory Properties.from(Map<String, Object?> map) {
    final storage = <String, PropertyValue>{};
    for (final entry in map.entries) {
      try {
        storage[entry.key] = PropertyValue._fromDynamic(entry.value);
      } catch (e) {
        throw InvalidPropertyError(
          entry.key,
          'Failed to convert value: ${entry.value}',
        );
      }
    }
    return Properties._(storage);
  }

  // MARK: - Subscript Access

  /// Access properties by key
  Object? operator [](String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;
    final value = propertyValue.value;
    return value is PropertyNull ? null : value;
  }

  /// Check if property exists
  bool containsKey(String key) => _storage.containsKey(key);

  /// Get all property keys
  Iterable<String> get keys => _storage.keys;

  /// Get number of properties
  int get length => _storage.length;

  /// Check if properties is empty
  bool get isEmpty => _storage.isEmpty;

  /// Check if properties is not empty
  bool get isNotEmpty => _storage.isNotEmpty;

  // MARK: - Type-Safe Property Access

  /// Get a property value as a specific type
  T? value<T>(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is T) return value as T;

    // Try type coercion for common cases
    if (T == String) {
      return value.toString() as T?;
    }

    return null;
  }

  /// Get a string property
  String? string(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is String) return value;

    // Coerce to string
    return value.toString();
  }

  /// Get an integer property
  int? integer(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is int) return value;

    // Try coercion
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);

    return null;
  }

  /// Get a double property
  double? number(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is double) return value;

    // Try coercion
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return null;
  }

  /// Get a boolean property
  bool? boolean(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is bool) return value;

    // Try coercion
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is int) {
      return value != 0;
    }

    return null;
  }

  /// Get a date property
  DateTime? date(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is DateTime) return value;

    // Try coercion
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Get an array property
  List<T>? array<T>(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Get a map property
  Map<String, T>? map<T>(String key) {
    final propertyValue = _storage[key];
    if (propertyValue == null) return null;

    final value = propertyValue.value;
    if (value is PropertyNull) return null;
    if (value is Map) {
      try {
        return value.cast<String, T>();
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // MARK: - Modification (Returns New Instance)

  /// Add or update a property (returns new Properties instance)
  Properties withProperty(String key, Object? value) {
    final newStorage = Map<String, PropertyValue>.from(_storage);
    if (value == null) {
      newStorage.remove(key);
    } else {
      newStorage[key] = PropertyValue._fromDynamic(value);
    }
    return Properties._(newStorage);
  }

  /// Add multiple properties (returns new Properties instance)
  Properties withProperties(Map<String, Object?> properties) {
    final newStorage = Map<String, PropertyValue>.from(_storage);
    for (final entry in properties.entries) {
      if (entry.value == null) {
        newStorage.remove(entry.key);
      } else {
        newStorage[entry.key] = PropertyValue._fromDynamic(entry.value);
      }
    }
    return Properties._(newStorage);
  }

  /// Remove a property (returns new Properties instance)
  Properties without(String key) {
    if (!_storage.containsKey(key)) return this;

    final newStorage = Map<String, PropertyValue>.from(_storage);
    newStorage.remove(key);
    return Properties._(newStorage);
  }

  /// Remove multiple properties (returns new Properties instance)
  Properties withoutAll(Iterable<String> keys) {
    final newStorage = Map<String, PropertyValue>.from(_storage);
    for (final key in keys) {
      newStorage.remove(key);
    }
    return Properties._(newStorage);
  }

  // MARK: - Validation

  /// Validate all properties
  void validate() {
    for (final entry in _storage.entries) {
      _validatePropertyKey(entry.key);
      entry.value.validate();
    }
  }

  void _validatePropertyKey(String key) {
    if (key.isEmpty) {
      throw const InvalidPropertyError('property key', 'cannot be empty');
    }

    if (key.length > ValidationConstants.maxPropertyKeyLength) {
      throw InvalidPropertyError(
        key,
        'key too long (max ${ValidationConstants.maxPropertyKeyLength} characters)',
      );
    }

    if (!ValidationConstants.propertyKeyPattern.hasMatch(key)) {
      throw InvalidPropertyError(
        key,
        'key must start with letter/underscore and contain only alphanumeric/underscore',
      );
    }
  }

  // MARK: - Serialization

  /// Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    for (final entry in _storage.entries) {
      result[entry.key] = entry.value.toJson();
    }
    return result;
  }

  /// Convert to JSON string
  String toJson() => json.encode(toMap());

  /// Convert to bytes for transport
  Uint8List toBytes() {
    try {
      final jsonString = toJson();
      return Uint8List.fromList(utf8.encode(jsonString));
    } catch (e) {
      throw JsonSerializationError('properties serialization', e);
    }
  }

  // MARK: - Object Overrides

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Properties &&
          runtimeType == other.runtimeType &&
          _mapEquals(_storage, other._storage);

  @override
  int get hashCode => Object.hashAll(_storage.entries.map(
        (e) => Object.hash(e.key, e.value),
      ));

  @override
  String toString() {
    if (_storage.isEmpty) return 'Properties()';

    final entries = _storage.entries
        .take(3) // Show first 3 entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    final suffix = _storage.length > 3 ? ', ...' : '';
    return 'Properties($entries$suffix)';
  }

  /// Get debug description with all properties
  String get debugDescription {
    return 'Properties(${_storage.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
  }
}

/// Represents a type-safe property value
@immutable
class PropertyValue {
  const PropertyValue._(this.value, this.type);

  final Object value;
  final PropertyType type;

  /// Create from dynamic value
  factory PropertyValue._fromDynamic(Object? value) {
    if (value == null) {
      return const PropertyValue._(PropertyNull._instance, PropertyType.null_);
    }

    if (value is String) {
      if (value.length > ValidationConstants.maxPropertyValueLength) {
        throw InvalidPropertyError(
          'value',
          'string too long (max ${ValidationConstants.maxPropertyValueLength} characters)',
        );
      }
      return PropertyValue._(value, PropertyType.string);
    }

    if (value is int) {
      return PropertyValue._(value, PropertyType.integer);
    }

    if (value is double) {
      return PropertyValue._(value, PropertyType.number);
    }

    if (value is bool) {
      return PropertyValue._(value, PropertyType.boolean);
    }

    if (value is DateTime) {
      return PropertyValue._(value, PropertyType.date);
    }

    if (value is List) {
      // Validate list elements
      for (int i = 0; i < value.length; i++) {
        try {
          PropertyValue._fromDynamic(value[i]); // Validate each element
        } catch (e) {
          throw InvalidPropertyError('array[$i]', 'invalid array element: ${value[i]}');
        }
      }
      return PropertyValue._(value, PropertyType.array);
    }

    if (value is Map) {
      // Validate map entries
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw InvalidPropertyError('map key', 'map keys must be strings');
        }
        try {
          PropertyValue._fromDynamic(entry.value); // Validate each value
        } catch (e) {
          throw InvalidPropertyError('map[${entry.key}]', 'invalid map value: ${entry.value}');
        }
      }
      return PropertyValue._(value, PropertyType.map);
    }

    throw InvalidPropertyError('value', 'unsupported type: ${value.runtimeType}');
  }

  /// Validate this property value
  void validate() {
    switch (type) {
      case PropertyType.string:
        final str = value as String;
        if (str.length > ValidationConstants.maxPropertyValueLength) {
          throw InvalidPropertyError(
            'value',
            'string too long (max ${ValidationConstants.maxPropertyValueLength} characters)',
          );
        }
        break;
      case PropertyType.array:
        final list = value as List;
        if (list.length > 1000) { // Reasonable limit
          throw InvalidPropertyError('value', 'array too large (max 1000 elements)');
        }
        break;
      case PropertyType.map:
        final map = value as Map;
        if (map.length > 100) { // Reasonable limit
          throw InvalidPropertyError('value', 'map too large (max 100 entries)');
        }
        break;
      default:
        break;
    }
  }

  /// Convert to JSON-serializable value
  Object? toJson() {
    switch (type) {
      case PropertyType.null_:
        return null;
      case PropertyType.string:
      case PropertyType.integer:
      case PropertyType.number:
      case PropertyType.boolean:
        return value;
      case PropertyType.date:
        return (value as DateTime).toIso8601String();
      case PropertyType.array:
        final list = value as List;
        return list.map((item) => PropertyValue._fromDynamic(item).toJson()).toList();
      case PropertyType.map:
        final map = value as Map;
        final result = <String, dynamic>{};
        for (final entry in map.entries) {
          result[entry.key.toString()] = PropertyValue._fromDynamic(entry.value).toJson();
        }
        return result;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyValue &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() {
    switch (type) {
      case PropertyType.string:
        return '"$value"';
      case PropertyType.date:
        return (value as DateTime).toIso8601String();
      default:
        return value.toString();
    }
  }
}

/// Property value types
enum PropertyType {
  null_,
  string,
  integer,
  number,
  boolean,
  date,
  array,
  map,
}

/// Represents a null property value
class PropertyNull {
  const PropertyNull._();
  static const _instance = PropertyNull._();

  @override
  String toString() => 'null';
}

/// Properties builder for fluent API
class PropertiesBuilder {
  final Map<String, Object?> _properties = {};

  /// Add a string property
  PropertiesBuilder string(String key, String value) {
    _properties[key] = value;
    return this;
  }

  /// Add an integer property
  PropertiesBuilder integer(String key, int value) {
    _properties[key] = value;
    return this;
  }

  /// Add a number property
  PropertiesBuilder number(String key, double value) {
    _properties[key] = value;
    return this;
  }

  /// Add a boolean property
  PropertiesBuilder boolean(String key, bool value) {
    _properties[key] = value;
    return this;
  }

  /// Add a date property
  PropertiesBuilder date(String key, DateTime value) {
    _properties[key] = value;
    return this;
  }

  /// Add an array property
  PropertiesBuilder array(String key, List<Object?> value) {
    _properties[key] = value;
    return this;
  }

  /// Add a map property
  PropertiesBuilder map(String key, Map<String, Object?> value) {
    _properties[key] = value;
    return this;
  }

  /// Add a generic property
  PropertiesBuilder property(String key, Object? value) {
    _properties[key] = value;
    return this;
  }

  /// Add multiple properties
  PropertiesBuilder properties(Map<String, Object?> properties) {
    _properties.addAll(properties);
    return this;
  }

  /// Build the Properties instance
  Properties build() {
    return Properties.fromMap(_properties);
  }
}

// Utility functions
bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
