import 'dart:developer' as developer;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Structured logger that forwards to Crashlytics in release builds
/// and prints in debug builds. Use this instead of raw `print()`.
class AppLogger {
  static final AppLogger _instance = AppLogger._();
  factory AppLogger() => _instance;
  AppLogger._();

  /// Log informational message (debug console only)
  void info(String tag, String message) {
    if (kDebugMode) {
      developer.log(message, name: tag);
    }
  }

  /// Log a warning (debug + Crashlytics breadcrumb)
  void warn(String tag, String message) {
    if (kDebugMode) {
      developer.log('⚠️ $message', name: tag);
    }
    FirebaseCrashlytics.instance.log('[$tag] WARN: $message');
  }

  /// Log an error with optional stack trace
  void error(String tag, String message,
      {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log('❌ $message',
          name: tag, error: error, stackTrace: stackTrace);
    }
    FirebaseCrashlytics.instance.log('[$tag] ERROR: $message');
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
          error, stackTrace ?? StackTrace.current,
          reason: message);
    }
  }

  /// Set user context for crash reports
  void setUser(String uid) {
    FirebaseCrashlytics.instance.setUserIdentifier(uid);
  }

  /// Add custom key-value for crash context
  void setCustomKey(String key, Object value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}
