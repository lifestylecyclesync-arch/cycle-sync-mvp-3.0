import 'dart:convert';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';

class DailySelectionsRepository {
  final _supabase = SupabaseConfig.client;

  /// Save recipe selection for a specific date (appends to array)
  Future<void> selectRecipe(String userId, DateTime date, String recipe) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('[DailySelections] About to save recipe: $recipe for user: $userId on date: $dateStr');
      
      // First try to get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing != null) {
        // Parse existing recipes
        List<String> recipes = [];
        final existingRecipes = existing['selected_recipes'];
        if (existingRecipes != null && existingRecipes.isNotEmpty) {
          try {
            recipes = List<String>.from(jsonDecode(existingRecipes) as List);
          } catch (e) {
            print('[DailySelections] Error parsing existing recipes: $e');
          }
        }
        
        // Add new recipe if not already in list
        if (!recipes.contains(recipe)) {
          recipes.add(recipe);
        }
        
        // Update with appended list
        await _supabase
            .from('user_daily_selections')
            .update({
              'selected_recipes': jsonEncode(recipes),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('selection_date', dateStr);
        print('[DailySelections] Recipe appended successfully: $recipe');
      } else {
        // Insert new record with single recipe in array
        await _supabase
            .from('user_daily_selections')
            .insert({
              'user_id': userId,
              'selection_date': dateStr,
              'selected_recipes': jsonEncode([recipe]),
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('[DailySelections] Recipe inserted successfully: $recipe');
      }
    } catch (e) {
      print('[Error] Failed to select recipe: $e');
      rethrow;
    }
  }

  /// Save workout selection for a specific date (appends to array)
  Future<void> selectWorkout(String userId, DateTime date, String workout) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('[DailySelections] About to save workout: $workout for user: $userId on date: $dateStr');
      
      // First try to get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing != null) {
        // Parse existing workouts
        List<String> workouts = [];
        final existingWorkouts = existing['selected_workouts'];
        if (existingWorkouts != null && existingWorkouts.isNotEmpty) {
          try {
            workouts = List<String>.from(jsonDecode(existingWorkouts) as List);
          } catch (e) {
            print('[DailySelections] Error parsing existing workouts: $e');
          }
        }
        
        // Add new workout if not already in list
        if (!workouts.contains(workout)) {
          workouts.add(workout);
        }
        
        // Update with appended list
        await _supabase
            .from('user_daily_selections')
            .update({
              'selected_workouts': jsonEncode(workouts),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('selection_date', dateStr);
        print('[DailySelections] Workout appended successfully: $workout');
      } else {
        // Insert new record with single workout in array
        await _supabase
            .from('user_daily_selections')
            .insert({
              'user_id': userId,
              'selection_date': dateStr,
              'selected_workouts': jsonEncode([workout]),
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('[DailySelections] Workout inserted successfully: $workout');
      }
    } catch (e) {
      print('[Error] Failed to select workout: $e');
      rethrow;
    }
  }

  /// Get selections for a specific date
  Future<Map<String, dynamic>?> getSelectionsForDate(String userId, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('[DailySelections] Fetching selections for user: $userId on date: $dateStr');
      
      final response = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      print('[DailySelections] Fetched selections: $response');
      return response;
    } catch (e) {
      print('[Error] Failed to fetch selections for date: $e');
      return null;
    }
  }
}
