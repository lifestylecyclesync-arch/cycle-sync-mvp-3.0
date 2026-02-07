import 'package:flutter/foundation.dart';

/// Simple logging utility for the app
/// Prints to console in debug mode
class AppLogger {
  final String tag;

  AppLogger(this.tag);

  /// Info level log
  void i(String message) {
    if (kDebugMode) {
      print('ℹ️  [$tag] $message');
    }
  }

  /// Debug level log
  void d(String message) {
    if (kDebugMode) {
      print('🔍 [$tag] $message');
    }
  }

  /// Error level log
  void e(String message) {
    if (kDebugMode) {
      print('❌ [$tag] $message');
    }
  }

  /// Warning level log
  void w(String message) {
    if (kDebugMode) {
      print('⚠️  [$tag] $message');
    }
  }

  /// Success level log
  void s(String message) {
    if (kDebugMode) {
      print('✅ [$tag] $message');
    }
  }
}
