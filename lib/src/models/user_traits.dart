// Copyright © 2024 UserCanal. All rights reserved.

/// User traits data model for UserCanal Flutter SDK
///
/// This module defines the user traits data structures used for user
/// identification, segmentation, and personalization throughout the SDK.

import 'package:meta/meta.dart';
import '../core/constants.dart';
import '../errors/user_canal_error.dart';
import 'properties.dart';

/// Core user traits class for user identification and segmentation
@immutable
class UserTraits {
  const UserTraits({
    this.userId,
    this.email,
    this.name,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    this.createdAt,
    this.plan,
    this.company,
    this.title,
    this.website,
    this.address,
    this.customTraits = Properties.empty,
  });

  /// Unique user identifier
  final String? userId;

  /// User email address
  final String? email;

  /// Full name
  final String? name;

  /// First name
  final String? firstName;

  /// Last name
  final String? lastName;

  /// Phone number
  final String? phone;

  /// Avatar/profile picture URL
  final String? avatar;

  /// Account creation date
  final DateTime? createdAt;

  /// User's plan/tier
  final String? plan;

  /// Company name
  final String? company;

  /// Job title
  final String? title;

  /// Website URL
  final String? website;

  /// User address
  final UserAddress? address;

  /// Custom trait properties
  final Properties customTraits;

  /// Create user traits from a map
  factory UserTraits.fromMap(Map<String, dynamic> map) {
    return UserTraits(
      userId: map['user_id'] as String?,
      email: map['email'] as String?,
      name: map['name'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      avatar: map['avatar'] as String?,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : map['created_at'] as DateTime?,
      plan: map['plan'] as String?,
      company: map['company'] as String?,
      title: map['title'] as String?,
      website: map['website'] as String?,
      address: map['address'] is Map<String, dynamic>
          ? UserAddress.fromMap(map['address'] as Map<String, dynamic>)
          : null,
      customTraits: Properties.fromMap(
        Map<String, dynamic>.from(map)
          ..removeWhere((key, value) => _standardTraitKeys.contains(key)),
      ),
    );
  }

  /// Standard trait keys that are handled separately
  static const Set<String> _standardTraitKeys = {
    'user_id',
    'email',
    'name',
    'first_name',
    'last_name',
    'phone',
    'avatar',
    'created_at',
    'company',
    'title',
    'website',
    'address',
  };

  /// Validate the user traits data
  void validate() {
    if (email != null && !ValidationConstants.emailPattern.hasMatch(email!)) {
      throw const InvalidUserIdError('invalid email format');
    }

    if (userId != null && userId!.isEmpty) {
      throw const InvalidUserIdError('user ID cannot be empty');
    }

    if (userId != null && userId!.length > ValidationConstants.maxUserIdLength) {
      throw InvalidUserIdError(
        'user ID too long (max ${ValidationConstants.maxUserIdLength} characters)',
      );
    }

    if (name != null && name!.length > 256) {
      throw const InvalidPropertyError('name', 'too long (max 256 characters)');
    }

    if (firstName != null && firstName!.length > 128) {
      throw const InvalidPropertyError('firstName', 'too long (max 128 characters)');
    }

    if (lastName != null && lastName!.length > 128) {
      throw const InvalidPropertyError('lastName', 'too long (max 128 characters)');
    }

    if (company != null && company!.length > 256) {
      throw const InvalidPropertyError('company', 'too long (max 256 characters)');
    }

    if (title != null && title!.length > 128) {
      throw const InvalidPropertyError('title', 'too long (max 128 characters)');
    }

    if (website != null && !_isValidUrl(website!)) {
      throw const InvalidPropertyError('website', 'invalid URL format');
    }

    if (avatar != null && !_isValidUrl(avatar!)) {
      throw const InvalidPropertyError('avatar', 'invalid URL format');
    }

    // Validate address if present
    address?.validate();

    // Validate custom traits
    try {
      customTraits.validate();
    } catch (e) {
      throw InvalidPropertyError('customTraits', 'invalid custom traits: $e');
    }
  }

  /// Convert to a map for serialization
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (userId != null) map['user_id'] = userId;
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null) map['last_name'] = lastName;
    if (phone != null) map['phone'] = phone;
    if (avatar != null) map['avatar'] = avatar;
    if (createdAt != null) map['created_at'] = createdAt!.toIso8601String();
    if (plan != null) map['plan'] = plan;
    if (company != null) map['company'] = company;
    if (title != null) map['title'] = title;
    if (website != null) map['website'] = website;
    if (address != null) map['address'] = address!.toMap();

    // Add custom traits
    map.addAll(customTraits.toMap());

    return map;
  }

  /// Create a copy with updated values
  UserTraits copyWith({
    String? userId,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
    DateTime? createdAt,
    String? plan,
    String? company,
    String? title,
    String? website,
    UserAddress? address,
    Properties? customTraits,
  }) {
    return UserTraits(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      plan: plan ?? this.plan,
      company: company ?? this.company,
      title: title ?? this.title,
      website: website ?? this.website,
      address: address ?? this.address,
      customTraits: customTraits ?? this.customTraits,
    );
  }

  /// Add or update custom traits
  UserTraits withCustomTraits(Properties additionalTraits) {
    return copyWith(
      customTraits: customTraits.withProperties(additionalTraits.toMap()),
    );
  }

  /// Add a single custom trait
  UserTraits withCustomTrait(String key, Object? value) {
    return withCustomTraits(Properties.from({key: value}));
  }

  /// Remove custom traits
  UserTraits withoutCustomTraits(Set<String> keysToRemove) {
    return copyWith(customTraits: customTraits.withoutAll(keysToRemove));
  }

  /// Get full name (first + last name)
  String? get fullName {
    if (name != null) return name;

    final parts = <String>[];
    if (firstName != null) parts.add(firstName!);
    if (lastName != null) parts.add(lastName!);

    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Check if user has any identification information
  bool get hasIdentification {
    return userId != null || email != null || phone != null;
  }

  /// Check if user has contact information
  bool get hasContactInfo {
    return email != null || phone != null;
  }

  /// Check if user has profile information
  bool get hasProfileInfo {
    return name != null || firstName != null || lastName != null || avatar != null;
  }

  /// Check if user has business information
  bool get hasBusinessInfo {
    return company != null || title != null || website != null;
  }

  /// Get user's initials for display
  String? get initials {
    final name = fullName;
    if (name == null || name.isEmpty) return null;

    final parts = name.trim().split(' ');
    if (parts.isEmpty) return null;

    final initials = parts
        .take(2) // Take first two parts only
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .where((initial) => initial.isNotEmpty)
        .join();

    return initials.isEmpty ? null : initials;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTraits &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          name == other.name &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          phone == other.phone &&
          avatar == other.avatar &&
          createdAt == other.createdAt &&
          plan == other.plan &&
          company == other.company &&
          title == other.title &&
          website == other.website &&
          address == other.address &&
          customTraits == other.customTraits;

  @override
  int get hashCode => Object.hash(
        userId,
        email,
        name,
        firstName,
        lastName,
        phone,
        avatar,
        createdAt,
        plan,
        company,
        title,
        website,
        address,
        customTraits,
      );

  @override
  String toString() {
    return 'UserTraits(userId: $userId, email: $email, name: $fullName, '
        'company: $company, customTraits: ${customTraits.length})';
  }

  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
}

/// User address information
@immutable
class UserAddress {
  const UserAddress({
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      street: map['street'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      postalCode: map['postal_code'] as String?,
      country: map['country'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (street != null) map['street'] = street;
    if (city != null) map['city'] = city;
    if (state != null) map['state'] = state;
    if (postalCode != null) map['postal_code'] = postalCode;
    if (country != null) map['country'] = country;
    return map;
  }

  void validate() {
    if (street != null && street!.length > 256) {
      throw const InvalidPropertyError('street', 'too long (max 256 characters)');
    }
    if (city != null && city!.length > 128) {
      throw const InvalidPropertyError('city', 'too long (max 128 characters)');
    }
    if (state != null && state!.length > 128) {
      throw const InvalidPropertyError('state', 'too long (max 128 characters)');
    }
    if (postalCode != null && postalCode!.length > 32) {
      throw const InvalidPropertyError('postalCode', 'too long (max 32 characters)');
    }
    if (country != null && country!.length > 128) {
      throw const InvalidPropertyError('country', 'too long (max 128 characters)');
    }
  }

  UserAddress copyWith({
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return UserAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAddress &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          city == other.city &&
          state == other.state &&
          postalCode == other.postalCode &&
          country == other.country;

  @override
  int get hashCode => Object.hash(street, city, state, postalCode, country);

  @override
  String toString() {
    final parts = <String>[];
    if (street != null) parts.add(street!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (postalCode != null) parts.add(postalCode!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }
}

/// User traits builder for fluent API
class UserTraitsBuilder {
  String? _userId;
  String? _email;
  String? _name;
  String? _firstName;
  String? _lastName;
  String? _phone;
  String? _avatar;
  DateTime? _createdAt;
  String? _plan;
  String? _company;
  String? _title;
  String? _website;
  UserAddress? _address;
  Properties _customTraits = Properties.empty;

  UserTraitsBuilder userId(String userId) {
    _userId = userId;
    return this;
  }

  UserTraitsBuilder email(String email) {
    _email = email;
    return this;
  }

  UserTraitsBuilder name(String name) {
    _name = name;
    return this;
  }

  UserTraitsBuilder firstName(String firstName) {
    _firstName = firstName;
    return this;
  }

  UserTraitsBuilder lastName(String lastName) {
    _lastName = lastName;
    return this;
  }

  UserTraitsBuilder phone(String phone) {
    _phone = phone;
    return this;
  }

  UserTraitsBuilder avatar(String avatar) {
    _avatar = avatar;
    return this;
  }

  UserTraitsBuilder createdAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  UserTraitsBuilder plan(String plan) {
    _plan = plan;
    return this;
  }

  UserTraitsBuilder company(String company) {
    _company = company;
    return this;
  }

  UserTraitsBuilder title(String title) {
    _title = title;
    return this;
  }

  UserTraitsBuilder website(String website) {
    _website = website;
    return this;
  }

  UserTraitsBuilder address(UserAddress address) {
    _address = address;
    return this;
  }

  UserTraitsBuilder customTraits(Properties customTraits) {
    _customTraits = customTraits;
    return this;
  }

  UserTraitsBuilder customTrait(String key, Object? value) {
    _customTraits = _customTraits.withProperty(key, value);
    return this;
  }

  UserTraits build() {
    final traits = UserTraits(
      userId: _userId,
      email: _email,
      name: _name,
      firstName: _firstName,
      lastName: _lastName,
      phone: _phone,
      avatar: _avatar,
      createdAt: _createdAt,
      plan: _plan,
      company: _company,
      title: _title,
      website: _website,
      address: _address,
      customTraits: _customTraits,
    );

    traits.validate();
    return traits;
  }
}
