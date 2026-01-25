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

  /// Toggle workout completion status
  Future<void> toggleWorkoutCompletion(String userId, DateTime date, String workout) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('[DailySelections] Toggling workout completion: $workout for user: $userId on date: $dateStr');
      
      // Get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing == null) {
        print('[DailySelections] No record found for date $dateStr');
        return;
      }
      
      // Parse completed workouts
      List<String> completedWorkouts = [];
      final completedJson = existing['completed_workouts'];
      if (completedJson != null && completedJson.isNotEmpty) {
        try {
          completedWorkouts = List<String>.from(jsonDecode(completedJson) as List);
        } catch (e) {
          print('[DailySelections] Error parsing completed workouts: $e');
        }
      }
      
      // Toggle workout in completed list
      if (completedWorkouts.contains(workout)) {
        completedWorkouts.remove(workout);
        print('[DailySelections] Marked as not done: $workout');
      } else {
        completedWorkouts.add(workout);
        print('[DailySelections] Marked as done: $workout');
      }
      
      // Update database
      await _supabase
          .from('user_daily_selections')
          .update({
            'completed_workouts': jsonEncode(completedWorkouts),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('selection_date', dateStr);
      
      print('[DailySelections] Completion toggled successfully: $workout');
    } catch (e) {
      print('[Error] Failed to toggle workout completion: $e');
      rethrow;
    }
  }

  /// Delete a recipe from the selected recipes
  Future<void> deleteRecipe(String userId, DateTime date, String recipe) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('[DailySelections] Deleting recipe: $recipe for user: $userId on date: $dateStr');
      
      // Get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing == null) {
        print('[DailySelections] No record found for date $dateStr');
        return;
      }
      
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
      
      // Remove recipe from list
      recipes.remove(recipe);
      
      // Also remove from completed recipes if it exists there
      List<String> completedRecipes = [];
      final existingCompleted = existing['completed_recipes'];
      if (existingCompleted != null && existingCompleted.isNotEmpty) {
        try {
          completedRecipes = List<String>.from(jsonDecode(existingCompleted) as List);
        } catch (e) {
          print('[DailySelections] Error parsing completed recipes: $e');
        }
      }
      completedRecipes.remove(recipe);
      
      // Update database - single atomic operation
      await _supabase
          .from('user_daily_selections')
          .update({
            'selected_recipes': recipes.isEmpty ? null : jsonEncode(recipes),
            'completed_recipes': completedRecipes.isEmpty ? null : jsonEncode(completedRecipes),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('selection_date', dateStr);
      
      print('[DailySelections] Recipe deleted successfully: $recipe');
    } catch (e) {
      print('[Error] Failed to delete recipe: $e');
      rethrow;
    }
  }

  /// Delete a workout from the selected workouts
  Future<void> deleteWorkout(String userId, DateTime date, String workout) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('[DailySelections] Deleting workout: $workout for user: $userId on date: $dateStr');
      
      // Get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing == null) {
        print('[DailySelections] No record found for date $dateStr');
        return;
      }
      
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
      
      // Remove workout from list
      workouts.remove(workout);
      
      // Also remove from completed workouts if it exists there
      List<String> completedWorkouts = [];
      final existingCompleted = existing['completed_workouts'];
      if (existingCompleted != null && existingCompleted.isNotEmpty) {
        try {
          completedWorkouts = List<String>.from(jsonDecode(existingCompleted) as List);
        } catch (e) {
          print('[DailySelections] Error parsing completed workouts: $e');
        }
      }
      completedWorkouts.remove(workout);
      
      // Update database - single atomic operation
      await _supabase
          .from('user_daily_selections')
          .update({
            'selected_workouts': workouts.isEmpty ? null : jsonEncode(workouts),
            'completed_workouts': completedWorkouts.isEmpty ? null : jsonEncode(completedWorkouts),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('selection_date', dateStr);
      
      print('[DailySelections] Workout deleted successfully: $workout');
    } catch (e) {
      print('[Error] Failed to delete workout: $e');
      rethrow;
    }
  }

  /// Save fasting hours selection for a specific date
  Future<void> selectFastingHours(String userId, String dateStr, double hours) async {
    try {
      print('[DailySelections] Saving fasting hours: $hours for user: $userId on date: $dateStr');
      
      // First try to get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing record with fasting hours
        await _supabase
            .from('user_daily_selections')
            .update({
              'selected_fasting_hours': hours,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('selection_date', dateStr);
        print('[DailySelections] Fasting hours updated successfully: $hours');
      } else {
        // Insert new record with fasting hours
        await _supabase
            .from('user_daily_selections')
            .insert({
              'user_id': userId,
              'selection_date': dateStr,
              'selected_fasting_hours': hours,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('[DailySelections] Fasting hours inserted successfully: $hours');
      }
    } catch (e) {
      print('[Error] Failed to save fasting hours: $e');
      rethrow;
    }
  }

  /// Log completed recipe for a specific date
  Future<void> logRecipe(String userId, DateTime date, String recipe) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('[DailySelections] Logging recipe: $recipe for user: $userId on date: $dateStr');
      
      // First try to get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing != null) {
        // Parse existing completed recipes
        List<String> completedRecipes = [];
        final existingCompleted = existing['completed_recipes'];
        if (existingCompleted != null && existingCompleted.isNotEmpty) {
          try {
            completedRecipes = List<String>.from(jsonDecode(existingCompleted) as List);
          } catch (e) {
            print('[DailySelections] Error parsing existing completed recipes: $e');
          }
        }
        
        // Add recipe if not already logged
        if (!completedRecipes.contains(recipe)) {
          completedRecipes.add(recipe);
        }
        
        // Update with appended list
        await _supabase
            .from('user_daily_selections')
            .update({
              'completed_recipes': jsonEncode(completedRecipes),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('selection_date', dateStr);
        print('[DailySelections] Recipe logged successfully: $recipe');
      } else {
        // Insert new record with logged recipe
        await _supabase
            .from('user_daily_selections')
            .insert({
              'user_id': userId,
              'selection_date': dateStr,
              'completed_recipes': jsonEncode([recipe]),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('[DailySelections] Recipe logged (new record): $recipe');
      }
    } catch (e) {
      print('[Error] Failed to log recipe: $e');
      rethrow;
    }
  }

  /// Log completed fasting for a specific date
  Future<void> logFastingHours(String userId, String dateStr, double hours) async {
    try {
      print('[DailySelections] Logging fasting: ${hours}h for user: $userId on date: $dateStr');
      
      // First try to get existing record
      final existing = await _supabase
          .from('user_daily_selections')
          .select()
          .eq('user_id', userId)
          .eq('selection_date', dateStr)
          .maybeSingle();
      
      if (existing != null) {
        // Update completed_fasting_hours
        await _supabase
            .from('user_daily_selections')
            .update({
              'completed_fasting_hours': hours,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('selection_date', dateStr);
        print('[DailySelections] Fasting logged successfully: ${hours}h');
      } else {
        // Insert new record with logged fasting
        await _supabase
            .from('user_daily_selections')
            .insert({
              'user_id': userId,
              'selection_date': dateStr,
              'selected_fasting_hours': hours,
              'completed_fasting_hours': hours,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('[DailySelections] Fasting logged (new record): ${hours}h');
      }
    } catch (e) {
      print('[Error] Failed to log fasting: $e');
      rethrow;
    }
  }

  /// Clear completed fasting hours for a specific date
  Future<void> clearCompletedFastingHours(String userId, String dateStr) async {
    try {
      print('[DailySelections] Clearing completed fasting hours for user: $userId on date: $dateStr');
      
      // Update completed_fasting_hours to null
      await _supabase
          .from('user_daily_selections')
          .update({
            'completed_fasting_hours': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('selection_date', dateStr);
      print('[DailySelections] Completed fasting hours cleared successfully');
    } catch (e) {
      print('[Error] Failed to clear completed fasting hours: $e');
      rethrow;
    }
  }
}