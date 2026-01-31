import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fitness Log Model
class FitnessLog {
  final String id;
  final String userId;
  final DateTime activityDate;
  final String activityType;
  final int? durationMinutes;
  final String intensity;
  final String? notes;
  final DateTime createdAt;

  FitnessLog({
    required this.id,
    required this.userId,
    required this.activityDate,
    required this.activityType,
    this.durationMinutes,
    required this.intensity,
    this.notes,
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
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final supabaseClient = Supabase.instance.client;

/// Get today's fitness logs
final todaysFitnessLogsProvider = FutureProvider.autoDispose<List<FitnessLog>>((ref) async {
  final user = supabaseClient.auth.currentUser;
  if (user == null) return [];

  final today = DateTime.now();
  final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final response = await supabaseClient
      .from('fitness_logs')
      .select()
      .eq('user_id', user.id)
      .eq('activity_date', todayDate)
      .order('created_at', ascending: false);

  return (response as List).map((log) => FitnessLog.fromJson(log as Map<String, dynamic>)).toList();
});

/// Create fitness log
final createFitnessLogProvider = FutureProvider.autoDispose.family<void, (String, int, String, String?)>(
  (ref, params) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final (activityType, durationMinutes, intensity, notes) = params;
    
    final now = DateTime.now();
    final dateOnly = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await supabaseClient.from('fitness_logs').insert({
      'user_id': user.id,
      'activity_date': dateOnly,
      'activity_type': activityType,
      'duration_minutes': durationMinutes,
      'intensity': intensity,
      'notes': notes,
    });

    // Invalidate the cache
    if (ref.mounted) {
      ref.invalidate(todaysFitnessLogsProvider);
    }
  },
);

/// Delete fitness log
final deleteFitnessLogProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, logId) async {
    await supabaseClient.from('fitness_logs').delete().eq('id', logId);
    ref.invalidate(todaysFitnessLogsProvider);
  },
);
