import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';

final _logger = AppLogger('OnboardingProvider');

/// Provider to check if user has completed onboarding
final onboardingStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    _logger.d('ℹ️ No user to check onboarding status');
    return false;
  }

  try {
    _logger.d('📥 Checking onboarding status for user: ${user.id}');

    final response = await SupabaseConfig.client
        .from('user_profiles')
        .select('onboarding_completed')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (response == null) {
      _logger.d('ℹ️ User profile not found');
      return false;
    }

    final completed = response['onboarding_completed'] as bool? ?? false;
    _logger.d('✅ Onboarding status: $completed');
    
    return completed;
  } catch (e) {
    _logger.e('❌ Error checking onboarding status: $e');
    rethrow;
  }
});

/// Provider to complete onboarding
/// Saves initial cycle data and marks onboarding as complete
final completeOnboardingProvider = 
    FutureProvider.family<void, ({
      DateTime lastPeriodDate,
      int cycleLength,
      int menstrualLength,
      List<String> lifestyleAreas,
    })>((
  ref,
  params,
) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    throw Exception('❌ No authenticated user');
  }

  try {
    _logger.i('🔄 Completing onboarding for user: ${user.id}');
    _logger.i('  Last period: ${params.lastPeriodDate}');
    _logger.i('  Cycle length: ${params.cycleLength}');
    _logger.i('  Menstrual length: ${params.menstrualLength}');
    _logger.i('  Lifestyle areas: ${params.lifestyleAreas}');

    // Upsert user profile with onboarding data (insert if doesn't exist, update if does)
    final response = await SupabaseConfig.client
        .from('user_profiles')
        .upsert({
          'id': user.id,
          'email': user.email ?? '',
          'display_name': user.userMetadata?['display_name'] ?? user.email ?? 'User',
          'last_period_date': params.lastPeriodDate.toIso8601String().split('T')[0],
          'cycle_length': params.cycleLength,
          'menstrual_length': params.menstrualLength,
          'lifestyle_areas': params.lifestyleAreas.isEmpty ? [] : params.lifestyleAreas,
          'onboarding_completed': true,
          'onboarding_completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .timeout(const Duration(seconds: 10));

    _logger.i('✅ Onboarding completed successfully');
    _logger.i('Response from Supabase: $response');
    _logger.i('✅ User profile upserted successfully');

    // Invalidate the onboarding status provider so it refetches
    ref.invalidate(onboardingStatusProvider);
    
    // Also invalidate cycle-related providers
    ref.invalidate(currentUserProvider);
    ref.invalidate(userCycleDataProvider);
  } catch (e) {
    _logger.e('❌ Error completing onboarding: $e');
    rethrow;
  }
});

/// Provider to check if user needs onboarding
/// Returns true if user is logged in but hasn't completed onboarding
final needsOnboardingProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return false; // User not logged in
  }

  final onboardingCompleted = await ref.watch(onboardingStatusProvider.future);
  return !onboardingCompleted; // Needs onboarding if NOT completed
});

/// Provider to get user's cycle data from profile
final userCycleDataProvider = FutureProvider.autoDispose<({
  DateTime? lastPeriodDate,
  int cycleLength,
  int menstrualLength,
  List<String> lifestyleAreas,
})?>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return null;
  }

  try {
    _logger.d('📥 Fetching cycle data for user: ${user.id}');

    final response = await SupabaseConfig.client
        .from('user_profiles')
        .select('last_period_date, cycle_length, menstrual_length, lifestyle_areas')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (response == null) {
      _logger.d('ℹ️ No cycle data found for user');
      return null;
    }

    final lastPeriodDateStr = response['last_period_date'] as String?;
    final cycleLength = response['cycle_length'] as int? ?? 28;
    final menstrualLength = response['menstrual_length'] as int? ?? 5;
    final lifestyleAreas = (response['lifestyle_areas'] as List?)?.cast<String>() ?? [];

    final lastPeriodDate = lastPeriodDateStr != null 
        ? DateTime.parse(lastPeriodDateStr) 
        : null;

    _logger.d('✅ Cycle data retrieved:');
    _logger.d('  Last period: $lastPeriodDate');
    _logger.d('  Cycle length: $cycleLength');
    _logger.d('  Menstrual length: $menstrualLength');
    _logger.d('  Lifestyle areas: $lifestyleAreas');

    return (
      lastPeriodDate: lastPeriodDate,
      cycleLength: cycleLength,
      menstrualLength: menstrualLength,
      lifestyleAreas: lifestyleAreas,
    );
  } catch (e) {
    _logger.e('❌ Error fetching cycle data: $e');
    rethrow;
  }
});
