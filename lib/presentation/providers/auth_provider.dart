import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/services/auth_service.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(SupabaseConfig.client);
});

/// Current authenticated user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;
  
  // Create a stream that emits current value first, then listens for changes
  return _emitCurrentThenChanges(
    currentUser,
    authService.watchAuthState().map((state) => state.session?.user),
  );
});

// Helper function to emit current value, then stream changes
Stream<T> _emitCurrentThenChanges<T>(T current, Stream<T> changes) async* {
  yield current;
  yield* changes;
}

/// Authentication state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.watchAuthState();
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.whenData((u) => u != null).value ?? false;
});

/// Current user ID
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.whenData((u) => u?.id).value;
});

/// Sign up provider - allows signing up with email/password
final signUpProvider = FutureProvider.family<void, ({String email, String password})>((ref, args) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signUp(email: args.email, password: args.password);
});

/// Sign in provider - allows signing in with email/password
final signInProvider = FutureProvider.family<void, ({String email, String password})>((ref, args) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signIn(email: args.email, password: args.password);
});

/// Sign out provider
final signOutProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signOut();
});

/// Signup mode state - tracks if user is in signup flow during onboarding
final signupModeProvider = NotifierProvider<_SignupModeNotifier, bool>(() {
  return _SignupModeNotifier();
});

class _SignupModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setSignupMode(bool isSignup) {
    state = isSignup;
  }
}
