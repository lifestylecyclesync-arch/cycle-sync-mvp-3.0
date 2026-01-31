import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fasting Log Model
class FastingLog {
  final String id;
  final String userId;
  final DateTime fastingDate;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final String? notes;
  final DateTime createdAt;

  FastingLog({
    required this.id,
    required this.userId,
    required this.fastingDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    this.notes,
    required this.createdAt,
  });

  factory FastingLog.fromJson(Map<String, dynamic> json) {
    return FastingLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fastingDate: DateTime.parse(json['fasting_date'] as String),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      durationHours: (json['duration_hours'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final supabaseClient = Supabase.instance.client;

/// Get today's fasting logs
final todaysFastingLogsProvider = FutureProvider.autoDispose<List<FastingLog>>((ref) async {
  final user = supabaseClient.auth.currentUser;
  if (user == null) return [];

  final today = DateTime.now();
  final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  print('🔍 Querying fasting logs for date: $todayDate, user: ${user.id}');

  final response = await supabaseClient
      .from('fasting_logs')
      .select()
      .eq('user_id', user.id)
      .eq('fasting_date', todayDate)
      .order('created_at', ascending: false);

  print('📊 Fasting logs response: ${(response as List).length} logs found');
  if ((response as List).isNotEmpty) {
    print('📋 First log: ${response[0]}');
  }

  return (response as List).map((log) => FastingLog.fromJson(log as Map<String, dynamic>)).toList();
});

/// Create fasting log
final createFastingLogProvider = FutureProvider.autoDispose.family<void, (DateTime, DateTime, String?)>(
  (ref, params) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final (startTime, endTime, notes) = params;

    // Calculate duration in hours
    final duration = endTime.difference(startTime).inMinutes / 60.0;
    
    final now = DateTime.now();
    final dateOnly = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    print('💾 Inserting fasting log:');
    print('  fasting_date: $dateOnly');
    print('  start_time: ${startTime.toIso8601String()}');
    print('  end_time: ${endTime.toIso8601String()}');
    print('  duration_hours: $duration');

    await supabaseClient.from('fasting_logs').insert({
      'user_id': user.id,
      'fasting_date': dateOnly,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_hours': duration,
      'notes': notes,
    });

    print('✅ Fasting log inserted successfully');

    if (ref.mounted) {
      ref.invalidate(todaysFastingLogsProvider);
    }
  },
);

/// Delete fasting log
final deleteFastingLogProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, logId) async {
    await supabaseClient.from('fasting_logs').delete().eq('id', logId);
    ref.invalidate(todaysFastingLogsProvider);
  },
);
