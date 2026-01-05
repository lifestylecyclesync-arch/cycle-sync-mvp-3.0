import 'package:cycle_sync_mvp_2/core/errors/failure.dart';

/// Base exception class
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(
    this.message, {
    this.code,
  });

  @override
  String toString() => message;
}

/// Supabase exception wrapper
class SupabaseException extends AppException {
  SupabaseException(
    super.message, {
    super.code,
  });

  /// Convert to failure for use in domain layer
  Failure toFailure() {
    return SupabaseFailure(message, code: code);
  }
}

/// Cache exception wrapper
class CacheException extends AppException {
  CacheException(
    super.message, {
    super.code,
  });

  Failure toFailure() {
    return CacheFailure(message);
  }
}

/// Network exception wrapper
class NetworkException extends AppException {
  NetworkException(
    super.message, {
    super.code,
  });

  Failure toFailure() {
    return NetworkFailure(message);
  }
}

/// Validation exception wrapper
class ValidationException extends AppException {
  final String field;

  ValidationException(
    super.message, {
    required this.field,
    super.code,
  });

  Failure toFailure() {
    return ValidationFailure(
      message,
      field: field,
    );
  }
}

/// Auth exception wrapper
class AuthException extends AppException {
  AuthException(
    super.message, {
    super.code,
  });

  Failure toFailure() {
    return AuthFailure(message, code: code);
  }
}
