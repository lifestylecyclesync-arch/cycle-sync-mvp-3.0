import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Cycle data model
class CycleData {
  final String id;
  final String userId;
  final DateTime startDate;
  final int? length;
  final String phase;
  final int dayOfCycle;
  final DateTime createdAt;
  final DateTime updatedAt;

  CycleData({
    required this.id,
    required this.userId,
    required this.startDate,
    this.length,
    required this.phase,
    required this.dayOfCycle,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase response
  factory CycleData.fromSupabase(Map<String, dynamic> data) {
    return CycleData(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      startDate: DateTime.parse(data['start_date'] as String),
      length: data['length'] as int?,
      phase: data['phase'] as String? ?? 'unknown',
      dayOfCycle: data['day_of_cycle'] as int? ?? 0,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  /// Get phase color name based on phase
  String getPhaseColorName() {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return 'menstrual';
      case 'follicular':
        return 'follicular';
      case 'ovulation':
        return 'ovulation';
      case 'luteal':
        return 'luteal';
      default:
        return 'follicular';
    }
  }
}

/// Current cycle provider
/// Fetches cycle data from user_profiles table
final currentCycleProvider =
    FutureProvider.autoDispose<CycleData?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    _logger.d('📥 Fetching cycle info for user: ${user.id}');

    final response = await SupabaseConfig.client
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (response == null) {
      _logger.d('ℹ️ No cycle profile found for user. Creating default...');
      return null;
    }

    // Convert user_profiles data to CycleData
    final lastPeriodDate = response['last_period_date'] != null
        ? DateTime.parse(response['last_period_date'] as String)
        : null;
    
    if (lastPeriodDate == null) {
      _logger.d('ℹ️ No cycle start date set yet');
      return null;
    }

    final cycleLength = (response['cycle_length'] as int?) ?? 28;
    final now = DateTime.now();
    final daysSinceStart = now.difference(lastPeriodDate).inDays;
    final dayOfCycle = (daysSinceStart % cycleLength) + 1;

    // Determine phase based on day of cycle (follows database table)
    String phase = 'Follicular';
    if (dayOfCycle <= 5) {
      phase = 'Menstrual';
    } else if (dayOfCycle <= 12) {
      phase = 'Follicular';
    } else if (dayOfCycle <= 15) {
      phase = 'Ovulation';
    } else {
      phase = 'Luteal';
    }

    final cycle = CycleData(
      id: response['id'] as String,
      userId: user.id,
      startDate: lastPeriodDate,
      length: cycleLength,
      phase: phase,
      dayOfCycle: dayOfCycle,
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );

    _logger.i(
        '✅ Current cycle loaded: ${cycle.phase} (day ${cycle.dayOfCycle})');
    return cycle;
  } catch (e) {
    _logger.e('❌ Error fetching cycle data: $e');
    return null;
  }
});

/// Today's cycle day provider
/// Returns the day number of the current cycle (1-28)
final currentCycleDayProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final cycle = await ref.watch(currentCycleProvider.future);
  if (cycle == null) return 1;

  final today = DateTime.now();
  final daysSinceStart = today.difference(cycle.startDate).inDays;
  final cycleLength = cycle.length ?? AppConstants.typicalCycleLength;

  // Calculate day within cycle
  int dayOfCycle = (daysSinceStart % cycleLength) + 1;
  dayOfCycle = dayOfCycle.clamp(1, cycleLength);

  return dayOfCycle;
});

/// Current phase provider
/// Returns the current phase name (capitalized for database queries)
final currentPhaseProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final dayOfCycle = await ref.watch(currentCycleDayProvider.future);

    // Simple phase calculation (can be enhanced later)
    // Returns capitalized phase name to match database schema
    if (dayOfCycle <= 5) {
      return 'Menstrual';
    } else if (dayOfCycle <= 13) {
      return 'Follicular';
    } else if (dayOfCycle <= 15) {
      return 'Ovulation';
    } else {
      return 'Luteal';
    }
  } catch (e) {
    // Fallback to Follicular phase if cycle data unavailable
    // This allows recommendations to display even without cycle tracking
    return 'Follicular';
  }
});

/// Fertile window provider
/// Returns true if today is in the fertile window
final isFertileWindowProvider = FutureProvider.autoDispose<bool>((ref) async {
  final dayOfCycle = await ref.watch(currentCycleDayProvider.future);
  final cycleLength = await ref.watch(userCycleLengthProvider.future);

  final fertileStart =
      AppConstants.calculateFertileWindowStart(cycleLength);
  final fertileEnd = AppConstants.calculateFertileWindowEnd(cycleLength);

  return dayOfCycle >= fertileStart && dayOfCycle <= fertileEnd;
});

/// Days until next period provider
/// Returns number of days until menstruation
final daysUntilPeriodProvider = FutureProvider.autoDispose<int>((ref) async {
  final cycle = await ref.watch(currentCycleProvider.future);
  final dayOfCycle = await ref.watch(currentCycleDayProvider.future);

  if (cycle == null) return 28;

  final cycleLength = cycle.length ?? AppConstants.typicalCycleLength;
  final daysRemaining = cycleLength - dayOfCycle + 1;

  return daysRemaining.clamp(0, cycleLength);
});

/// User cycle length provider
/// Fetches preferred cycle length from user profile
final userCycleLengthProvider = FutureProvider.autoDispose<int>((ref) async {
  return AppConstants.typicalCycleLength; // Default 28 days
});

/// Create cycle provider
/// Saves cycle info to cycles table (this triggers the sync to user_profiles)
final createCycleProvider =
    FutureProvider.autoDispose.family<void, (DateTime, int, int)>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');

  final (startDate, cycleLength, menstrualLength) = params;

  try {
    _logger.i('📤 Saving cycle to cycles table: start_date=${startDate.toIso8601String()}, cycle_length=$cycleLength');

    final startDateStr = startDate.toIso8601String().split('T')[0]; // Date only, not datetime

    // Mark all previous cycles as inactive (only one active cycle at a time)
    await SupabaseConfig.client
        .from('cycles')
        .update({'is_active': false})
        .eq('user_id', user.id);
    _logger.i('✅ Marked previous cycles as inactive');

    // Check if a cycle with this start date already exists
    final existingCycle = await SupabaseConfig.client
        .from('cycles')
        .select()
        .eq('user_id', user.id)
        .eq('start_date', startDateStr)
        .maybeSingle();

    if (existingCycle != null) {
      // Update existing cycle
      _logger.i('📝 Cycle with start_date=$startDateStr already exists, updating it');
      await SupabaseConfig.client
          .from('cycles')
          .update({
            'cycle_length': cycleLength,
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingCycle['id']);
      _logger.i('✅ Existing cycle updated and marked as active');
    } else {
      // Insert new cycle
      _logger.i('✨ Creating new cycle');
      await SupabaseConfig.client
          .from('cycles')
          .insert({
            'user_id': user.id,
            'start_date': startDateStr,
            'cycle_length': cycleLength,
            'is_active': true,
          });
      _logger.i('✅ New cycle inserted and marked as active');
    }
    
    // CRITICAL: Explicitly update user_profiles with new cycle data
    // Don't rely only on trigger - directly sync the data for immediate calendar update
    _logger.i('🔄 Syncing cycle data to user_profiles');
    final now = DateTime.now();
    await SupabaseConfig.client
        .from('user_profiles')
        .update({
          'last_period_date': startDateStr,
          'cycle_length': cycleLength,
          'menstrual_length': menstrualLength,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', user.id);
    _logger.i('✅ User profile synced with cycle data');
    
    // Small delay to ensure database writes complete before cache invalidation
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Check if provider is still mounted before invalidating
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
    _logger.e('❌ Error saving cycle: $e');
    rethrow;
  }

});

/// Get active cycle provider
/// Fetches the most recent/active cycle from cycles table for calendar display
/// Only returns ONE active cycle (the current one)
final activeCycleProvider = FutureProvider.autoDispose<CycleData?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _logger.d('ℹ️ No user to fetch cycle for');
    return null;
  }

  try {
    _logger.d('📥 Fetching active cycle for user: ${user.id}');

    final response = await SupabaseConfig.client
        .from('cycles')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true) // Get only active cycles
        .order('start_date', ascending: false) // Most recent first
        .limit(1)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (response == null) {
      _logger.d('ℹ️ No active cycle found for user');
      return null;
    }

    final startDate = DateTime.parse(response['start_date'] as String);
    final cycleLength = (response['cycle_length'] as int?) ?? 28;
    
    final cycle = CycleData(
      id: response['id'] as String,
      userId: response['user_id'] as String,
      startDate: startDate,
      length: cycleLength,
      phase: '', // Phase will be calculated per date
      dayOfCycle: 0,
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );

    _logger.i('✅ Loaded active cycle: start_date=${cycle.startDate}, length=${cycle.length}');
    return cycle;
  } catch (e) {
    _logger.e('❌ Error fetching active cycle: $e');
    return null;
  }
});

/// Get cycle history provider
/// Returns the active cycle for a specific month from the cycles table
final cycleHistoryProvider = FutureProvider.autoDispose
    .family<List<CycleData>, DateTime>((ref, month) async {
  final activeCycle = await ref.watch(activeCycleProvider.future);
  
  if (activeCycle == null) {
    _logger.d('ℹ️ No active cycle available');
    return [];
  }

  // Return single active cycle as a list
  _logger.i('✅ Returning active cycle for calendar view');
  return [activeCycle];
});
