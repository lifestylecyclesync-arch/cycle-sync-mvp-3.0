import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_phase_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class DayHeader extends StatelessWidget {
  final String label;

  const DayHeader({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    final days = <DateTime>[];
    
    // Add empty days for days before month starts
    for (int i = 1; i < firstWeekday; i++) {
      days.add(DateTime(month.year, month.month, 1 - (firstWeekday - i)));
    }
    
    // Add all days in month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    
    // Add empty days for remaining weeks
    while (days.length % 7 != 0) {
      days.add(DateTime(month.year, month.month + 1, days.length - daysInMonth + 1));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_currentMonth);
    
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Month header with navigation
            Padding(
              padding: EdgeInsets.all(AppConstants.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            
            // Day names header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
              child: Row(
                children: const [
                  DayHeader(label: 'Sun'),
                  DayHeader(label: 'Mon'),
                  DayHeader(label: 'Tue'),
                  DayHeader(label: 'Wed'),
                  DayHeader(label: 'Thu'),
                  DayHeader(label: 'Fri'),
                  DayHeader(label: 'Sat'),
                ],
              ),
            ),
            
            // Calendar grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isCurrentMonth = day.month == _currentMonth.month;
                    
                    return GestureDetector(
                      onTap: isCurrentMonth ? () {
                        _showDailyCard(context, day);
                      } : null,
                      child: isCurrentMonth
                          ? ref.watch(cyclePhaseProvider(day)).when(
                              data: (phaseInfo) {
                                // Convert hex color code to Color
                                final colorCode = phaseInfo.colorCode;
                                final hexColor = colorCode.replaceFirst('#', '');
                                final color = Color(int.parse('ff$hexColor', radix: 16));
                                
                                return Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color.withOpacity(0.7),
                                    border: Border.all(
                                      color: color,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                              loading: () => Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade300,
                                ),
                                child: Text('${day.day}'),
                              ),
                              error: (_, __) => Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade300,
                                ),
                                child: Text('${day.day}'),
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  void _showDailyCard(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => DailyCardSheet(
        date: date,
        onSelectionsChanged: () {
          // Force parent to rebuild when selections change
          setState(() {});
        },
      ),
    );
  }
}

class DailyCardSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final VoidCallback? onSelectionsChanged;

  const DailyCardSheet({
    required this.date,
    this.onSelectionsChanged,
    super.key,
  });

  @override
  ConsumerState<DailyCardSheet> createState() => _DailyCardSheetState();
}

class _DailyCardSheetState extends ConsumerState<DailyCardSheet> {
  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with phase info
                ref.watch(cyclePhaseProvider(widget.date)).when(
                  data: (phaseInfo) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${phaseInfo.dayOfCycle} • ${phaseInfo.lifestylePhase}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacingSm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${phaseInfo.displayName} Phase (Days ${phaseInfo.startDay}–${phaseInfo.endDay})',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                          ],
                        ),
                        SizedBox(height: AppConstants.spacingMd),
                      ],
                    );
                  },
                  loading: () => SizedBox(height: AppConstants.spacingMd),
                  error: (_, __) => SizedBox(height: AppConstants.spacingMd),
                ),
                
                // Progress summary line showing actions done vs planned
                if (ref.watch(userIdProvider) != null)
                  ref.watch(dailySelectionsProvider(widget.date)).when(
                    data: (selections) {
                      final selectedRecipesJson = selections?['selected_recipes'] as String?;
                      final selectedWorkoutsJson = selections?['selected_workouts'] as String?;
                      final selectedFastingHours = selections?['selected_fasting_hours'];
                      
                      final completedRecipesJson = selections?['completed_recipes'] as String?;
                      final completedWorkoutsJson = selections?['completed_workouts'] as String?;
                      final completedFastingHours = selections?['completed_fasting_hours'];
                
                int doneCount = 0;
                int plannedCount = 0;
                
                // Count planned recipes (Y - in today's plan)
                if (selectedRecipesJson != null && selectedRecipesJson.isNotEmpty) {
                  try {
                    final recipes = List<String>.from(jsonDecode(selectedRecipesJson) as List);
                    plannedCount += recipes.length;
                  } catch (e) {
                    print('[Error] Failed to parse recipes: $e');
                  }
                }
                
                // Count completed recipes (X - actually logged)
                if (completedRecipesJson != null && completedRecipesJson.isNotEmpty) {
                  try {
                    final completed = List<String>.from(jsonDecode(completedRecipesJson) as List);
                    doneCount += completed.length;
                  } catch (e) {
                    print('[Error] Failed to parse completed recipes: $e');
                  }
                }
                
                // Count planned workouts (Y - in today's plan)
                if (selectedWorkoutsJson != null && selectedWorkoutsJson.isNotEmpty) {
                  try {
                    final workouts = List<String>.from(jsonDecode(selectedWorkoutsJson) as List);
                    plannedCount += workouts.length;
                  } catch (e) {
                    print('[Error] Failed to parse workouts: $e');
                  }
                }
                
                // Count completed workouts (X - actually logged)
                if (completedWorkoutsJson != null && completedWorkoutsJson.isNotEmpty) {
                  try {
                    final completed = List<String>.from(jsonDecode(completedWorkoutsJson) as List);
                    doneCount += completed.length;
                  } catch (e) {
                    print('[Error] Failed to parse completed workouts: $e');
                  }
                }
                
                // Count planned fasting if selected for today (Y)
                if (selectedFastingHours != null && selectedFastingHours is num && selectedFastingHours > 0) {
                  plannedCount += 1;
                }
                
                // Count fasting as done only if completed (X)
                if (completedFastingHours != null && completedFastingHours is num && completedFastingHours > 0) {
                  doneCount += 1;
                }
                
                return Padding(
                  padding: EdgeInsets.only(bottom: AppConstants.spacingMd),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMd,
                      vertical: AppConstants.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actions done',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '$doneCount / $plannedCount',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                },
                loading: () => SizedBox(height: AppConstants.spacingSm),
                error: (_, __) => SizedBox(height: AppConstants.spacingSm),
              ),
            
            // Lifestyle areas from phase recommendations
            userProfile.when(
              data: (profile) {
                if (profile == null) {
                  return Text('Please complete your profile first',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                
                final fastingPref = profile.fastingPreference ?? '';
                if (fastingPref.isEmpty) {
                  return Text('Please set fasting preference in your profile',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                
                // Get current phase info
                return ref.watch(currentPhaseProvider).when(
                  data: (phaseInfo) {
                    final phaseName = phaseInfo.lifestylePhase;
                    
                    return ref.watch(phaseRecommendationsProvider(phaseName)).when(
                      data: (phaseData) {
                        if (phaseData == null) {
                          return Text('No recommendations available',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        }
                        
                        final recommendationsAsync = ref.watch(phaseRecommendationsProvider(phaseName));
                        
                        // Watch selected lifestyle areas from Supabase (single source of truth)
                        return ref.watch(lifestyleAreasProvider).when(
                          data: (selectedAreas) {
                            final suggestion = LifestyleSuggestion(
                              foodVibe: phaseData['food_vibe'] ?? 'Balanced',
                              workoutMode: phaseData['workout_mode'] ?? 'Moderate',
                              fastStyleBeginner: phaseData['fast_style_beginner'] ?? '14h',
                              fastStyleAdvanced: phaseData['fast_style_advanced'] ?? '18h',
                              lifestylePhase: phaseName,
                              hormonalPhase: phaseInfo.hormonePhase,
                            );
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nutrition Module - shown if selected
                                if (selectedAreas.contains('Nutrition'))
                                  _buildNutritionModule(
                                    context,
                                    ref,
                                    phaseData['food_vibe'] ?? 'Balanced',
                                    phaseName,
                                    widget.date,
                                    recommendationsAsync,
                                  ),
                                
                                // Fitness Module - shown if selected
                                if (selectedAreas.contains('Fitness'))
                                  _buildFitnessModule(
                                    context,
                                    ref,
                                    phaseData['workout_mode'] ?? 'Moderate',
                                    phaseName,
                                    widget.date,
                                    recommendationsAsync,
                                  ),
                                
                                // Fasting Module - shown if selected
                                if (selectedAreas.contains('Fasting'))
                                  _buildFastingModule(
                                    context,
                                    ref,
                                    suggestion,
                                    fastingPref,
                                    widget.date,
                                  ),
                              ],
                            );
                          },
                          loading: () => Column(
                            children: [
                              // Show modules while loading
                              _buildNutritionModule(
                                context,
                                ref,
                                phaseData['food_vibe'] ?? 'Balanced',
                                phaseName,
                                widget.date,
                                recommendationsAsync,
                              ),
                              _buildFitnessModule(
                                context,
                                ref,
                                phaseData['workout_mode'] ?? 'Moderate',
                                phaseName,
                                widget.date,
                                recommendationsAsync,
                              ),
                            ],
                          ),
                          error: (err, stack) => Text('Error loading lifestyle areas: $err'),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Text('Error loading recommendations: $err'),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => Text('Error determining current phase: $err'),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Text('Error loading profile: $err'),
            ),
            
            // Bottom action buttons
            SizedBox(height: AppConstants.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Log notes button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.note_add),
                    label: const Text('Log Notes'),
                    onPressed: () {
                      _showNoteModal(context, widget.date, ref);
                    },
                  ),
                ),
                SizedBox(width: AppConstants.spacingMd),
                // Update lifestyle areas button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Areas'),
                    onPressed: () {
                      final currentAreas = ref.read(cachedLifestyleAreasProvider);
                      _showAddLifestyleAreaModal(context, ref, currentAreas);
                    },
                  ),
                ),
              ],
            ),
            ],
          ),
          ),
        );
      },
    );
  }



  Widget _buildNutritionModule(
    BuildContext context,
    WidgetRef ref,
    String foodVibe,
    String phaseName,
    DateTime selectedDate,
    AsyncValue<Map<String, dynamic>?> recommendationsAsync,
  ) {
    final userId = ref.watch(userIdProvider);

    return recommendationsAsync.when(
      data: (data) {
        if (data == null) {
          return _buildModule(context, 'Diet', foodVibe);
        }
        
        final recipes = (data['food_recipes'] as String?)?.split(' • ') ?? [];
        return Padding(
          padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Padding(
                padding: EdgeInsets.only(left: AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showDietModal(context, foodVibe, recipes, userId, selectedDate, ref);
                        },
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: AppConstants.spacingSm),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                foodVibe,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(width: AppConstants.spacingSm),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Show selected recipe if it exists
                    if (userId != null)
                ref.watch(dailySelectionsProvider(selectedDate)).when(
                  data: (selections) {
                    final selectedRecipesJson = selections?['selected_recipes'] as String?;
                    List<String> selectedRecipes = [];
                    
                    if (selectedRecipesJson != null && selectedRecipesJson.isNotEmpty) {
                      try {
                        selectedRecipes = List<String>.from(jsonDecode(selectedRecipesJson) as List);
                      } catch (e) {
                        print('[Error] Failed to parse recipes: $e');
                      }
                    }
                    
                    if (selectedRecipes.isEmpty) {
                      return SizedBox(height: AppConstants.spacingSm);
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppConstants.spacingMd),
                        Padding(
                          padding: EdgeInsets.only(left: AppConstants.spacingMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Plan:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: AppConstants.spacingSm),
                              ...selectedRecipes.map((recipe) => Padding(
                                padding: EdgeInsets.only(bottom: AppConstants.spacingSm, left: AppConstants.spacingMd),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: AppConstants.spacingSm),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit button
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Edit recipe coming soon')),
                                            );
                                          },
                                          tooltip: 'Edit recipe',
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        // Swap button
                                        IconButton(
                                          icon: Icon(
                                            Icons.swap_horiz,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () {
                                            _showSwapRecipeModal(context, recipe, recipes, userId, selectedDate, ref);
                                          },
                                          tooltip: 'Swap recipe',
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        // Log button
                                        IconButton(
                                          icon: Icon(
                                            Icons.check_circle_outline,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () async {
                                            HapticFeedback.lightImpact();
                                            final userId = ref.read(userIdProvider);
                                            if (userId != null) {
                                              try {
                                                await ref.read(dailySelectionsRepositoryProvider)
                                                    .logRecipe(userId, selectedDate, recipe);
                                                print('[DailyCard] Recipe logged');
                                                // Refresh the provider after logging completes
                                                unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('✓ Logged: $recipe'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                print('[Error] Failed to log: $e');
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error: Failed to log recipe')),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          tooltip: 'Log recipe',
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () async {
                                            HapticFeedback.lightImpact();
                                            try {
                                              await ref.read(dailySelectionsRepositoryProvider)
                                                  .deleteRecipe(userId, selectedDate, recipe);
                                              print('[DailyCard] Recipe deleted');
                                              // Refresh the provider after deletion completes
                                              unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('✓ Removed: $recipe'),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print('[Error] Delete failed: $e');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: Failed to remove recipe'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          tooltip: 'Remove recipe',
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Padding(
                    padding: EdgeInsets.only(top: AppConstants.spacingMd),
                    child: const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, stack) => SizedBox(height: AppConstants.spacingSm),
                )
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Vibe',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
      error: (err, stack) => _buildModule(context, 'Food Vibe', foodVibe),
    );
  }

  Widget _buildFitnessModule(
    BuildContext context,
    WidgetRef ref,
    String workoutMode,
    String phaseName,
    DateTime selectedDate,
    AsyncValue<Map<String, dynamic>?> recommendationsAsync,
  ) {
    print('[DEBUG] _buildFitnessModule called with workoutMode: $workoutMode, phaseName: $phaseName');
    final userId = ref.watch(userIdProvider);

    return recommendationsAsync.when(
      data: (data) {
        if (data == null) {
          // Show clickable workout mode even when recommendation data is null
          return Padding(
            padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    print('[DEBUG] Workout tapped (from fallback) - workoutMode: $workoutMode');
                    // Fetch data and show modal
                    ref.read(phaseRecommendationsProvider(phaseName)).whenData((recData) {
                      if (recData != null) {
                        final workouts = (recData['workout_types'] as String?)?.split(' • ') ?? [];
                        _showWorkoutTypesModal(context, workoutMode, workouts, userId, selectedDate, ref);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No workout types available for this phase'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  },
                  splashColor: Colors.blue.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: 'Workout: ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: workoutMode,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: AppConstants.spacingLg,
                  color: Colors.grey.shade200,
                ),
              ],
            ),
          );
        }
        
        final workouts = (data['workout_types'] as String?)?.split(' • ') ?? [];
        
        return Padding(
          padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Padding(
                padding: EdgeInsets.only(left: AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          print('[DEBUG] Workout tapped - workouts count: ${workouts.length}, userId: $userId');
                          _showWorkoutTypesModal(context, workoutMode, workouts, userId, selectedDate, ref);
                        },
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: AppConstants.spacingSm),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                workoutMode,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(width: AppConstants.spacingSm),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Show selected workout if it exists
                    if (userId != null)
                      ref.watch(dailySelectionsProvider(selectedDate)).when(
                        data: (selections) {
                          final selectedWorkoutsJson = selections?['selected_workouts'] as String?;
                          List<String> selectedWorkouts = [];
                          
                          if (selectedWorkoutsJson != null && selectedWorkoutsJson.isNotEmpty) {
                            try {
                              selectedWorkouts = List<String>.from(jsonDecode(selectedWorkoutsJson) as List);
                            } catch (e) {
                              print('[Error] Failed to parse workouts: $e');
                            }
                          }
                          
                          if (selectedWorkouts.isEmpty) {
                            return SizedBox(height: AppConstants.spacingSm);
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: AppConstants.spacingMd),
                              Padding(
                                padding: EdgeInsets.only(left: AppConstants.spacingMd),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Today\'s Plan:',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: AppConstants.spacingSm),
                                    ...selectedWorkouts.map((workout) {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: AppConstants.spacingSm, left: AppConstants.spacingMd),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                workout,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            // Edit button
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                size: 24,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Edit workout coming soon')),
                                                );
                                              },
                                              tooltip: 'Edit workout',
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                            ),
                                            // Swap button
                                            IconButton(
                                              icon: Icon(
                                                Icons.swap_horiz,
                                                size: 24,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () {
                                                // Show available workouts to swap
                                                ref.read(phaseRecommendationsProvider(phaseName)).whenData((recData) {
                                                  if (recData != null) {
                                                    final workouts = (recData['workout_types'] as String?)?.split(' • ') ?? [];
                                                    _showSwapWorkoutModal(context, workout, workouts, userId, selectedDate, ref, phaseName);
                                                  }
                                                });
                                              },
                                              tooltip: 'Swap workout',
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                            ),
                                            // Log button
                                            IconButton(
                                              icon: Icon(
                                                Icons.check_circle_outline,
                                                size: 24,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  final userId = ref.read(userIdProvider);
                                                  if (userId != null) {
                                                    // Add to completed workouts
                                                    final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                                                    
                                                    final existing = await SupabaseConfig.client
                                                        .from('user_daily_selections')
                                                        .select()
                                                        .eq('user_id', userId)
                                                        .eq('selection_date', dateStr)
                                                        .maybeSingle();
                                                    
                                                    List<String> completedWorkouts = [];
                                                    if (existing != null && existing['completed_workouts'] != null && (existing['completed_workouts'] as String).isNotEmpty) {
                                                      try {
                                                        completedWorkouts = List<String>.from(jsonDecode(existing['completed_workouts']) as List);
                                                      } catch (e) {
                                                        print('Error parsing completed workouts: $e');
                                                      }
                                                    }
                                                    
                                                    if (!completedWorkouts.contains(workout)) {
                                                      completedWorkouts.add(workout);
                                                    }
                                                    
                                                    await SupabaseConfig.client
                                                        .from('user_daily_selections')
                                                        .update({
                                                          'completed_workouts': jsonEncode(completedWorkouts),
                                                          'updated_at': DateTime.now().toIso8601String(),
                                                        })
                                                        .eq('user_id', userId)
                                                        .eq('selection_date', dateStr);
                                                    
                                                    // Refresh the provider after logging completes
                                                    unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('✓ Logged: $workout'),
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error logging workout: $e')),
                                                  );
                                                }
                                              },
                                              tooltip: 'Log workout',
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                            ),
                                            // Delete button
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                size: 24,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  await ref.read(dailySelectionsRepositoryProvider).deleteWorkout(
                                                    userId,
                                                    selectedDate,
                                                    workout,
                                                  );
                                                  // Refresh the provider after deletion completes
                                                  unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('✓ Removed: $workout'),
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error removing workout: $e'),
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                              tooltip: 'Remove workout',
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => Padding(
                          padding: EdgeInsets.only(top: AppConstants.spacingMd),
                          child: const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (err, stack) => SizedBox(height: AppConstants.spacingSm),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
      error: (err, stack) => _buildModule(context, 'Workout', workoutMode),
    );
  }

  Widget _buildModule(
    BuildContext context,
    String title,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppConstants.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Divider(
            height: AppConstants.spacingLg,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildFastingModule(
    BuildContext context,
    WidgetRef ref,
    LifestyleSuggestion suggestion,
    String preference,
    DateTime selectedDate,
  ) {
    final fastStyle = preference == 'Beginner'
        ? suggestion.fastStyleBeginner
        : suggestion.fastStyleAdvanced;

    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fasting',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: AppConstants.spacingSm),
          Padding(
            padding: EdgeInsets.only(left: AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showFastingTypesModal(context, suggestion, selectedDate, ref);
                    },
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: AppConstants.spacingSm),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fastStyle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(width: AppConstants.spacingSm),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.spacingMd),
                // Today's Plan section
                ref.watch(dailySelectionsProvider(selectedDate)).when(
                  data: (selections) {
                    final selectedHours = selections?['selected_fasting_hours'];
                    return selectedHours != null && selectedHours > 0
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Plan",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: AppConstants.spacingSm),
                              Padding(
                                padding: EdgeInsets.only(left: AppConstants.spacingMd),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${selectedHours.toStringAsFixed(0)}h fast',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Edit button
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 24,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () {
                                        _showFastingTypesModal(context, suggestion, selectedDate, ref);
                                      },
                                      tooltip: 'Edit fasting hours',
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                    // Log button
                                    IconButton(
                                      icon: Icon(
                                        Icons.check_circle_outline,
                                        size: 24,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () async {
                                        HapticFeedback.lightImpact();
                                        final userId = ref.read(userIdProvider);
                                        if (userId != null) {
                                          final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                                          try {
                                            await ref.read(dailySelectionsRepositoryProvider)
                                                .logFastingHours(userId, dateStr, selectedHours);
                                            print('[DailyCard] Fasting logged');
                                            // Refresh the provider after logging completes
                                            unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('✓ Logged: ${selectedHours.toStringAsFixed(0)}h fast'),
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print('[Error] Failed to log fasting: $e');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: Failed to log fasting')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      tooltip: 'Log completed hours',
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 24,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () async {
                                        HapticFeedback.lightImpact();
                                        final userId = ref.read(userIdProvider);
                                        final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                                        if (userId != null) {
                                          try {
                                            await ref.read(dailySelectionsRepositoryProvider)
                                                .selectFastingHours(userId, dateStr, 0);
                                            await ref.read(dailySelectionsRepositoryProvider)
                                                .clearCompletedFastingHours(userId, dateStr);
                                            print('[DailyCard] Fasting cleared');
                                            // Refresh the provider after deletion completes
                                            unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('✓ Removed fasting selection')),
                                              );
                                            }
                                          } catch (e) {
                                            print('[Error] Failed to clear: $e');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: Failed to remove fasting')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      tooltip: 'Remove selection',
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : SizedBox.shrink();
                  },
                  loading: () => SizedBox.shrink(),
                  error: (_, __) => SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Divider(
            height: AppConstants.spacingLg,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  void _showNoteModal(BuildContext context, DateTime date, WidgetRef ref) {
    final textController = TextEditingController();
    
    // Load existing note if any
    ref.watch(dailyNoteProvider(date)).whenData((existingNote) {
      if (existingNote != null && existingNote.isNotEmpty) {
        textController.text = existingNote;
      }
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Notes'),
        content: TextField(
          controller: textController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Add your notes for the day...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final noteText = textController.text.trim();
              try {
                if (noteText.isEmpty) {
                  // Delete note if empty
                  await ref.read(deleteDailyNoteProvider(date).future);
                } else {
                  // Save note
                  await ref.read(saveDailyNoteProvider((date: date, noteText: noteText)).future);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Note saved')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving note: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddLifestyleAreaModal(
    BuildContext context,
    WidgetRef ref,
    List<String> currentAreas,
  ) {
    final categoriesAsync = ref.watch(lifestyleCategoriesProvider);
    final selectedAreas = List<String>.from(currentAreas);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => categoriesAsync.when(
          data: (areas) => AlertDialog(
            title: const Text('Update Lifestyle Areas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: areas.map((area) {
                final isSelected = selectedAreas.contains(area);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    // Instant haptic feedback on checkbox tap
                    HapticFeedback.selectionClick();
                    
                    setState(() {
                      if (value == true) {
                        selectedAreas.add(area);
                      } else {
                        selectedAreas.remove(area);
                      }
                    });
                  },
                  title: Text(area),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Instant haptic feedback
                  HapticFeedback.mediumImpact();
                  
                  // Show loading state or success immediately
                  Navigator.pop(context);
                  
                  // Transaction: save to backend and confirm with provider update
                  try {
                    // Save to backend
                    await ref.read(updateLifestyleAreasProvider(selectedAreas).future);
                    print('[DailyCard] Lifestyle areas saved to backend');
                    
                    // Refresh provider to confirm the change - clears optimistic state
                    unawaited(ref.refresh(lifestyleAreasProvider.future));
                    print('[DailyCard] Provider refreshed after save');
                    
                    // Show confirmation only after transaction succeeds
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Lifestyle areas updated'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    print('[Error] Failed to update lifestyle areas: $e');
                    // Show error recovery dialog with retry option
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) => AlertDialog(
                          title: const Text('Failed to Save'),
                          content: Text('Could not update lifestyle areas: $e\n\nTry again?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showAddLifestyleAreaModal(context, ref, selectedAreas);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
          loading: () => AlertDialog(
            title: const Text('Loading...'),
            content: const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load categories: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDietModal(
    BuildContext context,
    String foodVibe,
    List<String> recipes,
    String? userId,
    DateTime selectedDate,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Recipe',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Text(
                foodVibe,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppConstants.spacingMd),
              if (recipes.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                  child: Text(
                    'No recipes available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: recipes
                        .map((recipe) {
                          // Handle both authenticated and guest modes
                          if (userId != null) {
                            // Authenticated mode: use provider
                            return ref.watch(dailySelectionsProvider(selectedDate)).when(
                              data: (selections) {
                                final selectedRecipesJson = selections?['selected_recipes'] as String?;
                                List<String> selectedRecipes = [];
                                
                                if (selectedRecipesJson != null && selectedRecipesJson.isNotEmpty) {
                                  try {
                                    selectedRecipes = List<String>.from(jsonDecode(selectedRecipesJson) as List);
                                  } catch (e) {
                                    print('[Error] Failed to parse recipes: $e');
                                  }
                                }
                                
                                final isSelected = selectedRecipes.contains(recipe.trim());
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        // Instant haptic feedback
                                        HapticFeedback.lightImpact();
                                        
                                        print('[DEBUG] Recipe tapped: $recipe, userId: $userId, date: $selectedDate');
                                        final selectionsRepo = ref.read(dailySelectionsRepositoryProvider);
                                        
                                        // Close modal immediately for UX
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                        
                                        // Save in foreground and then refresh
                                        try {
                                          print('[DEBUG] About to toggle recipe: $recipe');
                                          if (isSelected) {
                                            // Deselect: remove this recipe
                                            await selectionsRepo.deleteRecipe(userId, selectedDate, recipe.trim());
                                            print('[DEBUG] Recipe deselected');
                                          } else {
                                            // Select: remove any existing recipe and add new one
                                            if (selectedRecipes.isNotEmpty) {
                                              await selectionsRepo.deleteRecipe(userId, selectedDate, selectedRecipes[0]);
                                            }
                                            await selectionsRepo.selectRecipe(userId, selectedDate, recipe.trim());
                                            print('[DEBUG] Recipe selected');
                                          }
                                          // Refresh after operation completes
                                          unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                        } catch (e) {
                                          print('[ERROR] Failed to toggle recipe: $e');
                                        }
                                        
                                        // Show confirmation
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(isSelected ? '✗ ${recipe.trim()} removed' : '✓ ${recipe.trim()} selected'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppConstants.spacingMd,
                                          vertical: AppConstants.spacingSm,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? Center(
                                                      child: Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: AppConstants.spacingMd),
                                            Expanded(
                                              child: Text(
                                                recipe.trim(),
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: isSelected ? Colors.blue : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              loading: () => SizedBox.shrink(),
                              error: (_, __) => SizedBox.shrink(),
                            );
                          } else {
                            // Guest mode: no selection
                            return const SizedBox.shrink();
                          }
                        })
                        .toList(),
                  ),
                ),
              SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        );
      },
    );
  }

  void _showWorkoutTypesModal(
    BuildContext context,
    String workoutMode,
    List<String> workouts,
    String? userId,
    DateTime selectedDate,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Workout',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMd),
                  if (workouts.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                      child: Text(
                        'No workout types available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: workouts
                            .map((workout) {
                              // Handle both authenticated and guest modes
                              if (userId != null) {
                                // Authenticated mode: use provider
                                return ref.watch(dailySelectionsProvider(selectedDate)).when(
                                  data: (selections) {
                                    final selectedWorkoutsJson = selections?['selected_workouts'] as String?;
                                    List<String> selectedWorkouts = [];
                                    
                                    if (selectedWorkoutsJson != null && selectedWorkoutsJson.isNotEmpty) {
                                      try {
                                        selectedWorkouts = List<String>.from(jsonDecode(selectedWorkoutsJson) as List);
                                      } catch (e) {
                                        print('[Error] Failed to parse workouts: $e');
                                      }
                                    }
                                    
                                    final isSelected = selectedWorkouts.contains(workout.trim());
                                    
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () async {
                                            HapticFeedback.lightImpact();
                                            final selectionsRepo = ref.read(dailySelectionsRepositoryProvider);
                                            
                                            // Close modal immediately for UX
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                            
                                            // Save in foreground and then refresh
                                            try {
                                              if (isSelected) {
                                                // Deselect: remove this workout
                                                await selectionsRepo.deleteWorkout(userId, selectedDate, workout.trim());
                                                print('[DailyCard] Workout deselected: ${workout.trim()}');
                                              } else {
                                                // Select: add this workout
                                                await selectionsRepo.selectWorkout(userId, selectedDate, workout.trim());
                                                print('[DailyCard] Workout selected: ${workout.trim()}');
                                              }
                                              // Refresh the provider after operation completes
                                              unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(isSelected ? '✗ ${workout.trim()} removed' : '✓ ${workout.trim()} selected'),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print('[Error] Failed to toggle workout: $e');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error: Failed to update workout')),
                                                );
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppConstants.spacingMd,
                                              vertical: AppConstants.spacingSm,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected ? Colors.blue : Colors.grey.shade400,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: isSelected
                                                      ? Center(
                                                          child: Container(
                                                            width: 12,
                                                            height: 12,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: Colors.blue,
                                                            ),
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                SizedBox(width: AppConstants.spacingMd),
                                                Expanded(
                                                  child: Text(
                                                    workout.trim(),
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                      color: isSelected ? Colors.blue : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => SizedBox.shrink(),
                                  error: (_, __) => SizedBox.shrink(),
                                );
                              } else {
                                // Guest mode: no selection
                                return const SizedBox.shrink();
                              }
                            })
                            .toList(),
                      ),
                    ),
                  SizedBox(height: AppConstants.spacingMd),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSwapWorkoutModal(
    BuildContext context,
    String currentWorkout,
    List<String> availableWorkouts,
    String? userId,
    DateTime selectedDate,
    WidgetRef ref,
    String phaseName,
  ) {
    // Filter to show workouts other than the current one
    final otherWorkouts = availableWorkouts.where((w) => w.trim() != currentWorkout.trim()).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Swap Workout',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Current: $currentWorkout',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingMd),
              if (otherWorkouts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                  child: Text(
                    'No other workout types available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: otherWorkouts
                        .map((workout) => Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (userId != null) {
                                  final selectionsRepo = ref.read(dailySelectionsRepositoryProvider);
                                  try {
                                    // First delete the current workout, then add the new one
                                    await selectionsRepo.deleteWorkout(userId, selectedDate, currentWorkout);
                                    await selectionsRepo.selectWorkout(userId, selectedDate, workout.trim());
                                    if (context.mounted) {
                                      ref.invalidate(dailySelectionsProvider(selectedDate));
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✓ Swapped to ${workout.trim()}'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error swapping workout: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingMd,
                                  vertical: AppConstants.spacingSm,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppConstants.spacingMd),
                                    Expanded(
                                      child: Text(
                                        workout.trim(),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                        .toList(),
                  ),
                ),
              SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        );
      },
    );
  }

  void _showSwapRecipeModal(
    BuildContext context,
    String currentRecipe,
    List<String> availableRecipes,
    String? userId,
    DateTime selectedDate,
    WidgetRef ref,
  ) {
    // Filter to show recipes other than the current one
    final otherRecipes = availableRecipes.where((r) => r.trim() != currentRecipe.trim()).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swap Recipe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: AppConstants.spacingMd),
                      child: Text(
                        'Current: $currentRecipe',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingMd),
              if (otherRecipes.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                  child: Text(
                    'No other recipes available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: otherRecipes
                        .map((recipe) => Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                if (userId != null) {
                                  final selectionsRepo = ref.read(dailySelectionsRepositoryProvider);
                                  // Close modal immediately for UX
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                  // Save and refresh
                                  try {
                                    await selectionsRepo.deleteRecipe(userId, selectedDate, currentRecipe);
                                    await selectionsRepo.selectRecipe(userId, selectedDate, recipe.trim());
                                    print('[DailyCard] Recipe swapped to ${recipe.trim()}');
                                    // Refresh the provider after swap completes
                                    unawaited(ref.refresh(dailySelectionsProvider(selectedDate).future));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✓ Swapped to ${recipe.trim()}'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('[Error] Failed to swap recipe: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: Failed to swap recipe')),
                                      );
                                    }
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingMd,
                                  vertical: AppConstants.spacingSm,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppConstants.spacingMd),
                                    Expanded(
                                      child: Text(
                                        recipe.trim(),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showFastingAddPlanModal(
    BuildContext context,
    LifestyleSuggestion suggestion,
    DateTime selectedDate,
    WidgetRef ref,
  ) {
    // Parse suggested hours for both preference levels
    double beginnerHours = 14.0;
    double advancedHours = 18.0;
    
    final beginnerMatch = RegExp(r'(\d+)h').firstMatch(suggestion.fastStyleBeginner);
    if (beginnerMatch != null) {
      beginnerHours = double.parse(beginnerMatch.group(1)!).toDouble();
    }
    
    final advancedMatch = RegExp(r'(\d+)h').firstMatch(suggestion.fastStyleAdvanced);
    if (advancedMatch != null) {
      advancedHours = double.parse(advancedMatch.group(1)!).toDouble();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Fasting to Plan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: AppConstants.spacingSm),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final userId = ref.read(userIdProvider);
                          if (userId != null) {
                            final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                            ref.invalidate(dailySelectionsProvider(selectedDate));
                            ref.read(dailySelectionsRepositoryProvider)
                                .selectFastingHours(userId, dateStr, beginnerHours)
                                .then((_) => print('[DailyCard] Fasting hours saved'))
                                .catchError((e) => print('[Error] Failed to save fasting: $e'));
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Added ${beginnerHours.toStringAsFixed(0)}h fast to today\'s plan'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Text('Beginner\n${beginnerHours.toStringAsFixed(0)}h'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: AppConstants.spacingSm),
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final userId = ref.read(userIdProvider);
                          if (userId != null) {
                            final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                            ref.invalidate(dailySelectionsProvider(selectedDate));
                            ref.read(dailySelectionsRepositoryProvider)
                                .selectFastingHours(userId, dateStr, advancedHours)
                                .then((_) => print('[DailyCard] Fasting hours saved'))
                                .catchError((e) => print('[Error] Failed to save fasting: $e'));
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Added ${advancedHours.toStringAsFixed(0)}h fast to today\'s plan'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Text('Advanced\n${advancedHours.toStringAsFixed(0)}h'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        );
      },
    );
  }

  void _showFastingTypesModal(
    BuildContext context,
    LifestyleSuggestion suggestion,
    DateTime selectedDate,
    WidgetRef ref,
  ) {
    // Parse fasting options
    double beginnerHours = 14.0;
    double advancedHours = 18.0;
    
    final beginnerMatch = RegExp(r'(\d+)h').firstMatch(suggestion.fastStyleBeginner);
    if (beginnerMatch != null) {
      beginnerHours = double.parse(beginnerMatch.group(1)!).toDouble();
    }
    
    final advancedMatch = RegExp(r'(\d+)h').firstMatch(suggestion.fastStyleAdvanced);
    if (advancedMatch != null) {
      advancedHours = double.parse(advancedMatch.group(1)!).toDouble();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        // Read current preference from state (only once)
        bool isAdvanced = false;
        double customHours = beginnerHours;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(AppConstants.spacingMd),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Select Fasting',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMd),
                  // Toggle Switch for Beginner/Advanced
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Beginner',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: !isAdvanced ? FontWeight.w600 : FontWeight.w500,
                            color: !isAdvanced ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(width: AppConstants.spacingMd),
                        GestureDetector(
                          onTap: () => setState(() {
                            isAdvanced = !isAdvanced;
                            customHours = isAdvanced ? advancedHours : beginnerHours;
                          }),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 100,
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: isAdvanced ? Colors.blue.shade300 : Colors.grey.shade300,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                AnimatedAlign(
                                  alignment: isAdvanced ? Alignment.centerRight : Alignment.centerLeft,
                                  duration: Duration(milliseconds: 300),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 3),
                                    child: Container(
                                      width: 50,
                                      height: 41,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: AppConstants.spacingMd),
                        Text(
                          'Advanced',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isAdvanced ? FontWeight.w600 : FontWeight.w500,
                            color: isAdvanced ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMd),
                  // Slider for custom hours
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fasting Hours',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${customHours.toStringAsFixed(1)}h',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppConstants.spacingSm),
                        Slider(
                          value: customHours,
                          min: 8.0,
                          max: 24.0,
                          divisions: 32,
                          onChanged: (value) => setState(() => customHours = value),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMd),
                  // Suggested options or custom selection
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final userId = ref.read(userIdProvider);
                          if (userId != null) {
                            final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                            await ref.read(dailySelectionsRepositoryProvider).selectFastingHours(
                              userId,
                              dateStr,
                              customHours,
                            );
                            if (context.mounted) {
                              ref.invalidate(dailySelectionsProvider(selectedDate));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ ${customHours.toStringAsFixed(1)}h ${isAdvanced ? 'Advanced' : 'Beginner'} fast selected'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving selection: $e')),
                            );
                          }
                        }
                      },
                      child: Text('Add to Plan'),
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMd),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }


  void _showFastingPreferenceModal(BuildContext context, String currentPreference, String beginnerStyle, String advancedStyle, WidgetRef ref) {
    // Placeholder method for backward compatibility
    // Parse suggested hours for both preference levels
    double beginnerHours = 14.0;
    double advancedHours = 18.0;
    
    final beginnerMatch = RegExp(r'(\d+)h').firstMatch(beginnerStyle);
    if (beginnerMatch != null) {
      beginnerHours = double.parse(beginnerMatch.group(1)!).toDouble();
    }
    
    final advancedMatch = RegExp(r'(\d+)h').firstMatch(advancedStyle);
    if (advancedMatch != null) {
      advancedHours = double.parse(advancedMatch.group(1)!).toDouble();
    }
    
    // Initialize state variables outside the builder but inside the function
    bool isAdvanced = currentPreference == 'Advanced';
    // Clamp to valid range: 8-24 hours for both modes
    double durationHours = (isAdvanced ? advancedHours : beginnerHours).clamp(8.0, 24.0);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fasting Preference',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMd),
                  
                  // Toggle Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Experience Level',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacingSm),
                          Text(
                            isAdvanced ? 'Advanced' : 'Beginner',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isAdvanced,
                        onChanged: (value) {
                          setState(() {
                            isAdvanced = value;
                            // Keep the current hours when toggling mode (both use 8-24 range)
                          });
                        },
                        activeThumbColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: AppConstants.spacingLg),
                  
                  // Duration Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacingSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${durationHours.toStringAsFixed(0)}h',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            '(8h - 24h)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.spacingSm),
                      Slider(
                        value: durationHours,
                        min: 8.0,
                        max: 24.0,
                        divisions: 16,
                        onChanged: (value) {
                          setState(() {
                            durationHours = value;
                          });
                        },
                        label: '${durationHours.toStringAsFixed(0)}h',
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: AppConstants.spacingLg),
                  
                  // Buttons Row
                  Row(
                    children: [
                      // Save to Today's Plan Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
                          ),
                          onPressed: () async {
                            try {
                              final today = DateTime.now();
                              final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                              final userId = ref.read(userIdProvider);
                              
                              if (userId != null) {
                                await ref.read(dailySelectionsRepositoryProvider).selectFastingHours(
                                  userId,
                                  dateStr,
                                  durationHours,
                                );
                                
                                if (context.mounted) {
                                  ref.invalidate(dailySelectionsProvider(today));
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✓ Added ${durationHours.toStringAsFixed(0)}h fast to today\'s plan'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving to plan: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Add to Plan'),
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingMd),
                      // Save Preference Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final preference = isAdvanced ? 'Advanced' : 'Beginner';
                            ref.invalidate(userProfileProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            ref.read(updateFastingPreferenceProvider(preference).future)
                                .then((_) => print('[DailyCard] Preference saved: $preference'))
                                .catchError((e) => print('[Error] Failed to save preference: $e'));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Preference set to $preference'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: const Text('Save Preference'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }}