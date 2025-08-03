// logging_example.dart
// UserCanal Flutter SDK - Logging Usage Example
//
// Copyright © 2024 UserCanal. All rights reserved.
//
// This example demonstrates how to use UserCanal for structured logging
// in a Flutter application. Shows the most common logging patterns.

import 'package:usercanal_flutter/usercanal_flutter.dart';

/// Simple logging usage example for UserCanal Flutter SDK
void main() async {
  print('=== UserCanal Flutter SDK - Logging Example ===\n');

  // 1. Configure the SDK
  await UserCanal.configure(
    apiKey: 'your-32-character-api-key-here',
    endpoint: 'collect.usercanal.com:50000',
    logLevel: SystemLogLevel.debug, // See SDK internal logs
    enableDebugLogging: true,       // Enable console output
  );

  print('✓ SDK configured successfully\n');

  // 2. Basic Logging Levels
  await demoBasicLogging();

  // 3. Structured Logging with Data
  await demoStructuredLogging();

  // 4. Service-Specific Logging
  await demoServiceLogging();

  // 5. Error Logging with Context
  await demoErrorLogging();

  // 6. Performance and Debug Logging
  await demoPerformanceLogging();

  // 7. Application Lifecycle Logging
  await demoLifecycleLogging();

  print('\n=== Logging Example Complete ===');
  print('All logs have been queued and will be sent to UserCanal.');
}

/// Demonstrate basic logging levels
Future<void> demoBasicLogging() async {
  print('--- Basic Logging Levels ---');

  // Different log levels (most common)
  UserCanal.logInfo('Application started successfully');
  print('✓ Info log');

  UserCanal.logError('Database connection failed');
  print('✓ Error log');

  UserCanal.logWarning('API rate limit approaching');
  print('✓ Warning log');

  UserCanal.logDebug('Cache hit for user preferences');
  print('✓ Debug log');

  // All available log levels
  UserCanal.log(LogLevel.emergency, 'System is unusable');
  UserCanal.log(LogLevel.alert, 'Immediate action required');
  UserCanal.log(LogLevel.critical, 'Critical system failure');
  UserCanal.log(LogLevel.notice, 'Normal but significant condition');
  UserCanal.log(LogLevel.trace, 'Very detailed execution trace');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate structured logging with rich data
Future<void> demoStructuredLogging() async {
  print('\n--- Structured Logging with Data ---');

  // User action with context
  UserCanal.logInfo('User login attempt', data: Properties.fromMap({
    'user_id': 'user_12345',
    'email': 'john.doe@example.com',
    'login_method': 'email',
    'ip_address': '192.168.1.100',
    'user_agent': 'Mozilla/5.0...',
    'timestamp': DateTime.now().toIso8601String(),
  }));
  print('✓ User login logged with context');

  // API request logging
  UserCanal.logInfo('API request processed', data: Properties.fromMap({
    'endpoint': '/api/v1/users',
    'method': 'POST',
    'status_code': 201,
    'response_time': 125, // milliseconds
    'request_size': 1024, // bytes
    'response_size': 512, // bytes
  }));
  print('✓ API request logged');

  // Database operation
  UserCanal.logDebug('Database query executed', data: Properties.fromMap({
    'query': 'SELECT * FROM users WHERE active = ?',
    'execution_time': 45, // milliseconds
    'rows_affected': 150,
    'cache_hit': false,
  }));
  print('✓ Database operation logged');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate service-specific logging
Future<void> demoServiceLogging() async {
  print('\n--- Service-Specific Logging ---');

  // Payment service
  UserCanal.log(LogLevel.info, 'Payment processed successfully',
    service: 'payment_service',
    data: Properties.fromMap({
      'transaction_id': 'txn_789456',
      'amount': 29.99,
      'currency': 'USD',
      'payment_method': 'credit_card',
      'processing_time': 850, // milliseconds
    })
  );
  print('✓ Payment service log');

  // Email service
  UserCanal.log(LogLevel.info, 'Welcome email sent',
    service: 'email_service',
    data: Properties.fromMap({
      'recipient': 'john.doe@example.com',
      'template': 'welcome_new_user',
      'delivery_status': 'delivered',
      'delivery_time': 2.5, // seconds
    })
  );
  print('✓ Email service log');

  // Authentication service
  UserCanal.log(LogLevel.warning, 'Multiple failed login attempts',
    service: 'auth_service',
    data: Properties.fromMap({
      'user_id': 'user_12345',
      'failed_attempts': 3,
      'time_window': '5 minutes',
      'ip_address': '192.168.1.100',
      'action_taken': 'account_locked',
    })
  );
  print('✓ Authentication service log');

  // Cache service
  UserCanal.log(LogLevel.debug, 'Cache operation completed',
    service: 'cache_service',
    data: Properties.fromMap({
      'operation': 'SET',
      'key': 'user_preferences_12345',
      'ttl': 3600, // seconds
      'size': 256, // bytes
    })
  );
  print('✓ Cache service log');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate error logging with context
Future<void> demoErrorLogging() async {
  print('\n--- Error Logging with Context ---');

  // Application error
  UserCanal.logError('Failed to load user profile', data: Properties.fromMap({
    'user_id': 'user_12345',
    'error_code': 'USER_NOT_FOUND',
    'error_message': 'User profile not found in database',
    'stack_trace': 'at UserService.getProfile(line 45)...',
    'request_id': 'req_abc123',
  }));
  print('✓ Application error logged');

  // Network error
  UserCanal.log(LogLevel.error, 'External API call failed',
    service: 'integration_service',
    data: Properties.fromMap({
      'api_endpoint': 'https://api.external.com/v1/data',
      'http_status': 503,
      'error_message': 'Service temporarily unavailable',
      'retry_count': 3,
      'timeout': 5000, // milliseconds
    })
  );
  print('✓ Network error logged');

  // Validation error
  UserCanal.logWarning('Input validation failed', data: Properties.fromMap({
    'form_name': 'user_registration',
    'validation_errors': [
      'email_invalid',
      'password_too_short',
      'terms_not_accepted'
    ],
    'user_input': {
      'email': 'invalid-email',
      'password_length': 4,
    },
  }));
  print('✓ Validation error logged');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate performance and debug logging
Future<void> demoPerformanceLogging() async {
  print('\n--- Performance and Debug Logging ---');

  // Performance monitoring
  UserCanal.log(LogLevel.info, 'Page load performance',
    service: 'frontend',
    data: Properties.fromMap({
      'page': '/dashboard',
      'load_time': 1250, // milliseconds
      'dom_ready': 800,
      'first_paint': 600,
      'largest_contentful_paint': 1100,
      'cumulative_layout_shift': 0.05,
    })
  );
  print('✓ Performance metrics logged');

  // Memory usage
  UserCanal.logDebug('Memory usage report', data: Properties.fromMap({
    'heap_used': 45.2, // MB
    'heap_total': 64.0, // MB
    'rss': 89.5, // MB
    'external': 12.1, // MB
    'gc_count': 15,
  }));
  print('✓ Memory usage logged');

  // Feature flag usage
  UserCanal.log(LogLevel.trace, 'Feature flag evaluated',
    service: 'feature_flags',
    data: Properties.fromMap({
      'flag_name': 'new_dashboard_ui',
      'user_id': 'user_12345',
      'flag_value': true,
      'evaluation_time': 2, // milliseconds
      'rule_matched': 'beta_users',
    })
  );
  print('✓ Feature flag logged');

  await Future.delayed(Duration(milliseconds: 100));
}

/// Demonstrate application lifecycle logging
Future<void> demoLifecycleLogging() async {
  print('\n--- Application Lifecycle Logging ---');

  // App startup
  UserCanal.log(LogLevel.info, 'Application startup completed',
    service: 'app_lifecycle',
    data: Properties.fromMap({
      'startup_time': 2500, // milliseconds
      'config_loaded': true,
      'database_connected': true,
      'cache_warmed': true,
      'environment': 'production',
      'app_version': '1.2.3',
    })
  );
  print('✓ App startup logged');

  // Configuration changes
  UserCanal.log(LogLevel.notice, 'Configuration updated',
    service: 'config_service',
    data: Properties.fromMap({
      'config_key': 'api_timeout',
      'old_value': 5000,
      'new_value': 7500,
      'updated_by': 'admin_user',
      'reason': 'performance_optimization',
    })
  );
  print('✓ Configuration change logged');

  // Scheduled task
  UserCanal.log(LogLevel.info, 'Scheduled task completed',
    service: 'task_scheduler',
    data: Properties.fromMap({
      'task_name': 'daily_user_cleanup',
      'execution_time': 45000, // milliseconds
      'records_processed': 1500,
      'records_deleted': 25,
      'next_run': DateTime.now().add(Duration(days: 1)).toIso8601String(),
    })
  );
  print('✓ Scheduled task logged');

  // System health check
  UserCanal.log(LogLevel.info, 'System health check',
    service: 'monitoring',
    data: Properties.fromMap({
      'cpu_usage': 25.5, // percentage
      'memory_usage': 68.2, // percentage
      'disk_usage': 45.0, // percentage
      'active_connections': 150,
      'response_time_avg': 125, // milliseconds
      'error_rate': 0.02, // percentage
    })
  );
  print('✓ System health logged');

  await Future.delayed(Duration(milliseconds: 100));
}
