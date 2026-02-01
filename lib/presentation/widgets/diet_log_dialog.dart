import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/diet_logs_provider.dart';
import 'package:logger/logger.dart';

/// Diet Log Dialog
void showDietLogDialog(BuildContext context, WidgetRef ref, {DateTime? selectedDate}) {
  final Logger logger = Logger();
  String selectedMealType = 'Breakfast';
  List<String> foodItems = [];
  String currentFood = '';
  int? calories;

  final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Log Meal'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Type
                  Text('Meal Type', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  DropdownButton<String>(
                    value: selectedMealType,
                    isExpanded: true,
                    items: mealTypes.map((meal) {
                      return DropdownMenuItem(
                        value: meal,
                        child: Text(meal),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedMealType = value ?? 'Breakfast');
                    },
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Food Items
                  Text('Food Items', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Add food item',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                          ),
                          onChanged: (value) => currentFood = value,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: () {
                          if (currentFood.isNotEmpty) {
                            setState(() {
                              foodItems.add(currentFood);
                              currentFood = '';
                            });
                          }
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Food items list
                  if (foodItems.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: foodItems.map((food) {
                        return Chip(
                          label: Text(food),
                          onDeleted: () {
                            setState(() => foodItems.remove(food));
                          },
                        );
                      }).toList(),
                    ),
                  SizedBox(height: AppSpacing.lg),

                  // Calories
                  Text('Calories (optional)', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Estimated calories',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      calories = int.tryParse(value);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (foodItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add at least one food item')),
                );
                return;
              }

              try {
                await ref.read(
                  createDietLogProvider(
                    (selectedMealType, foodItems, calories, null, selectedDate),
                  ).future,
                );

                logger.i('✅ Meal logged: $selectedMealType');
                
                // Invalidate providers to refresh UI with new meal
                ref.invalidate(todaysDietLogsProvider);
                ref.invalidate(dietLogsForDateProvider);
                
                // Give the invalidation time to propagate
                await Future.delayed(const Duration(milliseconds: 500));

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meal logged! 🍽️'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                logger.e('❌ Error logging meal: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Log Meal'),
          ),
        ],
      );
    },
  );
}
