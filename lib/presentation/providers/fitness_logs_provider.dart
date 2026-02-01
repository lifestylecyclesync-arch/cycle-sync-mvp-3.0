import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Fitness Log Model
class FitnessLog {
  final String id;
  final String userId;
  final DateTime activityDate;
  final String activityType;
  final int? durationMinutes;
  final String intensity;
  final String? notes;
  final bool completed;
  final DateTime createdAt;

  FitnessLog({
    required this.id,
    required this.userId,
    required this.activityDate,
    required this.activityType,
    this.durationMinutes,
    required this.intensity,
    this.notes,
    this.completed = false,
    required this.createdAt,
  });

  factory FitnessLog.fromJson(Map<String, dynamic> json) {
    return FitnessLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      activityDate: DateTime.parse(json['activity_date'] as String),
      activityType: json['activity_type'] as String,
      durationMinutes: json['duration_minutes'] as int?,
      intensity: json['intensity'] as String,
      notes: json['notes'] as String?,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  String toString() => 'FitnessLog($activityType, $durationMinutes min, $intensity)';
}

final supabaseClient = Supabase.instance.client;

/// Get fitness logs for a specific date (defaults to today if null)
final fitnessLogsForDateProvider = FutureProvider.autoDispose.family<List<FitnessLog>, DateTime?>((ref, selectedDate) async {
  try {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      logger.w('❌ [fitnessLogsForDateProvider] No authenticated user');
      return [];
    }

    final queryDate = selectedDate ?? DateTime.now();
    final dateStr = '${queryDate.year}-${queryDate.month.toString().padLeft(2, '0')}-${queryDate.day.toString().padLeft(2, '0')}';
    logger.i('📅 [fitnessLogsForDateProvider] Querying for date: "$dateStr" (type: ${dateStr.runtimeType})');

    final response = await supabaseClient
        .from('fitness_logs')
        .select()
        .eq('user_id', user.id)
        .eq('activity_date', dateStr)
        .order('created_at', ascending: false);

    final logs = (response as List).map((log) {
      logger.i('  📝 Raw log from DB: $log');
      return FitnessLog.fromJson(log as Map<String, dynamic>);
    }).toList();
    logger.i('✅ [fitnessLogsForDateProvider] Fetched ${logs.length} logs for date $dateStr: $logs');
    
    return logs;
  } catch (e) {
    logger.e('💥 [fitnessLogsForDateProvider] Error: $e');
    rethrow;
  }
});

/// Convenience provider for today's fitness logs
final todaysFitnessLogsProvider = FutureProvider.autoDispose<List<FitnessLog>>((ref) async {
  final asyncValue = ref.watch(fitnessLogsForDateProvider(null));
  return asyncValue.when(
    data: (logs) => logs,
    loading: () => throw Exception('Loading...'),
    error: (e, st) => throw e,
  );
});

/// Create fitness log
final createFitnessLogProvider = FutureProvider.autoDispose.family<void, (String, int, String, String?, DateTime?)>(
  (ref, params) async {
    try {
      logger.i('💪 [createFitnessLogProvider] Starting to create fitness log...');
      
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final (activityType, durationMinutes, intensity, notes, selectedDate) = params;
      logger.i('📝 [createFitnessLogProvider] Params: $activityType, $durationMinutes min, $intensity');
      
      // Use selected date if provided, otherwise use today
      final dateToUse = selectedDate ?? DateTime.now();
      final dateOnly = '${dateToUse.year}-${dateToUse.month.toString().padLeft(2, '0')}-${dateToUse.day.toString().padLeft(2, '0')}';

      logger.i('📤 [createFitnessLogProvider] Inserting into Supabase for user: ${user.id}, date: $dateOnly');
      logger.i('📊 [createFitnessLogProvider] Data being inserted:');
      logger.i('  - activity_type: "$activityType"');
      logger.i('  - duration_minutes: $durationMinutes (type: ${durationMinutes.runtimeType})');
      logger.i('  - intensity: "$intensity" (length: ${intensity.length})');
      logger.i('  - notes: "$notes"');
      
      await supabaseClient.from('fitness_logs').insert({
        'user_id': user.id,
        'activity_date': dateOnly,
        'activity_type': activityType,
        'duration_minutes': durationMinutes,
        'intensity': intensity,
        'notes': notes,
      });

      logger.i('✅ [createFitnessLogProvider] Successfully inserted');
    } catch (e) {
      logger.e('💥 [createFitnessLogProvider] Error: $e');
      rethrow;
    }
  },
);

/// Delete fitness log
final deleteFitnessLogProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, logId) async {
    await supabaseClient.from('fitness_logs').delete().eq('id', logId);
  },
);

/// Toggle fitness log completion status
final toggleFitnessLogCompletionProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, logId) async {
    // Get the current log
    final response = await supabaseClient
        .from('fitness_logs')
        .select()
        .eq('id', logId)
        .single();

    final currentLog = FitnessLog.fromJson(response);
    final newCompleted = !currentLog.completed;

    // Update completion status
    await supabaseClient
        .from('fitness_logs')
        .update({'completed': newCompleted})
        .eq('id', logId);
  },
);
