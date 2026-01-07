import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';

/// Repository for managing lifestyle areas in Supabase with local caching
class LifestyleAreasRepository {
  final SupabaseClient _supabaseClient;
  final SharedPreferences _prefs;

  LifestyleAreasRepository(this._supabaseClient, this._prefs);

  /// Get all lifestyle areas for a user
  Future<List<String>> getLifestyleAreas(String userId) async {
    try {
      final response = await _supabaseClient
          .from('lifestyle_areas')
          .select('area_name')
          .eq('user_id', userId);

      final areas = List<String>.from(
        response.map((row) => row['area_name'] as String),
      );

      // Cache locally
      await _cacheLifestyleAreas(areas);
      return areas;
    } catch (e) {
      AppLogger.error('Error fetching lifestyle areas from Supabase', e, StackTrace.current);
      // Return cached areas on error
      return _getCachedLifestyleAreas();
    }
  }

  /// Add a lifestyle area
  Future<void> addLifestyleArea(String userId, String areaName) async {
    try {
      await _supabaseClient
          .from('lifestyle_areas')
          .insert({
            'user_id': userId,
            'area_name': areaName,
          });

      AppLogger.info('Lifestyle area added: $areaName');
    } catch (e) {
      if (e.toString().contains('duplicate')) {
        AppLogger.info('Lifestyle area already exists: $areaName');
      } else {
        AppLogger.error('Error adding lifestyle area', e, StackTrace.current);
        rethrow;
      }
    }
  }

  /// Remove a lifestyle area
  Future<void> removeLifestyleArea(String userId, String areaName) async {
    try {
      await _supabaseClient
          .from('lifestyle_areas')
          .delete()
          .eq('user_id', userId)
          .eq('area_name', areaName);

      AppLogger.info('Lifestyle area removed: $areaName');
    } catch (e) {
      AppLogger.error('Error removing lifestyle area', e, StackTrace.current);
      rethrow;
    }
  }

  /// Update lifestyle areas (replace all)
  Future<void> updateLifestyleAreas(String userId, List<String> areas) async {
    try {
      // Delete all existing areas for this user
      await _supabaseClient
          .from('lifestyle_areas')
          .delete()
          .eq('user_id', userId);

      // Insert new areas
      for (final area in areas) {
        await _supabaseClient
            .from('lifestyle_areas')
            .insert({
              'user_id': userId,
              'area_name': area,
            });
      }

      // Cache locally
      await _cacheLifestyleAreas(areas);
      AppLogger.info('Lifestyle areas updated: $areas');
    } catch (e) {
      AppLogger.error('Error updating lifestyle areas', e, StackTrace.current);
      rethrow;
    }
  }

  /// Cache lifestyle areas locally
  Future<void> _cacheLifestyleAreas(List<String> areas) async {
    try {
      await _prefs.setStringList('cached_lifestyle_areas', areas);
    } catch (e) {
      AppLogger.error('Error caching lifestyle areas', e, StackTrace.current);
    }
  }

  /// Get cached lifestyle areas
  List<String> _getCachedLifestyleAreas() {
    try {
      return _prefs.getStringList('cached_lifestyle_areas') ?? [];
    } catch (e) {
      AppLogger.error('Error retrieving cached lifestyle areas', e, StackTrace.current);
      return [];
    }
  }
}
