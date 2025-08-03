// Copyright © 2024 UserCanal. All rights reserved.

/// Core event data model for UserCanal Flutter SDK
///
/// This module defines the event data structures used throughout the SDK,
/// including event properties, metadata, and serialization helpers.
/// Updated to match Swift SDK design with String user IDs and Properties system.

import 'dart:convert';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../errors/user_canal_error.dart';
import 'properties.dart';

/// Core event class representing a user action or system event
@immutable
class Event {
  const Event({
    required this.name,
    required this.timestamp,
    required this.eventType,
    required this.userId,
    this.properties = Properties.empty,
    this.eventId,
    this.sessionId,
    this.messageId,
  });

  /// Event name (can be predefined or custom)
  final EventName name;

  /// Unix timestamp in milliseconds
  final int timestamp;

  /// Event type for processing routing
  final EventType eventType;

  /// User identifier (string, converted to bytes at protocol level)
  final String userId;

  /// Event properties (type-safe Properties object)
  final Properties properties;

  /// Optional client-side event ID
  final String? eventId;

  /// Optional session identifier
  final String? sessionId;

  /// Optional message identifier for correlation
  final String? messageId;

  /// Create a track event
  factory Event.track({
    required EventName name,
    required String userId,
    Properties properties = Properties.empty,
    int? timestamp,
    String? eventId,
    String? sessionId,
    String? messageId,
  }) {
    return Event(
      name: name,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      eventType: EventType.track,
      userId: userId,
      properties: properties,
      eventId: eventId,
      sessionId: sessionId,
      messageId: messageId,
    );
  }

  /// Create an identify event
  factory Event.identify({
    required String userId,
    Properties traits = Properties.empty,
    int? timestamp,
    String? eventId,
    String? sessionId,
    String? messageId,
  }) {
    return Event(
      name: EventName.custom('user_identified'),
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      eventType: EventType.identify,
      userId: userId,
      properties: traits,
      eventId: eventId,
      sessionId: sessionId,
      messageId: messageId,
    );
  }

  /// Create a group event
  factory Event.group({
    required String groupId,
    required String userId,
    Properties properties = Properties.empty,
    int? timestamp,
    String? eventId,
    String? sessionId,
    String? messageId,
  }) {
    final groupProperties = properties.withProperty('group_id', groupId);

    return Event(
      name: EventName.custom('group_identified'),
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      eventType: EventType.group,
      userId: userId,
      properties: groupProperties,
      eventId: eventId,
      sessionId: sessionId,
      messageId: messageId,
    );
  }

  /// Create an alias event
  factory Event.alias({
    required String previousId,
    required String newUserId,
    int? timestamp,
    String? eventId,
    String? sessionId,
    String? messageId,
  }) {
    final aliasProperties = Properties.from({
      'previous_id': previousId,
    });

    return Event(
      name: EventName.custom('user_aliased'),
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      eventType: EventType.alias,
      userId: newUserId,
      properties: aliasProperties,
      eventId: eventId,
      sessionId: sessionId,
      messageId: messageId,
    );
  }

  /// Create a revenue event
  factory Event.revenue({
    required double amount,
    required Currency currency,
    required String userId,
    String? orderId,
    Properties properties = Properties.empty,
    int? timestamp,
    String? eventId,
    String? sessionId,
    String? messageId,
  }) {
    var revenueProperties = properties
        .withProperty('revenue', amount)
        .withProperty('currency', currency.code);

    if (orderId != null) {
      revenueProperties = revenueProperties.withProperty('order_id', orderId);
    }

    return Event(
      name: EventName.orderCompleted,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      eventType: EventType.track,
      userId: userId,
      properties: revenueProperties,
      eventId: eventId,
      sessionId: sessionId,
      messageId: messageId,
    );
  }

  /// Validate the event data
  void validate() {
    if (name.value.isEmpty) {
      throw const InvalidEventError('event name cannot be empty');
    }

    if (name.value.length > ValidationConstants.maxEventNameLength) {
      throw InvalidEventError(
        'event name too long (max ${ValidationConstants.maxEventNameLength} characters)',
      );
    }

    if (timestamp <= 0) {
      throw const InvalidEventError('timestamp must be positive');
    }

    if (userId.isEmpty) {
      throw const InvalidEventError('user ID cannot be empty');
    }

    if (userId.length > ValidationConstants.maxUserIdLength) {
      throw InvalidEventError(
        'user ID too long (max ${ValidationConstants.maxUserIdLength} characters)',
      );
    }

    // Validate user ID format (basic check)
    if (!ValidationConstants.userIdPattern.hasMatch(userId)) {
      throw InvalidEventError(
        'user ID contains invalid characters (only alphanumeric, underscore, hyphen allowed)',
      );
    }

    // Validate properties
    try {
      properties.validate();
    } catch (e) {
      throw InvalidEventError('invalid properties: $e');
    }

    // Event-specific validations
    switch (eventType) {
      case EventType.identify:
        _validateIdentifyEvent();
        break;
      case EventType.group:
        _validateGroupEvent();
        break;
      case EventType.alias:
        _validateAliasEvent();
        break;
      case EventType.track:
      case EventType.enrich:
      case EventType.unknown:
        break;
    }
  }

  /// Serialize event properties to JSON bytes
  Uint8List serializePayload() {
    try {
      // Create payload with event metadata
      final payload = <String, dynamic>{
        'event': name.value,
        'properties': properties.toMap(),
        if (eventId != null) 'event_id': eventId,
        if (sessionId != null) 'session_id': sessionId,
        if (messageId != null) 'message_id': messageId,
      };

      final jsonString = json.encode(payload);
      return Uint8List.fromList(utf8.encode(jsonString));
    } catch (e) {
      throw JsonSerializationError('event payload serialization', e);
    }
  }

  /// Convert user ID to bytes for protocol level
  Uint8List get userIdBytes {
    // For now, use a simple conversion. TODO: Phase 2 - Implement proper UUID conversion
    final bytes = Uint8List(16);
    final userIdBytes = utf8.encode(userId);

    for (int i = 0; i < 16; i++) {
      bytes[i] = userIdBytes[i % userIdBytes.length];
    }

    return bytes;
  }

  /// Create a copy with updated properties
  Event copyWith({
    EventName? name,
    int? timestamp,
    EventType? eventType,
    String? userId,
    Properties? properties,
    String? eventId,
    String? sessionId,
    String? messageId,
  }) {
    return Event(
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      userId: userId ?? this.userId,
      properties: properties ?? this.properties,
      eventId: eventId ?? this.eventId,
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
    );
  }

  /// Add or update properties
  Event withProperties(Properties additionalProperties) {
    return copyWith(
      properties: properties.withProperties(additionalProperties.toMap()),
    );
  }

  /// Add event ID if not present
  Event withEventId([String? id]) {
    if (eventId != null) return this;
    return copyWith(eventId: id ?? const Uuid().v4());
  }

  /// Add session ID
  Event withSessionId(String sessionId) {
    return copyWith(sessionId: sessionId);
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'name': name.value,
      'timestamp': timestamp,
      'event_type': eventType.name,
      'user_id': userId,
      'properties': properties.toMap(),
      if (eventId != null) 'event_id': eventId,
      if (sessionId != null) 'session_id': sessionId,
      if (messageId != null) 'message_id': messageId,
    };
  }

  @override
  String toString() {
    return 'Event(name: ${name.value}, type: ${eventType.name}, timestamp: $timestamp, userId: $userId, properties: ${properties.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          timestamp == other.timestamp &&
          eventType == other.eventType &&
          userId == other.userId &&
          properties == other.properties &&
          eventId == other.eventId &&
          sessionId == other.sessionId &&
          messageId == other.messageId;

  @override
  int get hashCode => Object.hash(
        name,
        timestamp,
        eventType,
        userId,
        properties,
        eventId,
        sessionId,
        messageId,
      );

  // Private validation methods

  void _validateIdentifyEvent() {
    // Identify events should have user traits
    if (properties.isEmpty) {
      throw const InvalidEventError('identify event should have user traits');
    }
  }

  void _validateGroupEvent() {
    // Group events must have group_id
    final groupId = properties.string('group_id');
    if (groupId == null || groupId.isEmpty) {
      throw const InvalidEventError('group event must have non-empty group_id property');
    }
  }

  void _validateAliasEvent() {
    // Alias events must have previous_id
    final previousId = properties.string('previous_id');
    if (previousId == null || previousId.isEmpty) {
      throw const InvalidEventError('alias event must have non-empty previous_id property');
    }
  }
}

/// Event builder for fluent API
class EventBuilder {
  String? _name;
  int? _timestamp;
  EventType _eventType = EventType.track;
  String? _userId;
  Properties _properties = Properties.empty;
  String? _eventId;
  String? _sessionId;
  String? _messageId;

  EventBuilder name(EventName name) {
    _name = name.value;
    return this;
  }

  EventBuilder customName(String name) {
    _name = name;
    return this;
  }

  EventBuilder timestamp(int timestamp) {
    _timestamp = timestamp;
    return this;
  }

  EventBuilder eventType(EventType eventType) {
    _eventType = eventType;
    return this;
  }

  EventBuilder userId(String userId) {
    _userId = userId;
    return this;
  }

  EventBuilder properties(Properties properties) {
    _properties = properties;
    return this;
  }

  EventBuilder property(String key, Object? value) {
    _properties = _properties.withProperty(key, value);
    return this;
  }

  EventBuilder eventId(String eventId) {
    _eventId = eventId;
    return this;
  }

  EventBuilder sessionId(String sessionId) {
    _sessionId = sessionId;
    return this;
  }

  EventBuilder messageId(String messageId) {
    _messageId = messageId;
    return this;
  }

  Event build() {
    if (_name == null) {
      throw const InvalidEventError('event name is required');
    }

    if (_userId == null) {
      throw const InvalidEventError('user ID is required');
    }

    final event = Event(
      name: EventName.custom(_name!),
      timestamp: _timestamp ?? DateTime.now().millisecondsSinceEpoch,
      eventType: _eventType,
      userId: _userId!,
      properties: _properties,
      eventId: _eventId,
      sessionId: _sessionId,
      messageId: _messageId,
    );

    event.validate();
    return event;
  }
}

/// Event collection for batching
class EventBatch {
  EventBatch({this.maxSize = 100});

  final int maxSize;
  final List<Event> _events = [];

  /// Add an event to the batch
  bool add(Event event) {
    if (_events.length >= maxSize) {
      return false; // Batch is full
    }

    event.validate();
    _events.add(event);
    return true;
  }

  /// Add multiple events
  List<Event> addAll(Iterable<Event> events) {
    final rejected = <Event>[];

    for (final event in events) {
      if (!add(event)) {
        rejected.add(event);
      }
    }

    return rejected;
  }

  /// Get all events in the batch
  List<Event> get events => List.unmodifiable(_events);

  /// Check if batch is empty
  bool get isEmpty => _events.isEmpty;

  /// Check if batch is full
  bool get isFull => _events.length >= maxSize;

  /// Get batch size
  int get length => _events.length;

  /// Clear the batch
  void clear() => _events.clear();

  /// Estimate batch size in bytes
  int get estimatedBytes {
    return _events.fold<int>(0, (sum, event) {
      return sum + event.serializePayload().length + 100; // Add overhead estimate
    });
  }
}
