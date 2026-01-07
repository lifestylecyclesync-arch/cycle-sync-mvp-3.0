import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';

/// Service for handling Supabase authentication
class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  /// Get current authenticated user
  User? get currentUser => _supabaseClient.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  String? get userId => currentUser?.id;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Signing up user: $email');
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      AppLogger.info('Sign up successful for: $email');
      return response;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error(
        'Sign up failed: ${error.message}',
        error,
        stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected error during sign up',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Signing in user: $email');
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLogger.info('Sign in successful for: $email');
      return response;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error(
        'Sign in failed: ${error.message}',
        error,
        stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected error during sign in',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      AppLogger.info('Signing out user');
      await _supabaseClient.auth.signOut();
      AppLogger.info('Sign out successful');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sign out failed',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Watch auth state changes
  Stream<AuthState> watchAuthState() {
    return _supabaseClient.auth.onAuthStateChange;
  }

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _supabaseClient.auth.refreshSession();
      return response;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Session refresh failed',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
