import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_provider.dart';

final _logger = AppLogger('PeriodTrackingProvider');

/// Provider to log a new period date
/// This updates the last_period_date and creates a new cycle entry
final logPeriodProvider = FutureProvider.family<void, DateTime>((ref, periodDate) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    throw Exception('❌ No authenticated user');
  }

  try {
    _logger.i('🔄 Logging period for user: ${user.id}');
    _logger.i('  Period date: $periodDate');

    // Get current user profile to access cycle length
    final profileResponse = await SupabaseConfig.client
        .from('user_profiles')
        .select('cycle_length, menstrual_length')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (profileResponse == null) {
      throw Exception('❌ User profile not found');
    }

    final cycleLength = profileResponse['cycle_length'] as int? ?? 28;
    final menstrualLength = profileResponse['menstrual_length'] as int? ?? 5;

    _logger.d('📊 Current cycle length: $cycleLength, menstrual length: $menstrualLength');

    // Step 1: Mark all previous active cycles as inactive
    _logger.d('🔄 Marking previous cycles as inactive...');
    await SupabaseConfig.client
        .from('cycles')
        .update({'is_active': false})
        .eq('user_id', user.id)
        .eq('is_active', true)
        .timeout(const Duration(seconds: 10));

    // Step 2: Check if cycle with this start date already exists (but is inactive)
    _logger.d('🔍 Checking for existing cycle with this date...');
    final periodDateStr = periodDate.toIso8601String().split('T')[0];
    
    final existingCycle = await SupabaseConfig.client
        .from('cycles')
        .select()
        .eq('user_id', user.id)
        .eq('start_date', periodDateStr)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (existingCycle != null) {
      _logger.d('✏️ Updating existing cycle...');
      // Update existing cycle
      await SupabaseConfig.client
          .from('cycles')
          .update({
            'cycle_length': cycleLength,
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingCycle['id'])
          .timeout(const Duration(seconds: 10));
    } else {
      _logger.d('✨ Creating new cycle...');
      // Create new cycle
      await SupabaseConfig.client
          .from('cycles')
          .insert({
            'user_id': user.id,
            'start_date': periodDateStr,
            'cycle_length': cycleLength,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));
    }

    // Step 3: Update user profile with new last_period_date
    _logger.d('📝 Updating user profile with new period date...');
    await SupabaseConfig.client
        .from('user_profiles')
        .update({
          'last_period_date': periodDateStr,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id)
        .timeout(const Duration(seconds: 10));

    _logger.i('✅ Period logged successfully');

    // Invalidate dependent providers
    if (ref.mounted) {
      _logger.i('🔄 Invalidating dependent providers...');
      ref.invalidate(currentCycleProvider);
      ref.invalidate(activeCycleProvider);
      ref.invalidate(currentCycleDayProvider);
      ref.invalidate(currentPhaseProvider);
      ref.invalidate(isFertileWindowProvider);
      ref.invalidate(daysUntilPeriodProvider);
      ref.invalidate(userCycleLengthProvider);
      ref.invalidate(cycleHistoryProvider);
      _logger.i('✅ Providers invalidated successfully');
    }
  } catch (e) {
    _logger.e('❌ Error logging period: $e');
    rethrow;
  }
});
