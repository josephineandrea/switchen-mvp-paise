import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[DEBUG]${tag != null ? "[$tag]" : ""} $message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[INFO]${tag != null ? "[$tag]" : ""} $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[WARN]${tag != null ? "[$tag]" : ""} $message');
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[ERROR]${tag != null ? "[$tag]" : ""} $message');
      if (error != null) debugPrint('  Error: $error');
    }
    // Report to Sentry in production
    if (!kDebugMode && error != null) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
}
