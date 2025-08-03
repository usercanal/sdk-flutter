// device.dart
// UserCanal Flutter SDK - Device Context Module
//
// Copyright © 2024 UserCanal. All rights reserved.
//

/// Device context module for automatic enrichment of events
///
/// This module provides comprehensive device information collection
/// for enrichment events, matching the Swift SDK's DeviceContext functionality.
///
/// Features:
/// - Platform-specific device information collection
/// - Cached context for performance optimization
/// - Automatic device type detection (mobile, tablet, desktop, etc.)
/// - Screen, memory, network, and app information
/// - Locale and timezone detection
/// - Cross-platform support (iOS, Android, Web, Desktop)
///
/// Example usage:
/// ```dart
/// final deviceContext = DeviceContext.instance;
/// await deviceContext.initialize();
///
/// // Get complete device context
/// final context = await deviceContext.getContext();
///
/// // Get minimal context for performance
/// final minimalContext = await deviceContext.getMinimalContext();
///
/// // Force refresh cache
/// await deviceContext.refreshContext();
/// ```
library device;

export 'device_constants.dart';
export 'device_context.dart';
