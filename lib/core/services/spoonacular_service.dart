import 'package:dio/dio.dart';
import 'package:cycle_sync_mvp_2/domain/entities/recipe.dart';
import 'package:logger/logger.dart';

class SpoonacularService {
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';
  // Replace with your actual API key from https://spoonacular.com/food-api
  static const String _apiKey = 'bfdab33cbd134a9f89b404f0a0610022';

  final Dio _dio;
  final Logger _logger = Logger();
  
  // Simple in-memory cache to reduce API calls
  final Map<String, List<Recipe>> _searchCache = {};
  final Map<int, Recipe> _recipeCache = {};
  final Map<String, List<Recipe>> _phaseCache = {};
  late List<Recipe>? _randomCache;

  SpoonacularService({Dio? dio}) : _dio = dio ?? Dio();

  /// Search recipes by query
  /// Returns list of Recipe objects
  /// Uses cache to avoid repeated API calls
  Future<List<Recipe>> searchRecipes({
    required String query,
    int number = 10,
    bool addRecipeInformation = true,
    bool fillIngredients = true,
  }) async {
    // Check cache first
    final cacheKey = '$query:$number';
    if (_searchCache.containsKey(cacheKey)) {
      _logger.i('Cache hit for search: $cacheKey');
      return _searchCache[cacheKey]!;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/complexSearch',
        queryParameters: {
          'apiKey': _apiKey,
          'query': query,
          'number': number,
          'addRecipeInformation': addRecipeInformation,
          'fillIngredients': fillIngredients,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        final recipes = results
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList();
        
        // Cache the results
        _searchCache[cacheKey] = recipes;
        _logger.i('Cached search results for: $cacheKey');
        
        return recipes;
      }
      throw Exception('Failed to search recipes: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.e('Spoonacular API error: ${e.message}');
      rethrow;
    }
  }

  /// Get detailed recipe information by ID
  /// Uses cache to avoid repeated API calls
  Future<Recipe> getRecipeById(int recipeId) async {
    // Check cache first
    if (_recipeCache.containsKey(recipeId)) {
      _logger.i('Cache hit for recipe ID: $recipeId');
      return _recipeCache[recipeId]!;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/$recipeId/information',
        queryParameters: {
          'apiKey': _apiKey,
          'includeNutrition': true,
        },
      );

      if (response.statusCode == 200) {
        final recipe = Recipe.fromJson(response.data as Map<String, dynamic>);
        // Cache the result
        _recipeCache[recipeId] = recipe;
        _logger.i('Cached recipe with ID: $recipeId');
        return recipe;
      }
      throw Exception('Failed to get recipe: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.e('Spoonacular API error: ${e.message}');
      rethrow;
    }
  }

  /// Search recipes by phase characteristics
  /// Menstrual: iron-rich, lower carb
  /// Follicular: light, fresh, energizing
  /// Ovulation: high protein, carbs
  /// Luteal: comfort food, magnesium-rich
  /// Uses cache to avoid repeated API calls
  Future<List<Recipe>> searchRecipesByPhase({
    required String phaseName,
    int number = 10,
  }) async {
    // Check cache first
    final cacheKey = 'phase:$phaseName:$number';
    if (_phaseCache.containsKey(cacheKey)) {
      _logger.i('Cache hit for phase: $phaseName');
      return _phaseCache[cacheKey]!;
    }

    final queries = {
      'Menstrual': 'iron spinach lentil beef',
      'Follicular': 'salmon chicken light fresh',
      'Ovulation': 'high protein carbs pasta rice',
      'Luteal': 'comfort dark chocolate magnesium sweet potato',
    };

    final query = queries[phaseName] ?? 'healthy recipes';
    final recipes = await searchRecipes(query: query, number: number);
    
    // Cache the phase results
    _phaseCache[cacheKey] = recipes;
    return recipes;
  }

  /// Filter recipes by dietary restrictions
  Future<List<Recipe>> filterByDiet({
    required List<Recipe> recipes,
    bool vegetarian = false,
    bool vegan = false,
    bool glutenFree = false,
  }) async {
    return recipes.where((recipe) {
      if (vegetarian && !recipe.vegetarian) return false;
      if (vegan && !recipe.vegan) return false;
      if (glutenFree && !recipe.glutenFree) return false;
      return true;
    }).toList();
  }

  /// Get random recipes
  /// Uses cache to avoid repeated API calls
  Future<List<Recipe>> getRandomRecipes({int number = 5}) async {
    // Check cache first
    if (_randomCache != null) {
      _logger.i('Cache hit for random recipes');
      return _randomCache!;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/random',
        queryParameters: {
          'apiKey': _apiKey,
          'number': number,
          'includeNutrition': true,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final recipes = data['recipes'] as List? ?? [];
        final result = recipes
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList();
        
        // Cache the results
        _randomCache = result;
        _logger.i('Cached random recipes');
        
        return result;
      }
      throw Exception('Failed to get random recipes: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.e('Spoonacular API error: ${e.message}');
      rethrow;
    }
  }

  /// Clear all caches (useful for manual refresh)
  void clearCache() {
    _searchCache.clear();
    _recipeCache.clear();
    _phaseCache.clear();
    _randomCache = null;
    _logger.i('All caches cleared');
  }}