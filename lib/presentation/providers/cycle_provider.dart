import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_provider.dart';
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
        .eq('user_id', user.id)
        .single()
        .timeout(const Duration(seconds: 10));

    if (response == null) {
      _logger.d('ℹ️ No user profile found yet');
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
/// Saves cycle info to user_profiles table (single source of truth)
final createCycleProvider =
    FutureProvider.autoDispose.family<void, (DateTime, int, int)>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');

  final (startDate, cycleLength, menstrualLength) = params;

  try {
    _logger.i('📤 Saving cycle to user profile: start_date=${startDate.toIso8601String()}, cycle_length=$cycleLength, menstrual_length=$menstrualLength');

    // Try to update existing profile first
    final existingProfile = await SupabaseConfig.client
        .from('user_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingProfile != null) {
      // Update existing profile
      await SupabaseConfig.client
          .from('user_profiles')
          .update({
            'cycle_length': cycleLength,
            'menstrual_length': menstrualLength,
            'last_period_date': startDate.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);
      _logger.i('✅ Cycle updated in user profile');
    } else {
      // Insert new profile
      await SupabaseConfig.client.from('user_profiles').insert({
        'user_id': user.id,
        'cycle_length': cycleLength,
        'menstrual_length': menstrualLength,
        'last_period_date': startDate.toIso8601String(),
      });
      _logger.i('💡 ✅ Cycle created in user profile');
    }
    
    // Check if provider is still mounted before invalidating
    if (ref.mounted) {
      _logger.i('🔄 Invalidating dependent providers...');
      ref.invalidate(currentCycleProvider);
      ref.invalidate(currentCycleDayProvider);
      ref.invalidate(currentPhaseProvider);
      ref.invalidate(isFertileWindowProvider);
      ref.invalidate(daysUntilPeriodProvider);
      ref.invalidate(userCycleLengthProvider);
      _logger.i('✅ Providers invalidated successfully');
    }
  } catch (e) {
    _logger.e('❌ Error saving cycle: $e');
    rethrow;
  }
});

/// Get cycle history provider
/// Returns current cycle (single profile - no history in new schema)
final cycleHistoryProvider = FutureProvider.autoDispose
    .family<List<CycleData>, DateTime>((ref, month) async {
  // In the new schema, we only have current cycle data in user_profiles
  // Return the current cycle if it exists
  final currentCycle = await ref.watch(currentCycleProvider.future);
  
  if (currentCycle == null) {
    _logger.d('ℹ️ No cycle history available');
    return [];
  }

  // Return current cycle as a single-item list
  _logger.i('✅ Returning current cycle for calendar view');
  return [currentCycle];
});
