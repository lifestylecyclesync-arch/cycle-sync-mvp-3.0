/// Base failure class for all domain-level errors
abstract class Failure {
  final String message;

  Failure(this.message);

  @override
  String toString() => message;
}

/// Supabase-related failures
class SupabaseFailure extends Failure {
  final String? code;

  SupabaseFailure(
    super.message, {
    this.code,
  });

  factory SupabaseFailure.fromException(Object error) {
    if (error is Exception) {
      return SupabaseFailure(error.toString());
    }
    return SupabaseFailure('Unknown Supabase error');
  }
}

/// Cache-related failures
class CacheFailure extends Failure {
  CacheFailure(super.message);

  factory CacheFailure.read() {
    return CacheFailure('Failed to read from cache');
  }

  factory CacheFailure.write() {
    return CacheFailure('Failed to write to cache');
  }

  factory CacheFailure.clear() {
    return CacheFailure('Failed to clear cache');
  }
}

/// Validation failures
class ValidationFailure extends Failure {
  final String field;

  ValidationFailure(
    super.message, {
    required this.field,
  });

  factory ValidationFailure.invalidDate() {
    return ValidationFailure(
      'Date cannot be in the future',
      field: 'date',
    );
  }

  factory ValidationFailure.invalidCycleLength() {
    return ValidationFailure(
      'Cycle length must be between 21 and 35 days',
      field: 'cycleLength',
    );
  }

  factory ValidationFailure.invalidMenstrualLength() {
    return ValidationFailure(
      'Menstrual length must be between 2 and 35 days',
      field: 'menstrualLength',
    );
  }

  factory ValidationFailure.emptyField(String fieldName) {
    return ValidationFailure(
      '$fieldName is required',
      field: fieldName,
    );
  }
}

/// Network failures
class NetworkFailure extends Failure {
  NetworkFailure(super.message);

  factory NetworkFailure.noConnection() {
    return NetworkFailure('No internet connection');
  }

  factory NetworkFailure.timeout() {
    return NetworkFailure('Request timeout');
  }
}

/// Authentication failures
class AuthFailure extends Failure {
  final String? code;

  AuthFailure(
    super.message, {
    this.code,
  });

  factory AuthFailure.unauthorized() {
    return AuthFailure('Unauthorized access');
  }

  factory AuthFailure.sessionExpired() {
    return AuthFailure('Session expired, please login again');
  }

  factory AuthFailure.invalidCredentials() {
    return AuthFailure('Invalid username or password');
  }
}

/// Generic/unknown failures
class UnknownFailure extends Failure {
  UnknownFailure([super.message = 'An unknown error occurred']);
}
