import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/data/repositories/user_profile_repository.dart';
import 'package:cycle_sync_mvp_2/data/repositories/lifestyle_areas_repository.dart';
import 'package:cycle_sync_mvp_2/data/repositories/daily_notes_repository.dart';
import 'package:cycle_sync_mvp_2/data/repositories/daily_selections_repository.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';

/// Provide SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provide Supabase client
final supabaseClientProvider = Provider((ref) {
  return SupabaseConfig.client;
});

/// Provide UserProfileRepository
final userProfileRepositoryProvider = Provider<UserProfileRepository?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) return null;
  
  return UserProfileRepository(SupabaseConfig.client, prefs);
});

/// Provide LifestyleAreasRepository
final lifestyleAreasRepositoryProvider = Provider<LifestyleAreasRepository?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) return null;
  
  return LifestyleAreasRepository(SupabaseConfig.client, prefs);
});

/// Provide DailyNotesRepository
final dailyNotesRepositoryProvider = Provider<DailyNotesRepository?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) return null;
  
  return DailyNotesRepository(SupabaseConfig.client, prefs);
});

/// Provide DailySelectionsRepository
final dailySelectionsRepositoryProvider = Provider<DailySelectionsRepository>((ref) {
  return DailySelectionsRepository();
});

/// Get user profile from Supabase
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(userProfileRepositoryProvider);
  if (repository == null) return null;

  return await repository.getUserProfile(userId);
});

/// Get lifestyle areas from Supabase
final lifestyleAreasProvider = FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  final repository = ref.watch(lifestyleAreasRepositoryProvider);
  if (repository == null) return [];

  return await repository.getLifestyleAreas(userId);
});

/// Get available lifestyle categories from Supabase reference table
final lifestyleCategoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final response = await SupabaseConfig.client
        .from('lifestyle_categories')
        .select('category_name')
        .order('category_name', ascending: true);
    
    final categories = (response as List)
        .map((item) => item['category_name'] as String)
        .toList();
    
    return categories;
  } catch (e) {
    print('[Error] Failed to fetch lifestyle categories: $e');
    // Fallback to default categories if fetch fails
    return ['Nutrition', 'Fitness', 'Fasting'];
  }
});

/// Get note for a specific date
final dailyNoteProvider = FutureProvider.family<String?, DateTime>((ref, date) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(dailyNotesRepositoryProvider);
  if (repository == null) return null;

  return await repository.getNote(userId, date);
});

/// Get selections for a specific date - can be invalidated to refresh
final dailySelectionsProvider = FutureProvider.family<Map<String, dynamic>?, DateTime>((ref, date) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(dailySelectionsRepositoryProvider);
  return await repository.getSelectionsForDate(userId, date);
});

/// Get phase recommendations by phase name (Menstrual, Follicular, Ovulation, Luteal)
final phaseRecommendationsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, phaseName) async {
  try {
    print('[phaseRecommendationsProvider] START: Fetching recommendations for phase: "$phaseName"');
    
    // Query by phase_name only. The app has already calculated the correct lifestyle phase locally.
    // Database day_range values are for reference only (28-day cycle standard).
    final response = await SupabaseConfig.client
        .from('cycle_phase_recommendations')
        .select('food_recipes,workout_types,phase_name,lifestyle_phase,workout_mode,food_vibe')
        .eq('phase_name', phaseName)
        .maybeSingle();
    
    print('[phaseRecommendationsProvider] Response for phase "$phaseName": ${response == null ? 'NULL' : 'DATA FOUND'}');
    if (response != null) {
      return response;
    }
    
    // Database returned null - populate with sensible defaults based on phase
    print('[phaseRecommendationsProvider] Using default recommendations for phase: "$phaseName"');
    return _getDefaultPhaseRecommendations(phaseName);
    
  } catch (e, stackTrace) {
    print('[phaseRecommendationsProvider] ERROR: $e');
    print('[phaseRecommendationsProvider] STACKTRACE: $stackTrace');
    // Return defaults even on error
    return _getDefaultPhaseRecommendations(phaseName);
  }
});

/// Default recommendations for each phase when database is empty or unavailable
Map<String, dynamic> _getDefaultPhaseRecommendations(String phaseName) {
  final defaults = {
    'Menstrual': {
      'phase_name': 'Menstrual',
      'lifestyle_phase': 'Glow Reset',
      'hormonal_state': 'Low E, Low P',
      'food_vibe': 'Gut-Friendly Low-Carb',
      'food_recipes': 'Lentil & Spinach Stew • Beetroot & Quinoa Salad • Moroccan Chickpea Tagine • Black Bean Chili con Carne • Braised Kale & White Beans • Red Lentil & Carrot Soup',
      'workout_mode': 'Low-Impact Workout',
      'workout_types': 'Walking • Rest • Hot Girl Walk • Yoga • Mat Pilates • Foam rolling • Low-Impact Strength Training',
    },
    'Follicular': {
      'phase_name': 'Follicular',
      'lifestyle_phase': 'Power Up',
      'hormonal_state': 'Rising E',
      'food_vibe': 'Gut-Friendly Low-Carb',
      'food_recipes': 'Grilled Salmon with Quinoa & Greens • Chicken & Broccoli Stir-Fry • Tofu & Vegetable Power Bowl • Shrimp & Zucchini Noodles • Turkey & Spinach Meatballs • Eggplant & Chickpea Curry',
      'workout_mode': 'Moderate to High-Intensity Workout',
      'workout_types': 'Cardio • 12-3-30 Treadmill • Incline walking • HIIT • Cycling • Spin class • Strength Training • Reformer Pilates • Power yoga',
    },
    'Ovulation': {
      'phase_name': 'Ovulation',
      'lifestyle_phase': 'Main Character',
      'hormonal_state': 'Peak E',
      'food_vibe': 'Carb-Boost Hormone Fuel',
      'food_recipes': 'Mediterranean Grain Bowl • Sweet Potato & Black Bean Tacos • Pasta Primavera • Mango & Avocado Salad • Quinoa Tabouleh • Roasted Vegetable Couscous',
      'workout_mode': 'Strength & Resistance',
      'workout_types': 'Heavy lifting • Strength Training • Strength Reformer Pilates',
    },
    'Luteal': {
      'phase_name': 'Luteal',
      'lifestyle_phase': 'Power Up / Cozy Care',
      'hormonal_state': 'Declining E, High P',
      'food_vibe': 'Carb-Boost Hormone Fuel',
      'food_recipes': 'Turkey & Vegetable Stir-Fry • Lentil & Carrot Curry • Cauliflower Rice Buddha Bowl • Chickpea & Spinach Sauté • Grilled Chicken with Brussels Sprouts • Tempeh & Broccoli Stir-Fry',
      'workout_mode': 'Moderate to Low-Impact Strength',
      'workout_types': 'Spin Class • Strength Training • Endurance Runs • Circuits • Power yoga • Reformer Pilates • Hot Girl Walk • Low-Impact Strength Training',
    },
  };
  
  return defaults[phaseName] ?? defaults['Menstrual']!;
}

// Factory to pass parameters
typedef SaveProfileParams = ({
  String name,
  int cycleLength,
  int menstrualLength,
  int lutealPhaseLength,
  DateTime lastPeriodDate,
  String? avatarBase64,
  String? fastingPreference,
});

/// Save user profile provider
final saveUserProfileProvider = FutureProvider.family<void, SaveProfileParams>((ref, params) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(userProfileRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.saveUserProfile(
    userId: userId,
    name: params.name,
    cycleLength: params.cycleLength,
    menstrualLength: params.menstrualLength,
    lutealPhaseLength: params.lutealPhaseLength,
    lastPeriodDate: params.lastPeriodDate,
    avatarBase64: params.avatarBase64,
    fastingPreference: params.fastingPreference,
  );
});

/// Update avatar provider
final updateAvatarProvider = FutureProvider.family<void, String>((ref, avatarBase64) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(userProfileRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.updateAvatar(userId, avatarBase64);
});

/// Update fasting preference provider
final updateFastingPreferenceProvider = FutureProvider.family<void, String>((ref, preference) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(userProfileRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.updateFastingPreference(userId, preference);
});

/// Update lifestyle areas provider
final updateLifestyleAreasProvider = FutureProvider.family<void, List<String>>((ref, areas) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(lifestyleAreasRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.updateLifestyleAreas(userId, areas);
});

/// Add lifestyle area provider
final addLifestyleAreaProvider = FutureProvider.family<void, String>((ref, area) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(lifestyleAreasRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.addLifestyleArea(userId, area);
});

/// Remove lifestyle area provider
final removeLifestyleAreaProvider = FutureProvider.family<void, String>((ref, area) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(lifestyleAreasRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.removeLifestyleArea(userId, area);
});

typedef SaveNoteParams = ({DateTime date, String noteText});

/// Save daily note provider
final saveDailyNoteProvider = FutureProvider.family<void, SaveNoteParams>((ref, params) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(dailyNotesRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.saveNote(userId, params.date, params.noteText);
});

/// Delete daily note provider
final deleteDailyNoteProvider = FutureProvider.family<void, DateTime>((ref, date) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(dailyNotesRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.deleteNote(userId, date);
});
