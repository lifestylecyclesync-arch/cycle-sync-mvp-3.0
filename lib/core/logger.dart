import 'package:logger/logger.dart';

/// App logger wrapper
/// Provides consistent logging across the app
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error: error, stackTrace: stackTrace);
  }

  /// Log API calls
  static void logApiCall({
    required String endpoint,
    required String method,
    Map<String, dynamic>? params,
  }) {
    info('API Call: $method $endpoint${params != null ? '\nParams: $params' : ''}');
  }

  /// Log API response
  static void logApiResponse({
    required String endpoint,
    required int statusCode,
    dynamic response,
  }) {
    info('API Response: $endpoint ($statusCode)');
  }

  /// Log API error
  static void logApiError({
    required String endpoint,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    AppLogger.error('API Error: $endpoint', error, stackTrace);
  }

  /// Log database operation
  static void logDatabaseOperation({
    required String operation,
    required String table,
    dynamic data,
  }) {
    debug('Database: $operation on $table${data != null ? '\nData: $data' : ''}');
  }

  /// Log cache operation
  static void logCacheOperation({
    required String operation,
    required String key,
    dynamic value,
  }) {
    debug('Cache: $operation - $key${value != null ? '\nValue: $value' : ''}');
  }
}
