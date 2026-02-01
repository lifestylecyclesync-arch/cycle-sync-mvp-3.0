import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cycle_sync_mvp_2/domain/entities/recipe.dart';
import 'package:logger/logger.dart';

class FirestoreRecipeService {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirestoreRecipeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get Firestore collection reference for user's favorite recipes
  CollectionReference<FavoriteRecipe> _favoritesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteRecipes')
        .withConverter<FavoriteRecipe>(
          fromFirestore: (snapshot, _) =>
              FavoriteRecipe.fromJson(snapshot.data() ?? {}),
          toFirestore: (favorite, _) => favorite.toJson(),
        );
  }

  /// Add recipe to favorites
  Future<void> addFavorite({
    required String userId,
    required Recipe recipe,
    required String phaseName,
    String notes = '',
  }) async {
    try {
      await _favoritesCollection(userId).doc(recipe.id.toString()).set(
            FavoriteRecipe(
              spoonacularId: recipe.id,
              title: recipe.title,
              imageUrl: recipe.image,
              phaseName: phaseName,
              savedAt: DateTime.now(),
              notes: notes,
            ),
          );
      _logger.i('Recipe ${recipe.title} added to favorites');
    } catch (e) {
      _logger.e('Error adding favorite: $e');
      rethrow;
    }
  }

  /// Remove recipe from favorites
  Future<void> removeFavorite({
    required String userId,
    required int recipeId,
  }) async {
    try {
      await _favoritesCollection(userId).doc(recipeId.toString()).delete();
      _logger.i('Recipe $recipeId removed from favorites');
    } catch (e) {
      _logger.e('Error removing favorite: $e');
      rethrow;
    }
  }

  /// Get all favorite recipes for user
  Future<List<FavoriteRecipe>> getFavorites(String userId) async {
    try {
      final snapshot = await _favoritesCollection(userId).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.e('Error fetching favorites: $e');
      rethrow;
    }
  }

  /// Stream favorite recipes (real-time updates)
  Stream<List<FavoriteRecipe>> favoritesStream(String userId) {
    return _favoritesCollection(userId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get favorites for specific phase
  Future<List<FavoriteRecipe>> getFavoritesByPhase({
    required String userId,
    required String phaseName,
  }) async {
    try {
      final snapshot = await _favoritesCollection(userId)
          .where('phaseName', isEqualTo: phaseName)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.e('Error fetching favorites by phase: $e');
      rethrow;
    }
  }

  /// Update notes for a favorite recipe
  Future<void> updateFavoriteNotes({
    required String userId,
    required int recipeId,
    required String notes,
  }) async {
    try {
      await _favoritesCollection(userId)
          .doc(recipeId.toString())
          .update({'notes': notes});
      _logger.i('Notes updated for recipe $recipeId');
    } catch (e) {
      _logger.e('Error updating notes: $e');
      rethrow;
    }
  }

  /// Check if recipe is favorited
  Future<bool> isFavorited({
    required String userId,
    required int recipeId,
  }) async {
    try {
      final doc =
          await _favoritesCollection(userId).doc(recipeId.toString()).get();
      return doc.exists;
    } catch (e) {
      _logger.e('Error checking favorite status: $e');
      rethrow;
    }
  }

  /// Save user recipe preferences
  Future<void> savePreferences({
    required String userId,
    required List<String> phases,
    required List<String> dietaryRestrictions,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'recipePreferences': {
            'savedPhases': phases,
            'dietaryRestrictions': dietaryRestrictions,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        },
        SetOptions(merge: true),
      );
      _logger.i('Recipe preferences saved');
    } catch (e) {
      _logger.e('Error saving preferences: $e');
      rethrow;
    }
  }

  /// Get user recipe preferences
  Future<Map<String, dynamic>> getPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return (doc.data()?['recipePreferences'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      _logger.e('Error fetching preferences: $e');
      rethrow;
    }
  }
}
