// Copyright © 2024 UserCanal. All rights reserved.

/// Storage Manager for UserCanal Flutter SDK
///
/// Provides persistent storage for privacy settings, user preferences,
/// and other data that needs to survive app restarts. Uses a simple
/// key-value approach with platform-specific implementations.

import 'dart:async';
import 'dart:convert';

/// Simple storage interface for UserCanal SDK data
///
/// This provides a minimal storage layer for privacy settings,
/// opt-out status, consent state, and anonymous IDs without
/// requiring external dependencies in the core SDK.
abstract class StorageManager {
  /// Get a string value for the given key
  Future<String?> getString(String key);

  /// Set a string value for the given key
  Future<void> setString(String key, String value);

  /// Get a boolean value for the given key
  Future<bool?> getBool(String key);

  /// Set a boolean value for the given key
  Future<void> setBool(String key, bool value);

  /// Get an integer value for the given key
  Future<int?> getInt(String key);

  /// Set an integer value for the given key
  Future<void> setInt(String key, int value);

  /// Remove a value for the given key
  Future<void> remove(String key);

  /// Clear all stored data
  Future<void> clear();

  /// Check if a key exists
  Future<bool> containsKey(String key);
}

/// In-memory storage implementation for testing and fallback
class InMemoryStorageManager implements StorageManager {
  final Map<String, dynamic> _storage = {};

  @override
  Future<String?> getString(String key) async {
    final value = _storage[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async {
    final value = _storage[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _storage[key] = value;
  }

  @override
  Future<int?> getInt(String key) async {
    final value = _storage[key];
    return value is int ? value : null;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }
}

/// Storage keys used by UserCanal SDK
class StorageKeys {
  static const String optOutState = 'usercanal_opt_out';
  static const String consentState = 'usercanal_consent';
  static const String anonymousId = 'usercanal_anonymous_id';
  static const String userId = 'usercanal_user_id';
  static const String userTraits = 'usercanal_user_traits';
  static const String sessionId = 'usercanal_session_id';
  static const String lastSessionTime = 'usercanal_last_session_time';
  static const String appInstallTime = 'usercanal_app_install_time';
}

/// Privacy-focused data manager
class PrivacyDataManager {
  PrivacyDataManager(this._storage);

  final StorageManager _storage;

  // MARK: - Opt-out State Management

  /// Load opt-out state from storage
  Future<bool?> loadOptOutState() async {
    return await _storage.getBool(StorageKeys.optOutState);
  }

  /// Save opt-out state to storage
  Future<void> saveOptOutState(bool isOptedOut) async {
    await _storage.setBool(StorageKeys.optOutState, isOptedOut);
  }

  // MARK: - Consent Management

  /// Load consent state from storage
  Future<bool?> loadConsentState() async {
    return await _storage.getBool(StorageKeys.consentState);
  }

  /// Save consent state to storage
  Future<void> saveConsentState(bool hasConsent) async {
    await _storage.setBool(StorageKeys.consentState, hasConsent);
  }

  // MARK: - User Identity Management

  /// Load anonymous ID from storage
  Future<String?> loadAnonymousId() async {
    return await _storage.getString(StorageKeys.anonymousId);
  }

  /// Save anonymous ID to storage
  Future<void> saveAnonymousId(String anonymousId) async {
    await _storage.setString(StorageKeys.anonymousId, anonymousId);
  }

  /// Load user ID from storage
  Future<String?> loadUserId() async {
    return await _storage.getString(StorageKeys.userId);
  }

  /// Save user ID to storage
  Future<void> saveUserId(String userId) async {
    await _storage.setString(StorageKeys.userId, userId);
  }

  /// Load user traits from storage
  Future<Map<String, dynamic>?> loadUserTraits() async {
    final traitsJson = await _storage.getString(StorageKeys.userTraits);
    if (traitsJson != null) {
      try {
        return json.decode(traitsJson) as Map<String, dynamic>;
      } catch (e) {
        // Invalid JSON, return null
        return null;
      }
    }
    return null;
  }

  /// Save user traits to storage
  Future<void> saveUserTraits(Map<String, dynamic> traits) async {
    final traitsJson = json.encode(traits);
    await _storage.setString(StorageKeys.userTraits, traitsJson);
  }

  // MARK: - Session Management

  /// Load session ID from storage
  Future<String?> loadSessionId() async {
    return await _storage.getString(StorageKeys.sessionId);
  }

  /// Save session ID to storage
  Future<void> saveSessionId(String sessionId) async {
    await _storage.setString(StorageKeys.sessionId, sessionId);
  }

  /// Load last session time from storage
  Future<int?> loadLastSessionTime() async {
    return await _storage.getInt(StorageKeys.lastSessionTime);
  }

  /// Save last session time to storage
  Future<void> saveLastSessionTime(int timestamp) async {
    await _storage.setInt(StorageKeys.lastSessionTime, timestamp);
  }

  // MARK: - App Installation Tracking

  /// Load app install time from storage
  Future<int?> loadAppInstallTime() async {
    return await _storage.getInt(StorageKeys.appInstallTime);
  }

  /// Save app install time to storage
  Future<void> saveAppInstallTime(int timestamp) async {
    await _storage.setInt(StorageKeys.appInstallTime, timestamp);
  }

  // MARK: - Data Management

  /// Clear all user-related data (GDPR compliance)
  Future<void> clearUserData() async {
    await Future.wait([
      _storage.remove(StorageKeys.userId),
      _storage.remove(StorageKeys.userTraits),
      _storage.remove(StorageKeys.sessionId),
      _storage.remove(StorageKeys.lastSessionTime),
    ]);
  }

  /// Clear all stored data including privacy settings
  Future<void> clearAllData() async {
    await _storage.clear();
  }

  /// Export all stored data for GDPR compliance
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'opt_out_state': await loadOptOutState(),
      'consent_state': await loadConsentState(),
      'anonymous_id': await loadAnonymousId(),
      'user_id': await loadUserId(),
      'user_traits': await loadUserTraits(),
      'session_id': await loadSessionId(),
      'last_session_time': await loadLastSessionTime(),
      'app_install_time': await loadAppInstallTime(),
    };
  }
}

/// Default storage manager instance
/// Uses in-memory storage by default, can be replaced with platform-specific implementation
StorageManager _defaultStorage = InMemoryStorageManager();
PrivacyDataManager? _privacyManager;

/// Get the default privacy data manager
PrivacyDataManager getPrivacyDataManager() {
  _privacyManager ??= PrivacyDataManager(_defaultStorage);
  return _privacyManager!;
}

/// Set a custom storage manager for the SDK
/// This allows using SharedPreferences, Hive, or other storage solutions
void setStorageManager(StorageManager storage) {
  _defaultStorage = storage;
  _privacyManager = null; // Reset so it gets recreated with new storage
}
