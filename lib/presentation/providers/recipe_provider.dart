import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cycle_sync_mvp_2/core/services/spoonacular_service.dart';
import 'package:cycle_sync_mvp_2/core/services/firestore_recipe_service.dart';
import 'package:cycle_sync_mvp_2/domain/entities/recipe.dart';

/// Provider for Spoonacular service
final spoonacularServiceProvider = Provider<SpoonacularService>((ref) {
  return SpoonacularService();
});

/// Provider for Firestore recipe service
final firestoreRecipeServiceProvider =
    Provider<FirestoreRecipeService>((ref) {
  return FirestoreRecipeService();
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Search recipes by query
final recipeSearchProvider =
    FutureProvider.family<List<Recipe>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final service = ref.watch(spoonacularServiceProvider);
  return service.searchRecipes(query: query, number: 15);
});

/// Get recipes for specific phase
final recipesByPhaseProvider =
    FutureProvider.family<List<Recipe>, String>((ref, phaseName) async {
  final service = ref.watch(spoonacularServiceProvider);
  return service.searchRecipesByPhase(phaseName: phaseName, number: 12);
});

/// Get detailed recipe by ID
final recipeDetailProvider =
    FutureProvider.family<Recipe, int>((ref, recipeId) async {
  final service = ref.watch(spoonacularServiceProvider);
  return service.getRecipeById(recipeId);
});

/// Get random recipes
final randomRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final service = ref.watch(spoonacularServiceProvider);
  return service.getRandomRecipes(number: 6);
});

/// Get user's favorite recipes (stream)
final userFavoritesProvider = StreamProvider<List<FavoriteRecipe>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final service = ref.watch(firestoreRecipeServiceProvider);
  return service.favoritesStream(userId);
});

/// Get favorite recipes for specific phase
final favoritesByPhaseProvider = FutureProvider.family<List<FavoriteRecipe>,
    String>((ref, phaseName) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(firestoreRecipeServiceProvider);
  return service.getFavoritesByPhase(
    userId: userId,
    phaseName: phaseName,
  );
});

/// Check if recipe is favorited
final isFavoritedProvider =
    FutureProvider.family<bool, int>((ref, recipeId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  final service = ref.watch(firestoreRecipeServiceProvider);
  return service.isFavorited(userId: userId, recipeId: recipeId);
});

/// Add recipe to favorites
final addFavoriteProvider = FutureProvider.family<void, (Recipe, String)>(
  (ref, params) async {
    final (recipe, phaseName) = params;
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) throw Exception('User not authenticated');

    final service = ref.watch(firestoreRecipeServiceProvider);
    await service.addFavorite(
      userId: userId,
      recipe: recipe,
      phaseName: phaseName,
    );
    // Invalidate favorites cache to trigger rebuild
    ref.invalidate(userFavoritesProvider);
  },
);

/// Remove recipe from favorites
final removeFavoriteProvider = FutureProvider.family<void, int>(
  (ref, recipeId) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) throw Exception('User not authenticated');

    final service = ref.watch(firestoreRecipeServiceProvider);
    await service.removeFavorite(userId: userId, recipeId: recipeId);
    // Invalidate favorites cache to trigger rebuild
    ref.invalidate(userFavoritesProvider);
  },
);

/// Get user recipe preferences
final userRecipePreferencesProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {};

  final service = ref.watch(firestoreRecipeServiceProvider);
  return service.getPreferences(userId);
});

/// State notifier for recipe search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

/// State notifier for selected phase filter
class PhaseFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPhase(String? phase) {
    state = phase;
  }
}

final phaseFilterProvider =
    NotifierProvider<PhaseFilterNotifier, String?>(() {
  return PhaseFilterNotifier();
});
