import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  // TODO: Replace with your actual Supabase project URL and API key
  // Get these from your Supabase project settings
  static const String _supabaseUrl = 'https://aoimvxciibxxcxgeeocz.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_uyaQHsPoIVvj4CvTqVpVxA_0fEatEmV';

  /// Initialize Supabase
  /// Call this in main.dart before runApp()
  static Future<void> initialize() async {
    try {
      AppLogger.info('Initializing Supabase...');

      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );

      AppLogger.info('Supabase initialized successfully');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize Supabase',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get user ID
  static String? get userId => currentUser?.id;

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
