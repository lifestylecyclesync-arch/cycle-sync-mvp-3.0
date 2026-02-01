import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/core/services/firebase_init.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/app_shell.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/auth/login_page.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:logger/logger.dart';

void main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await initializeFirebase();
  // Initialize Supabase before running the app
  await SupabaseConfig.initialize();
  runApp(
    // Wrap entire app with ProviderScope for Riverpod state management
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cycle Sync',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.peach,
        scaffoldBackgroundColor: AppColors.backgroundPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.peach,
          brightness: Brightness.light,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 2,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Auth wrapper that shows auth screens or main app based on session
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Logger logger = Logger();

    // Watch authentication state
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        // Check if user is authenticated
        final isAuthenticated = SupabaseConfig.isAuthenticated;

        if (isAuthenticated) {
          logger.i('👤 User authenticated: ${SupabaseConfig.currentUser?.email}');
          return const AppShell();
        }

        // Show login screen
        logger.d('🔓 No active session, showing login');
        return LoginPage(
          onLoginSuccess: () {
            // ignore: unused_result
            ref.refresh(authStateProvider);
          },
          onNavigateToSignup: () {
            // Navigate to signup
            // TODO: Implement navigation
          },
        );
      },
      loading: () {
        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.peach),
            ),
          ),
        );
      },
      error: (error, stack) {
        logger.e('❌ Auth error: $error');
        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }
}

