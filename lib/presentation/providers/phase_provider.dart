import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';

/// Phase data model
class Phase {
  final String id;
  final String name;
  final int dayStart;
  final int dayEnd;
  final String description;
  final String? iconName;
  final String? colorHex;
  final int orderIndex;

  Phase({
    required this.id,
    required this.name,
    required this.dayStart,
    required this.dayEnd,
    required this.description,
    this.iconName,
    this.colorHex,
    required this.orderIndex,
  });

  factory Phase.fromSupabase(Map<String, dynamic> json) {
    return Phase(
      id: json['id'] as String,
      name: json['name'] as String,
      dayStart: json['day_start'] as int,
      dayEnd: json['day_end'] as int,
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }
}

/// Fetch all phases from database (single source of truth)
final allPhasesProvider = FutureProvider<List<Phase>>((ref) async {
  try {
    final response = await SupabaseConfig.client
        .from('phases')
        .select()
        .order('order_index');

    final phases = (response as List)
        .map((json) => Phase.fromSupabase(json as Map<String, dynamic>))
        .toList();

    return phases;
  } catch (e) {
    throw Exception('Failed to fetch phases: $e');
  }
});

/// Cycle data
class CycleData {
  final String id;
  final DateTime startDate;
  final int length;
  final int dayOfCycle;
  final int daysSinceStart;

  CycleData({
    required this.id,
    required this.startDate,
    required this.length,
    required this.dayOfCycle,
    required this.daysSinceStart,
  });

  factory CycleData.fromSupabase(Map<String, dynamic> json) {
    return CycleData(
      id: json['cycle_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      length: json['cycle_length'] as int,
      dayOfCycle: json['day_of_cycle'] as int,
      daysSinceStart: json['days_since_start'] as int,
    );
  }
}

/// Get current user's active cycle
final userCurrentCycleProvider =
    FutureProvider.autoDispose<CycleData?>((ref) async {
  try {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return null;

    final response = await SupabaseConfig.client
        .rpc('get_user_current_cycle', params: {'user_uuid': userId});

    if (response == null || (response is List && response.isEmpty)) {
      return null;
    }

    // Response is a single object (not a list from rpc)
    if (response is List && response.isNotEmpty) {
      return CycleData.fromSupabase(response[0] as Map<String, dynamic>);
    }

    return CycleData.fromSupabase(response as Map<String, dynamic>);
  } catch (e) {
    // Log but don't throw - allow app to work without cycle data
    print('⚠️ Could not fetch cycle data: $e');
    return null;
  }
});

/// Get current user's phase
final userCurrentPhaseProvider =
    FutureProvider.autoDispose<Phase?>((ref) async {
  try {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return null;

    final response = await SupabaseConfig.client
        .rpc('get_user_current_phase', params: {'user_uuid': userId});

    if (response == null || (response is List && response.isEmpty)) {
      // Return Follicular as default fallback
      final phases = await ref.watch(allPhasesProvider.future);
      return phases.firstWhere((p) => p.name == 'Follicular');
    }

    if (response is List && response.isNotEmpty) {
      final phaseMap = response[0] as Map<String, dynamic>;
      // Get phase details from allPhasesProvider
      final phases = await ref.watch(allPhasesProvider.future);
      return phases.firstWhere(
        (p) => p.id == phaseMap['phase_id'],
        orElse: () =>
            phases.firstWhere((p) => p.name == 'Follicular'), // Fallback
      );
    }

    // Fallback
    final phases = await ref.watch(allPhasesProvider.future);
    return phases.firstWhere((p) => p.name == 'Follicular');
  } catch (e) {
    print('⚠️ Could not fetch current phase: $e');
    // Return Follicular as safe fallback
    try {
      final phases = await ref.watch(allPhasesProvider.future);
      return phases.firstWhere((p) => p.name == 'Follicular');
    } catch (_) {
      return null;
    }
  }
});

/// Get recommendations for a specific phase and category
final phaseRecommendationsProvider = FutureProvider.family<List<Map<String, dynamic>>, (String, String)>(
  (ref, params) async {
    final (phaseId, category) = params;
    try {
      final response = await SupabaseConfig.client
          .from('phase_recommendations')
          .select()
          .eq('phase_id', phaseId)
          .eq('category', category)
          .eq('is_active', true)
          .order('order_index');

      return response;
    } catch (e) {
      throw Exception('Failed to fetch recommendations for $phaseId/$category: $e');
    }
  },
);

/// Get phase name for a specific cycle day (from database - single source of truth)
final phaseForCycleDayProvider = FutureProvider.family<String, int>(
  (ref, cycleDay) async {
    try {
      // Query cycle_phase_recommendations to find which phase this day belongs to
      final response = await SupabaseConfig.client
          .from('cycle_phase_recommendations')
          .select('phase_name')
          .lte('day_range_start', cycleDay)
          .gte('day_range_end', cycleDay)
          .limit(1)
          .single();

      return response['phase_name'] as String? ?? 'Follicular';
    } catch (e) {
      // Fallback to default calculation if query fails (updated to match table)
      if (cycleDay <= 5) return 'Menstrual';
      if (cycleDay <= 12) return 'Follicular';
      if (cycleDay <= 15) return 'Ovulation';
      return 'Luteal';
    }
  },
);

/// Get all phase definitions (single source of truth)
final phaseDefinitionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await SupabaseConfig.client
        .from('cycle_phase_recommendations')
        .select('phase_name, day_range_start, day_range_end')
        .order('day_range_start');

    // Convert to map: phase_name -> {start, end}
    // Calculate actual min/max for each phase (handles multiple day ranges per phase)
    final definitions = <String, dynamic>{};
    final phaseRanges = <String, (int start, int end)>{};
    
    for (final record in response as List) {
      final phaseName = record['phase_name'] as String;
      final start = record['day_range_start'] as int;
      final end = record['day_range_end'] as int;
      
      if (phaseRanges.containsKey(phaseName)) {
        // Update to include the full range
        final existing = phaseRanges[phaseName]!;
        phaseRanges[phaseName] = (
          existing.$1 < start ? existing.$1 : start,
          existing.$2 > end ? existing.$2 : end,
        );
      } else {
        phaseRanges[phaseName] = (start, end);
      }
    }
    
    // Convert to final format
    for (final entry in phaseRanges.entries) {
      definitions[entry.key] = {
        'start': entry.value.$1,
        'end': entry.value.$2,
      };
    }
    return definitions;
  } catch (e) {
    // Return default if query fails (updated to match new table)
    return {
      'Menstrual': {'start': 1, 'end': 5},
      'Follicular': {'start': 6, 'end': 12},
      'Ovulation': {'start': 13, 'end': 15},
      'Luteal': {'start': 16, 'end': 28},
    };
  }
});

/// Get ALL user's phase recommendations for a cycle day (single query for all categories)
/// This replaces making 3 separate queries - MUCH faster
final userPhaseRecommendationsByDayProvider =
    FutureProvider.family.autoDispose<Map<String, List<Map<String, dynamic>>>, int?>((ref, selectedCycleDay) async {
  try {
    // Get current user's cycle info to determine phase
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return {};

    // Fetch user's last_period_date and cycle_length from user_profiles
    final profileResponse = await SupabaseConfig.client
        .from('user_profiles')
        .select('last_period_date, cycle_length')
        .eq('id', userId)
        .maybeSingle();

    if (profileResponse == null) return {};

    final lastPeriodDate = DateTime.parse(profileResponse['last_period_date'] as String);
    final cycleLength = profileResponse['cycle_length'] as int? ?? 28;

    // Use selected cycle day if provided, otherwise calculate current cycle day
    late int cycleDay;
    if (selectedCycleDay != null && selectedCycleDay > 0) {
      cycleDay = selectedCycleDay;
    } else {
      final normalizedToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final normalizedStart = DateTime(lastPeriodDate.year, lastPeriodDate.month, lastPeriodDate.day);
      final daysSinceStart = normalizedToday.difference(normalizedStart).inDays;
      cycleDay = (daysSinceStart % cycleLength) + 1;
    }

    // Get ALL recommendations for this cycle day (single query - no category filter)
    final response = await SupabaseConfig.client
        .from('cycle_phase_recommendations')
        .select()
        .lte('day_range_start', cycleDay)
        .gte('day_range_end', cycleDay)
        .order('day_range_start');

    // Organize by recommendation_type
    final Map<String, List<Map<String, dynamic>>> organized = {};
    for (final rec in response as List) {
      final type = rec['recommendation_type'] as String;
      organized.putIfAbsent(type, () => []).add(rec as Map<String, dynamic>);
    }

    return organized;
  } catch (e) {
    print('⚠️ Could not fetch phase recommendations for day $selectedCycleDay: $e');
    return {};
  }
});

/// Get user's phase recommendations for a specific category (from database - single source of truth)
final userPhaseRecommendationsProvider =
    FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>(
  (ref, category) async {
    try {
      // Get current user's cycle info to determine phase
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return [];

      // Fetch user's last_period_date and cycle_length from user_profiles
      final profileResponse = await SupabaseConfig.client
          .from('user_profiles')
          .select('last_period_date, cycle_length')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) return [];

      final lastPeriodDate = DateTime.parse(profileResponse['last_period_date'] as String);
      final cycleLength = profileResponse['cycle_length'] as int? ?? 28;

      // Calculate current cycle day
      final normalizedToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final normalizedStart = DateTime(lastPeriodDate.year, lastPeriodDate.month, lastPeriodDate.day);
      final daysSinceStart = normalizedToday.difference(normalizedStart).inDays;
      final cycleDay = (daysSinceStart % cycleLength) + 1;

      // Get recommendations for this cycle day and category
      final response = await SupabaseConfig.client
          .from('cycle_phase_recommendations')
          .select()
          .lte('day_range_start', cycleDay)
          .gte('day_range_end', cycleDay)
          .eq('recommendation_type', category)
          .order('day_range_start');

      return response;
    } catch (e) {
      print('⚠️ Could not fetch user phase recommendations for $category: $e');
      return [];
    }
  },
);
