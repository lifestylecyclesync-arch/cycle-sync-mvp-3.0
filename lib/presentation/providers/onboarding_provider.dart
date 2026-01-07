import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_profile_provider.dart';

/// Async provider to load onboarding state from SharedPreferences
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    print('[OnboardingProvider] Loaded onboarding_completed: $completed');
    return completed;
  } catch (e) {
    print('[OnboardingProvider] Error loading onboarding state: $e');
    return false;
  }
});

/// Provider to reset onboarding (for debugging/testing)
final resetOnboardingProvider = FutureProvider<void>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
    print('[OnboardingProvider] Reset onboarding_completed to false');
    // Invalidate the onboarding provider to reload
    ref.invalidate(hasCompletedOnboardingProvider);
  } catch (e) {
    print('[OnboardingProvider] Error resetting onboarding: $e');
  }
});

/// Provider to mark onboarding as completed
final completeOnboardingProvider = FutureProvider<void>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    print('[OnboardingProvider] Marked onboarding_completed: true');
    
    // Invalidate user profile provider to reload saved data
    ref.invalidate(userProfileProvider);
    ref.invalidate(hasCompletedOnboardingProvider);
  } catch (e) {
    print('[OnboardingProvider] Error completing onboarding: $e');
  }
});
