import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/services/spoonacular_service.dart';
import 'package:cycle_sync_mvp_2/domain/entities/recipe.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/diet_logs_provider.dart';
import 'package:logger/logger.dart';

/// Meal Planning Dialog
/// Step 1: Shows 4 meal type options (Breakfast, Lunch, Dinner, Snack)
/// Step 2: Shows recipes for selected meal type
void showMealPlanDialog(BuildContext context, WidgetRef ref, {DateTime? selectedDate}) {

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _MealTypeSelectionDialog(selectedDate: selectedDate);
    },
  );
}

/// Step 1: Meal Type Selection
class _MealTypeSelectionDialog extends StatelessWidget {
  final DateTime? selectedDate;
  
  const _MealTypeSelectionDialog({this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final mealTypes = [
      {'type': 'Breakfast', 'icon': Icons.breakfast_dining, 'color': Colors.orange},
      {'type': 'Lunch', 'icon': Icons.lunch_dining, 'color': Colors.green},
      {'type': 'Dinner', 'icon': Icons.dinner_dining, 'color': Colors.indigo},
      {'type': 'Snack', 'icon': Icons.fastfood, 'color': Colors.amber},
    ];

    return AlertDialog(
      title: const Text('Plan Your Meal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a meal type'),
          SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: mealTypes.length,
            itemBuilder: (context, index) {
              final meal = mealTypes[index];
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showRecipeListDialog(
                    context,
                    meal['type'] as String,
                    selectedDate,
                  );
                },
                child: Card(
                  color: (meal['color'] as Color).withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        meal['icon'] as IconData,
                        size: 40,
                        color: meal['color'] as Color,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        meal['type'] as String,
                        style: AppTypography.subtitle2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showRecipeListDialog(BuildContext context, String mealType, DateTime? selectedDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _RecipeListDialog(mealType: mealType, selectedDate: selectedDate);
      },
    );
  }
}

/// Step 2: Recipe List for Selected Meal Type
class _RecipeListDialog extends StatefulWidget {
  final String mealType;
  final DateTime? selectedDate;

  const _RecipeListDialog({required this.mealType, this.selectedDate});

  @override
  State<_RecipeListDialog> createState() => _RecipeListDialogState();
}

class _RecipeListDialogState extends State<_RecipeListDialog> {
  late Future<List<Recipe>> recipeFuture;
  final spoonacularService = SpoonacularService();
  final Logger logger = Logger();
  final TextEditingController _customMealController = TextEditingController();

  @override
  void initState() {
    super.initState();
    recipeFuture = _getRecipesForMealType();
  }

  @override
  void dispose() {
    _customMealController.dispose();
    super.dispose();
  }

  Future<List<Recipe>> _getRecipesForMealType() async {
    try {
      final queries = {
        'Breakfast': 'breakfast eggs pancakes oatmeal smoothie',
        'Lunch': 'lunch sandwich pasta salad bowl',
        'Dinner': 'dinner chicken beef fish salmon',
        'Snack': 'snack protein bar nuts yogurt',
      };

      final query = queries[widget.mealType] ?? 'healthy recipes';
      return await spoonacularService.searchRecipes(
        query: query,
        number: 10,
        addRecipeInformation: true,
        fillIngredients: false,
      );
    } catch (e) {
      logger.e('Failed to fetch recipes: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.mealType} Recipes'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      content: FutureBuilder<List<Recipe>>(
        future: recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    const Text('Loading recipes...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.red),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Error loading recipes:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTypography.body2,
                    ),
                  ],
                ),
              ),
            );
          }

          final recipes = snapshot.data ?? [];

          return SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              children: [
                // Custom Meal Section
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Custom Meal',
                        style: AppTypography.subtitle2,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customMealController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Grilled chicken with rice',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Consumer(
                            builder: (context, ref, child) {
                              return ElevatedButton(
                                onPressed: _customMealController.text.isEmpty
                                    ? null
                                    : () {
                                        final mealName = _customMealController.text.trim();
                                        try {
                                          ref.read(createDietLogProvider((
                                            widget.mealType,
                                            [mealName],
                                            null,
                                            null,                                            widget.selectedDate,                                          )));

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${widget.mealType}: $mealName added!',
                                              ),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );

                                          _customMealController.clear();
                                          Navigator.pop(context);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error adding meal: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sage,
                                  disabledBackgroundColor: Colors.grey[300],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                ),
                                child: const Icon(Icons.add),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'Or Select from Suggestions',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                ),

                // Suggested Recipes List
                if (recipes.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No recipes found for ${widget.mealType}',
                        style: AppTypography.body2,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return _RecipeListTile(
                          recipe: recipe,
                          mealType: widget.mealType,
                          onSelected: () {
                            Navigator.pop(context);
                          },
                          selectedDate: widget.selectedDate,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
      ],
    );
  }
}

/// Individual Recipe List Tile
class _RecipeListTile extends StatelessWidget {
  final Recipe recipe;
  final String mealType;
  final VoidCallback onSelected;
  final DateTime? selectedDate;

  const _RecipeListTile({
    required this.recipe,
    required this.mealType,
    required this.onSelected,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            title: Text(
              recipe.title,
              style: AppTypography.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.xs),
                Text(
                    '${recipe.nutrition.calories} calories',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () {
              // Add meal to diet logs
              try {
                ref.read(createDietLogProvider((
                  mealType,
                  [recipe.title],
                  recipe.nutrition.calories.toInt(),
                  null,
                  selectedDate,
                )));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$mealType: ${recipe.title} added!',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                onSelected();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding meal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

