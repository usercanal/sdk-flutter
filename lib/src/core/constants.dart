// Copyright © 2024 UserCanal. All rights reserved.

/// Core constants and enums for UserCanal Flutter SDK
///
/// This module defines all constants, enums, and static values used throughout
/// the SDK, including event types, log levels, predefined event names, and
/// system constants.

import 'package:meta/meta.dart';

/// SDK version and metadata
class SDKInfo {
  static const String name = 'usercanal-flutter';
  static const String version = '0.1.0';
  static const String userAgent = '$name/$version';

  /// Supported platforms
  static const List<String> supportedPlatforms = ['android', 'ios'];

  /// Minimum platform versions
  static const Map<String, String> minimumVersions = {
    'android': '7.0', // API 24
    'ios': '14.0',
  };
}

/// Schema types for FlatBuffer routing
enum SchemaType {
  unknown(0),
  event(1),
  log(2),
  metric(3),
  inventory(4);

  const SchemaType(this.value);
  final int value;

  static SchemaType fromValue(int value) {
    return SchemaType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SchemaType.unknown,
    );
  }
}

/// Event types for different processing paths
enum EventType {
  unknown(0),
  track(1),
  identify(2),
  group(3),
  alias(4),
  enrich(5);

  const EventType(this.value);
  final int value;

  static EventType fromValue(int value) {
    return EventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EventType.unknown,
    );
  }
}

/// Log severity levels (RFC 5424 + TRACE)
enum LogLevel {
  emergency(0, 'EMERGENCY'),
  alert(1, 'ALERT'),
  critical(2, 'CRITICAL'),
  error(3, 'ERROR'),
  warning(4, 'WARNING'),
  notice(5, 'NOTICE'),
  info(6, 'INFO'),
  debug(7, 'DEBUG'),
  trace(8, 'TRACE');

  const LogLevel(this.value, this.label);
  final int value;
  final String label;

  static LogLevel fromValue(int value) {
    return LogLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => LogLevel.info,
    );
  }

  /// Whether this log level is more severe than another
  bool isMoreSevereThan(LogLevel other) => value < other.value;

  /// Whether this log level is at least as severe as another
  bool isAtLeastAsSevereAs(LogLevel other) => value <= other.value;
}

/// Log event types
enum LogEventType {
  unknown(0),
  log(1),
  enrich(2);

  const LogEventType(this.value);
  final int value;

  static LogEventType fromValue(int value) {
    return LogEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LogEventType.unknown,
    );
  }
}

/// Predefined event names (strongly typed)
@immutable
class EventName {
  const EventName._(this.value);

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventName &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  /// Create custom event name
  factory EventName.custom(String name) => EventName._(name);

  // MARK: - Authentication & User Management Events

  static const userSignedUp = EventName._('User Signed Up');
  static const userSignedIn = EventName._('User Signed In');
  static const userSignedOut = EventName._('User Signed Out');
  static const userInvited = EventName._('User Invited');
  static const userOnboarded = EventName._('User Onboarded');
  static const authenticationFailed = EventName._('Authentication Failed');
  static const passwordReset = EventName._('Password Reset');
  static const twoFactorEnabled = EventName._('Two Factor Enabled');
  static const twoFactorDisabled = EventName._('Two Factor Disabled');

  // MARK: - Revenue & Billing Events

  static const orderCompleted = EventName._('Order Completed');
  static const orderRefunded = EventName._('Order Refunded');
  static const orderCanceled = EventName._('Order Canceled');
  static const paymentFailed = EventName._('Payment Failed');
  static const paymentMethodAdded = EventName._('Payment Method Added');
  static const paymentMethodUpdated = EventName._('Payment Method Updated');
  static const paymentMethodRemoved = EventName._('Payment Method Removed');

  // MARK: - Subscription Management Events

  static const subscriptionStarted = EventName._('Subscription Started');
  static const subscriptionRenewed = EventName._('Subscription Renewed');
  static const subscriptionPaused = EventName._('Subscription Paused');
  static const subscriptionResumed = EventName._('Subscription Resumed');
  static const subscriptionChanged = EventName._('Subscription Changed');
  static const subscriptionCanceled = EventName._('Subscription Canceled');

  // MARK: - Trial & Conversion Events

  static const trialStarted = EventName._('Trial Started');
  static const trialEndingSoon = EventName._('Trial Ending Soon');
  static const trialEnded = EventName._('Trial Ended');
  static const trialConverted = EventName._('Trial Converted');

  // MARK: - Shopping Experience Events

  static const cartViewed = EventName._('Cart Viewed');
  static const cartUpdated = EventName._('Cart Updated');
  static const cartAbandoned = EventName._('Cart Abandoned');
  static const checkoutStarted = EventName._('Checkout Started');
  static const checkoutCompleted = EventName._('Checkout Completed');

  // MARK: - Product Engagement Events

  static const pageViewed = EventName._('Page Viewed');
  static const featureUsed = EventName._('Feature Used');
  static const searchPerformed = EventName._('Search Performed');
  static const fileUploaded = EventName._('File Uploaded');
  static const notificationSent = EventName._('Notification Sent');
  static const notificationClicked = EventName._('Notification Clicked');

  // MARK: - Communication Events

  static const emailSent = EventName._('Email Sent');
  static const emailOpened = EventName._('Email Opened');
  static const emailClicked = EventName._('Email Clicked');
  static const emailBounced = EventName._('Email Bounced');
  static const emailUnsubscribed = EventName._('Email Unsubscribed');
  static const supportTicketCreated = EventName._('Support Ticket Created');
  static const supportTicketResolved = EventName._('Support Ticket Resolved');

  // MARK: - Session Events

  static const sessionStarted = EventName._('Session Started');
  static const sessionEnded = EventName._('Session Ended');
  static const appLaunched = EventName._('App Launched');
  static const appBackgrounded = EventName._('App Backgrounded');
  static const appForegrounded = EventName._('App Foregrounded');

  // MARK: - Error Events

  static const errorOccurred = EventName._('Error Occurred');
  static const crashDetected = EventName._('Crash Detected');
  static const performanceIssue = EventName._('Performance Issue');

  // MARK: - UI Events

  static const buttonTapped = EventName._('Button Tapped');
  static const linkClicked = EventName._('Link Clicked');
  static const formSubmitted = EventName._('Form Submitted');
  static const modalOpened = EventName._('Modal Opened');
  static const modalClosed = EventName._('Modal Closed');

  // MARK: - Content Events

  static const contentViewed = EventName._('Content Viewed');
  static const contentShared = EventName._('Content Shared');
  static const contentLiked = EventName._('Content Liked');
  static const videoPlayed = EventName._('Video Played');
  static const videoPaused = EventName._('Video Paused');
  static const videoCompleted = EventName._('Video Completed');

  /// All predefined standard events
  static const List<EventName> standardEvents = [
    // Authentication & User Management
    userSignedUp, userSignedIn, userSignedOut, userInvited, userOnboarded,
    authenticationFailed, passwordReset, twoFactorEnabled, twoFactorDisabled,

    // Revenue & Billing
    orderCompleted, orderRefunded, orderCanceled, paymentFailed,
    paymentMethodAdded, paymentMethodUpdated, paymentMethodRemoved,

    // Subscription Management
    subscriptionStarted, subscriptionRenewed, subscriptionPaused,
    subscriptionResumed, subscriptionChanged, subscriptionCanceled,

    // Trial & Conversion
    trialStarted, trialEndingSoon, trialEnded, trialConverted,

    // Shopping Experience
    cartViewed, cartUpdated, cartAbandoned, checkoutStarted, checkoutCompleted,

    // Product Engagement
    pageViewed, featureUsed, searchPerformed, fileUploaded,
    notificationSent, notificationClicked,

    // Communication
    emailSent, emailOpened, emailClicked, emailBounced, emailUnsubscribed,
    supportTicketCreated, supportTicketResolved,

    // Session Events
    sessionStarted, sessionEnded, appLaunched, appBackgrounded, appForegrounded,

    // Error Events
    errorOccurred, crashDetected, performanceIssue,

    // UI Events
    buttonTapped, linkClicked, formSubmitted, modalOpened, modalClosed,

    // Content Events
    contentViewed, contentShared, contentLiked, videoPlayed, videoPaused, videoCompleted,
  ];

  /// Check if this is a predefined standard event
  bool get isStandardEvent => standardEvents.contains(this);

  /// Get event category
  EventCategory get category {
    if ([userSignedUp, userSignedIn, userSignedOut, userInvited, userOnboarded,
         authenticationFailed, passwordReset, twoFactorEnabled, twoFactorDisabled].contains(this)) {
      return EventCategory.authentication;
    }
    if ([orderCompleted, orderRefunded, orderCanceled, paymentFailed,
         paymentMethodAdded, paymentMethodUpdated, paymentMethodRemoved].contains(this)) {
      return EventCategory.revenue;
    }
    if ([subscriptionStarted, subscriptionRenewed, subscriptionPaused,
         subscriptionResumed, subscriptionChanged, subscriptionCanceled].contains(this)) {
      return EventCategory.subscription;
    }
    if ([trialStarted, trialEndingSoon, trialEnded, trialConverted].contains(this)) {
      return EventCategory.trial;
    }
    if ([cartViewed, cartUpdated, cartAbandoned, checkoutStarted, checkoutCompleted].contains(this)) {
      return EventCategory.shopping;
    }
    if ([pageViewed, featureUsed, searchPerformed, fileUploaded,
         notificationSent, notificationClicked].contains(this)) {
      return EventCategory.engagement;
    }
    if ([emailSent, emailOpened, emailClicked, emailBounced, emailUnsubscribed,
         supportTicketCreated, supportTicketResolved].contains(this)) {
      return EventCategory.communication;
    }
    if ([sessionStarted, sessionEnded, appLaunched, appBackgrounded, appForegrounded].contains(this)) {
      return EventCategory.session;
    }
    if ([errorOccurred, crashDetected, performanceIssue].contains(this)) {
      return EventCategory.error;
    }
    if ([buttonTapped, linkClicked, formSubmitted, modalOpened, modalClosed].contains(this)) {
      return EventCategory.ui;
    }
    if ([contentViewed, contentShared, contentLiked, videoPlayed, videoPaused, videoCompleted].contains(this)) {
      return EventCategory.content;
    }
    return EventCategory.custom;
  }
}

/// Event categories for grouping and analytics
enum EventCategory {
  authentication,
  revenue,
  subscription,
  trial,
  shopping,
  engagement,
  communication,
  session,
  error,
  ui,
  content,
  custom,
}

/// Currency codes (ISO 4217)
enum Currency {
  usd('USD', 'US Dollar', r'$'),
  eur('EUR', 'Euro', '€'),
  gbp('GBP', 'British Pound', '£'),
  jpy('JPY', 'Japanese Yen', '¥'),
  cad('CAD', 'Canadian Dollar', r'C$'),
  aud('AUD', 'Australian Dollar', r'A$'),
  chf('CHF', 'Swiss Franc', 'CHF'),
  cny('CNY', 'Chinese Yuan', '¥'),
  sek('SEK', 'Swedish Krona', 'kr'),
  nzd('NZD', 'New Zealand Dollar', r'NZ$');

  const Currency(this.code, this.name, this.symbol);

  final String code;
  final String name;
  final String symbol;

  static Currency? fromCode(String code) {
    try {
      return Currency.values.firstWhere(
        (currency) => currency.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Authentication methods
enum AuthMethod {
  email('email'),
  phone('phone'),
  social('social'),
  sso('sso'),
  biometric('biometric'),
  twoFactor('two_factor');

  const AuthMethod(this.value);
  final String value;
}

/// Network constants
class NetworkConstants {
  static const int defaultPort = 50000;
  static const String defaultHost = 'collect.usercanal.com';
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration defaultRetryDelay = Duration(seconds: 1);
  static const int maxRetryAttempts = 3;
  static const int maxBatchSize = 10000;
  static const int maxPayloadSize = 100 * 1024 * 1024; // 100MB
}

/// Storage constants
class StorageConstants {
  static const String keyPrefix = 'usercanal_';
  static const String configKey = '${keyPrefix}config';
  static const String userIdKey = '${keyPrefix}user_id';
  static const String sessionIdKey = '${keyPrefix}session_id';
  static const String optOutKey = '${keyPrefix}opt_out';
  static const String offlineEventsKey = '${keyPrefix}offline_events';
  static const String deviceContextKey = '${keyPrefix}device_context';
  static const int maxOfflineEvents = 100000;
  static const int maxStorageSize = 50 * 1024 * 1024; // 50MB
}

/// Validation constants
class ValidationConstants {
  static const int apiKeyLength = 32;
  static const int maxPropertyKeyLength = 256;
  static const int maxPropertyValueLength = 8192;
  static const int maxEventNameLength = 256;
  static const int maxUserIdLength = 256;
  static const int maxGroupIdLength = 256;
  static const int maxServiceNameLength = 128;
  static const int maxLogMessageLength = 4096;
  static const int maxPropertiesCount = 1000;

  /// Regular expressions for validation
  static final RegExp userIdPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
  static final RegExp propertyKeyPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
}

/// Timing constants
class TimingConstants {
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration deviceContextRefresh = Duration(hours: 24);
  static const Duration batchFlushInterval = Duration(seconds: 30);
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration maxRetryDelay = Duration(minutes: 5);
  static const Duration gracefulShutdownTimeout = Duration(seconds: 10);
}

/// Platform-specific constants
class PlatformConstants {
  // iOS specific
  static const String iosMinVersion = '14.0';
  static const List<String> iosSupportedArchitectures = ['arm64', 'x86_64'];

  // Android specific
  static const int androidMinSdkVersion = 24; // Android 7.0
  static const List<String> androidSupportedArchitectures = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
}

/// Feature flags for controlling SDK behavior
class FeatureFlags {
  static const bool enableBatchCompression = true;
  static const bool enableDeviceContextCollection = true;
  static const bool enableSessionTracking = true;
  static const bool enableOfflineStorage = true;
  static const bool enableErrorRecovery = true;
  static const bool enablePerformanceMonitoring = false; // Phase 7
  static const bool enableAdvancedAnalytics = false; // Phase 7
}
