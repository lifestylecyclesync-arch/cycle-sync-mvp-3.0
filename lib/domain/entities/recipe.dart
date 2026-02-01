/// Recipe entity - from Spoonacular API
class Recipe {
  final int id;
  final String title;
  final String image;
  final String sourceUrl;
  final int readyInMinutes;
  final int servings;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final String summary;
  final List<RecipeIngredient> extendedIngredients;
  final RecipeNutrition nutrition;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.sourceUrl,
    required this.readyInMinutes,
    required this.servings,
    required this.vegetarian,
    required this.vegan,
    required this.glutenFree,
    required this.summary,
    required this.extendedIngredients,
    required this.nutrition,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      image: json['image'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      readyInMinutes: json['readyInMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      vegetarian: json['vegetarian'] as bool? ?? false,
      vegan: json['vegan'] as bool? ?? false,
      glutenFree: json['glutenFree'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      extendedIngredients: (json['extendedIngredients'] as List?)
              ?.map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      nutrition: json['nutrition'] != null
          ? RecipeNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
          : RecipeNutrition.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'sourceUrl': sourceUrl,
        'readyInMinutes': readyInMinutes,
        'servings': servings,
        'vegetarian': vegetarian,
        'vegan': vegan,
        'glutenFree': glutenFree,
        'summary': summary,
        'extendedIngredients':
            extendedIngredients.map((i) => i.toJson()).toList(),
        'nutrition': nutrition.toJson(),
      };
}

class RecipeIngredient {
  final int id;
  final String name;
  final double amount;
  final String unit;

  RecipeIngredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'unit': unit,
      };
}

class RecipeNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  RecipeNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory RecipeNutrition.empty() => RecipeNutrition(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
      );

  factory RecipeNutrition.fromJson(Map<String, dynamic> json) {
    final nutrients = json['nutrients'] as List? ?? [];

    double getValue(String name) {
      try {
        final nutrient = nutrients.firstWhere(
          (n) => (n['name'] as String?)?.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
        return (nutrient?['amount'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    return RecipeNutrition(
      calories: getValue('calories'),
      protein: getValue('protein'),
      carbs: getValue('carbohydrates'),
      fat: getValue('fat'),
      fiber: getValue('fiber'),
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
      };
}

/// Favorite recipe saved in Firestore
class FavoriteRecipe {
  final int spoonacularId;
  final String title;
  final String imageUrl;
  final String phaseName;
  final DateTime savedAt;
  final String notes;

  FavoriteRecipe({
    required this.spoonacularId,
    required this.title,
    required this.imageUrl,
    required this.phaseName,
    required this.savedAt,
    this.notes = '',
  });

  factory FavoriteRecipe.fromJson(Map<String, dynamic> json) {
    return FavoriteRecipe(
      spoonacularId: json['spoonacularId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      phaseName: json['phaseName'] as String? ?? '',
      savedAt: json['savedAt'] != null
          ? DateTime.parse(json['savedAt'] as String)
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'spoonacularId': spoonacularId,
        'title': title,
        'imageUrl': imageUrl,
        'phaseName': phaseName,
        'savedAt': savedAt.toIso8601String(),
        'notes': notes,
      };
}
