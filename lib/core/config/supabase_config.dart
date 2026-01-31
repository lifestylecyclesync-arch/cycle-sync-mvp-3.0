import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Supabase Configuration & Initialization
/// Centralized backend setup and client access
class SupabaseConfig {
  static final Logger _logger = Logger();

  // ============================================================================
  // SUPABASE CREDENTIALS - From environment or direct config
  // ============================================================================
  
  /// Supabase project URL
  static const String supabaseUrl = 'https://aoimvxciibxxcxgeeocz.supabase.co';

  /// Supabase anonymous key (public, safe to expose)
  /// Get this from: Supabase Dashboard → Settings → API → anon (public) key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvaW12eGNpaWJ4eGN4Z2Vlb2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1NjgzMjQsImV4cCI6MjA4MjE0NDMyNH0.pPyZpZLPf9sNlWCOkZKQ9I0zBxcZylMFOGtO21v3e2c';

  // ============================================================================
  // LAZY SINGLETON ACCESS
  // ============================================================================

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get authenticated user, or null if not logged in
  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Get current session, or null if not authenticated
  static Session? get currentSession =>
      Supabase.instance.client.auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize Supabase with credentials
  /// Call this in main() before running app
  static Future<void> initialize() async {
    try {
      _logger.i('🔌 Initializing Supabase...');

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _logger.i('✅ Supabase initialized successfully');

      // Log current auth state
      if (isAuthenticated) {
        _logger.i('👤 User already authenticated: ${currentUser?.email}');
      } else {
        _logger.i('🔓 No active session');
      }
    } catch (e) {
      _logger.e('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // DATABASE REFERENCES
  // ============================================================================

  /// Reference to users table
  static PostgrestFilterBuilder get usersTable =>
      client.from('users').select();

  /// Reference to user_profiles table
  static PostgrestFilterBuilder get userProfilesTable =>
      client.from('user_profiles').select();

  /// Reference to cycles table
  static PostgrestFilterBuilder get cyclesTable =>
      client.from('cycles').select();

  /// Reference to cycle_days table
  static PostgrestFilterBuilder get cycleDaysTable =>
      client.from('cycle_days').select();

  /// Reference to fitness_logs table
  static PostgrestFilterBuilder get fitnessLogsTable =>
      client.from('fitness_logs').select();

  /// Reference to diet_logs table
  static PostgrestFilterBuilder get dietLogsTable =>
      client.from('diet_logs').select();

  /// Reference to meals table
  static PostgrestFilterBuilder get mealsTable =>
      client.from('meals').select();

  /// Reference to fasting_logs table
  static PostgrestFilterBuilder get fastingLogsTable =>
      client.from('fasting_logs').select();

  /// Reference to recipes table
  static PostgrestFilterBuilder get recipesTable =>
      client.from('recipes').select();

  // ============================================================================
  // AUTHENTICATION HELPERS
  // ============================================================================

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('📝 Signing up: $email');
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      _logger.i('✅ Sign up successful');
      return response;
    } catch (e) {
      _logger.e('❌ Sign up failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('🔐 Signing in: $email');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _logger.i('✅ Sign in successful');
      return response;
    } catch (e) {
      _logger.e('❌ Sign in failed: $e');
      rethrow;
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      _logger.i('🚪 Signing out...');
      await client.auth.signOut();
      _logger.i('✅ Sign out successful');
    } catch (e) {
      _logger.e('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// Reset password with email link
  static Future<void> resetPassword({required String email}) async {
    try {
      _logger.i('📧 Sending password reset email: $email');
      await client.auth.resetPasswordForEmail(email);
      _logger.i('✅ Password reset email sent');
    } catch (e) {
      _logger.e('❌ Password reset failed: $e');
      rethrow;
    }
  }

  /// Update user password
  static Future<UserResponse> updatePassword({required String password}) async {
    try {
      _logger.i('🔑 Updating password...');
      final response = await client.auth.updateUser(
        UserAttributes(password: password),
      );
      _logger.i('✅ Password updated successfully');
      return response;
    } catch (e) {
      _logger.e('❌ Password update failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME LISTENERS
  // ============================================================================

  /// Listen to authentication state changes
  /// Usage: SupabaseConfig.onAuthStateChange().listen((event) { ... })
  static Stream<AuthState> onAuthStateChange() {
    return client.auth.onAuthStateChange;
  }

  /// Subscribe to real-time updates on a table
  /// TODO: Implement with updated Supabase API when v3 is available
  static void subscribeToTable({
    required String tableName,
    required Function(dynamic) onUpdate,
  }) {
    _logger.d('📡 Real-time subscription to $tableName queued for implementation');
    // Supabase real-time subscriptions to be implemented in v2 update
  }

  // ============================================================================
  // HEALTH CHECK
  // ============================================================================

  /// Check if Supabase connection is healthy
  static Future<bool> healthCheck() async {
    try {
      _logger.i('🏥 Running Supabase health check...');

      // Try to query a simple table to verify connection
      await client.from('users').select().limit(1);

      _logger.i('✅ Supabase health check passed');
      return true;
    } catch (e) {
      _logger.e('❌ Supabase health check failed: $e');
      return false;
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Close all real-time subscriptions and clean up
  static Future<void> dispose() async {
    try {
      _logger.i('🧹 Cleaning up Supabase...');
      await client.removeAllChannels();
      _logger.i('✅ Supabase cleanup complete');
    } catch (e) {
      _logger.e('⚠️ Supabase cleanup warning: $e');
    }
  }
}
