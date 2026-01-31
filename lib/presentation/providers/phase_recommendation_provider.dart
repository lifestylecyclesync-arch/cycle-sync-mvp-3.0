import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/data/models/phase_recommendation.dart';

/// Fetch all phase recommendations from Supabase
final allPhaseRecommendationsProvider = FutureProvider<List<PhaseRecommendation>>((ref) async {
  try {
    final response = await SupabaseConfig.client
        .from('phase_recommendations')
        .select()
        .order('phase_name')
        .order('order_index');

    final recommendations = (response as List)
        .map((json) => PhaseRecommendation.fromSupabase(json as Map<String, dynamic>))
        .toList();

    return recommendations;
  } catch (e) {
    throw Exception('Failed to fetch phase recommendations: $e');
  }
});

/// Fetch recommendations for a specific phase
final phaseRecommendationsByPhaseProvider = FutureProvider.family<List<PhaseRecommendation>, String>((ref, phaseName) async {
  try {
    final response = await SupabaseConfig.client
        .from('phase_recommendations')
        .select()
        .eq('phase_name', phaseName)
        .order('order_index');

    final recommendations = (response as List)
        .map((json) => PhaseRecommendation.fromSupabase(json as Map<String, dynamic>))
        .toList();

    return recommendations;
  } catch (e) {
    throw Exception('Failed to fetch recommendations for $phaseName: $e');
  }
});

/// Fetch recommendation for a specific phase and category
final phaseRecommendationProvider = FutureProvider.family<PhaseRecommendation?, (String, String)>(
  (ref, params) async {
    final (phaseName, category) = params;
    try {
      final response = await SupabaseConfig.client
          .from('phase_recommendations')
          .select()
          .eq('phase_name', phaseName)
          .eq('category', category)
          .maybeSingle();

      if (response == null) return null;

      return PhaseRecommendation.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to fetch recommendation for $phaseName/$category: $e');
    }
  },
);

/// Helper to get recommendations for a specific category across all phases
final recommendationsByCategoryProvider = FutureProvider.family<List<PhaseRecommendation>, String>(
  (ref, category) async {
    try {
      final response = await SupabaseConfig.client
          .from('phase_recommendations')
          .select()
          .eq('category', category)
          .order('phase_name')
          .order('order_index');

      final recommendations = (response as List)
          .map((json) => PhaseRecommendation.fromSupabase(json as Map<String, dynamic>))
          .toList();

      return recommendations;
    } catch (e) {
      throw Exception('Failed to fetch recommendations for category $category: $e');
    }
  },
);
