import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Authentication state provider
/// Manages current user session and auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  _logger.d('📡 Setting up auth state stream listener');
  return SupabaseConfig.onAuthStateChange();
});

/// Current authenticated user provider
/// Returns null if not authenticated
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.whenData((state) {
    final user = SupabaseConfig.currentUser;
    if (user != null) {
      _logger.d('👤 Current user: ${user.email}');
    }
    return user;
  }).when(
    data: (user) => user,
    loading: () => null,
    error: (err, stack) {
      _logger.e('Error getting current user: $err');
      return null;
    },
  );
});

/// Current session provider
/// Returns the current Supabase session
final currentSessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.whenData((state) {
    final session = SupabaseConfig.currentSession;
    return session;
  }).when(
    data: (session) => session,
    loading: () => null,
    error: (err, stack) {
      _logger.e('Error getting session: $err');
      return null;
    },
  );
});

/// Is user authenticated provider
/// Returns true if user is logged in
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// User email provider
/// Returns the email of current user, or null
final userEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

/// Sign out state notifier
/// Handles sign out action
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  _logger.i('🚪 Signing out...');
  await SupabaseConfig.signOut();
  _logger.i('✅ Sign out successful');
});
