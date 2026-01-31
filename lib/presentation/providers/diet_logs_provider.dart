import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diet Log Model
class DietLog {
  final String id;
  final String userId;
  final DateTime logDate;
  final String mealType;
  final List<String> foodItems;
  final int? calories;
  final String? notes;
  final DateTime createdAt;

  DietLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.mealType,
    required this.foodItems,
    this.calories,
    this.notes,
    required this.createdAt,
  });

  factory DietLog.fromJson(Map<String, dynamic> json) {
    return DietLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      mealType: json['meal_type'] as String,
      foodItems: List<String>.from(json['food_items'] as List? ?? []),
      calories: json['calories'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final supabaseClient = Supabase.instance.client;

/// Get today's diet logs
final todaysDietLogsProvider = FutureProvider.autoDispose<List<DietLog>>((ref) async {
  final user = supabaseClient.auth.currentUser;
  if (user == null) return [];

  final today = DateTime.now();
  final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final response = await supabaseClient
      .from('diet_logs')
      .select()
      .eq('user_id', user.id)
      .eq('log_date', todayDate)
      .order('created_at', ascending: false);

  return (response as List).map((log) => DietLog.fromJson(log as Map<String, dynamic>)).toList();
});

/// Create diet log
final createDietLogProvider = FutureProvider.autoDispose.family<void, (String, List<String>, int?, String?)>(
  (ref, params) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final (mealType, foodItems, calories, notes) = params;
    
    final now = DateTime.now();
    final dateOnly = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await supabaseClient.from('diet_logs').insert({
      'user_id': user.id,
      'log_date': dateOnly,
      'meal_type': mealType,
      'food_items': foodItems,
      'calories': calories,
      'notes': notes,
    });

    if (ref.mounted) {
      ref.invalidate(todaysDietLogsProvider);
    }
  },
);

/// Delete diet log
final deleteDietLogProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, logId) async {
    await supabaseClient.from('diet_logs').delete().eq('id', logId);
    ref.invalidate(todaysDietLogsProvider);
  },
);
