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

/// Simple in-memory cache for lifestyle areas
/// Uses a mutable reference to store cached data
class _LifestyleAreasCache {
  List<String> _areas = [];
  
  List<String> get areas => _areas;
  
  void update(List<String> areas) {
    _areas = areas;
  }
}

final _lifestyleAreasCache = _LifestyleAreasCache();

/// Cache lifestyle areas for instant access without network calls
/// This enables synchronous reads from the cache layer
final lifestyleAreasCacheProvider = Provider<List<String>>((ref) {
  return _lifestyleAreasCache.areas;
});

/// Get cached lifestyle areas synchronously (no waiting for network)
/// Returns empty list if not yet loaded from network
final cachedLifestyleAreasProvider = Provider<List<String>>((ref) {
  return _lifestyleAreasCache.areas;
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
/// NOTE: Lifestyle areas are fetched separately via lifestyleAreasProvider
/// This keeps the profile focused on cycle data only
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(userProfileRepositoryProvider);
  if (repository == null) return null;

  return await repository.getUserProfile(userId);
});

/// Get lifestyle areas from Supabase with unified cache layer
/// Updates the cache immediately, so consumers can watch cachedLifestyleAreasProvider for instant data
final lifestyleAreasProvider = FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];

  final repository = ref.watch(lifestyleAreasRepositoryProvider);
  if (repository == null) return [];

  try {
    final areas = await repository.getLifestyleAreas(userId);
    // Update unified cache layer immediately
    _lifestyleAreasCache.update(areas);
    return areas;
  } catch (e) {
    print('[Error] Failed to fetch lifestyle areas: $e');
    // On error, return what's in cache
    return _lifestyleAreasCache.areas;
  }
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
  // Map lifestyle phase names to their corresponding recommendations
  final lifestylePhaseDefaults = {
    'Glow Reset': {
      'phase_name': 'Menstrual',
      'lifestyle_phase': 'Glow Reset',
      'hormonal_state': 'Low E, Low P',
      'food_vibe': 'Gut-Friendly Low-Carb',
      'food_recipes': 'Lentil & Spinach Stew • Beetroot & Quinoa Salad • Moroccan Chickpea Tagine • Black Bean Chili con Carne • Braised Kale & White Beans • Red Lentil & Carrot Soup',
      'workout_mode': 'Low-Impact Workout',
      'workout_types': 'Walking • Rest • Hot Girl Walk • Yoga • Mat Pilates • Foam rolling • Low-Impact Strength Training',
      'fast_style_beginner': '13h',
      'fast_style_advanced': '15h',
    },
    'Power Up': {
      'phase_name': 'Follicular & Early Luteal',
      'lifestyle_phase': 'Power Up',
      'hormonal_state': 'Rising E / Declining E, Rising P',
      'food_vibe': 'Carb-Boost Hormone Fuel',
      'food_recipes': 'Grilled Salmon with Quinoa & Greens • Chicken & Broccoli Stir-Fry • Tofu & Vegetable Power Bowl • Shrimp & Zucchini Noodles • Turkey & Spinach Meatballs • Eggplant & Chickpea Curry',
      'workout_mode': 'Moderate to High-Intensity Workout',
      'workout_types': 'Cardio • 12-3-30 Treadmill • Incline walking • HIIT • Cycling • Spin class • Strength Training • Reformer Pilates • Power yoga',
      'fast_style_beginner': '17h',
      'fast_style_advanced': '24h',
    },
    'Main Character': {
      'phase_name': 'Ovulation',
      'lifestyle_phase': 'Main Character',
      'hormonal_state': 'Peak E',
      'food_vibe': 'Carb-Boost Hormone Fuel',
      'food_recipes': 'Mediterranean Grain Bowl • Sweet Potato & Black Bean Tacos • Pasta Primavera • Mango & Avocado Salad • Quinoa Tabouleh • Roasted Vegetable Couscous',
      'workout_mode': 'Strength & Resistance',
      'workout_types': 'Heavy lifting • Strength Training • Strength Reformer Pilates',
      'fast_style_beginner': '13h',
      'fast_style_advanced': '17h',
    },
    'Cozy Care': {
      'phase_name': 'Luteal',
      'lifestyle_phase': 'Cozy Care',
      'hormonal_state': 'Low E, High P',
      'food_vibe': 'Carb-Boost Hormone Fuel',
      'food_recipes': 'Turkey & Vegetable Stir-Fry • Lentil & Carrot Curry • Cauliflower Rice Buddha Bowl • Chickpea & Spinach Sauté • Grilled Chicken with Brussels Sprouts • Tempeh & Broccoli Stir-Fry',
      'workout_mode': 'Moderate to Low-Impact Strength',
      'workout_types': 'Hot Girl Walk • Low-Impact Strength Training • Yoga • Mat Pilates • Foam rolling • Restorative Pilates • Gentle Stretching',
      'fast_style_beginner': '13h',
      'fast_style_advanced': '13h',
    },
  };
  
  return lifestylePhaseDefaults[phaseName] ?? lifestylePhaseDefaults['Glow Reset']!;
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
  // Update unified cache layer
  _lifestyleAreasCache.update(areas);
});

/// Add lifestyle area provider
final addLifestyleAreaProvider = FutureProvider.family<void, String>((ref, area) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(lifestyleAreasRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.addLifestyleArea(userId, area);
  // Update unified cache layer
  final updatedAreas = [..._lifestyleAreasCache.areas, area];
  _lifestyleAreasCache.update(updatedAreas);
});

/// Remove lifestyle area provider
final removeLifestyleAreaProvider = FutureProvider.family<void, String>((ref, area) async {
  final userId = ref.watch(userIdProvider);
  final repository = ref.watch(lifestyleAreasRepositoryProvider);
  
  if (repository == null || userId == null) {
    throw Exception('Missing repository or user ID');
  }

  await repository.removeLifestyleArea(userId, area);
  // Update unified cache layer
  final updatedAreas = _lifestyleAreasCache.areas.where((a) => a != area).toList();
  _lifestyleAreasCache.update(updatedAreas);
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

/// Provider for lifestyle areas display order preference
/// Stores and retrieves the user's preferred order for lifestyle area modules
final lifestyleAreasOrderProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  const String orderPreferenceKey = 'lifestyle_areas_order';
  
  final order = prefs.getStringList(orderPreferenceKey);
  if (order != null && order.isNotEmpty) {
    return order;
  }
  // Default order if not set
  return ['Nutrition', 'Fitness', 'Fasting'];
});

/// Mutation provider to save lifestyle areas order
final saveLifestyleAreasOrderProvider = FutureProvider.family<void, List<String>>((ref, newOrder) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  const String orderPreferenceKey = 'lifestyle_areas_order';
  
  await prefs.setStringList(orderPreferenceKey, newOrder);
  print('[LifestyleAreasOrder] Order saved: $newOrder');
});

