import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/month_selector.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/cycle_calendar_grid.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/planner_card.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/phase_provider.dart' as phase_providers;
import 'package:cycle_sync_mvp_2/presentation/providers/fitness_logs_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/templates_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_provider.dart' as cycle_providers;

/// Fitness Screen
/// Log workouts and track fitness activities
class FitnessScreen extends ConsumerStatefulWidget {
  const FitnessScreen({super.key});

  @override
  ConsumerState<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends ConsumerState<FitnessScreen> {
  late DateTime _selectedDate;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  /// Get the currently selected day (for dialog to use when adding workouts)
  DateTime? getSelectedDay() => _selectedDay;

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch phase definitions from database
    final phaseDefsAsync = ref.watch(phase_providers.phaseDefinitionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          MonthSelector(
            selectedDate: _selectedDate,
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
          ),

          // Calendar grid - Watch current cycle to display phases
          phaseDefsAsync.when(
            data: (phaseDefs) {
              return ref.watch(cycle_providers.currentCycleProvider).when(
                data: (cycle) {
                  return CycleCalendarGrid(
                    selectedDate: _selectedDate,
                    selectedDay: _selectedDay,
                    onDayTapped: _onDayTapped,
                    cycleStartDate: cycle?.startDate,
                    cycleLength: cycle?.length ?? 28,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, stack) => CycleCalendarGrid(
                  selectedDate: _selectedDate,
                  selectedDay: _selectedDay,
                  onDayTapped: _onDayTapped,
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => CycleCalendarGrid(
              selectedDate: _selectedDate,
              selectedDay: _selectedDay,
              onDayTapped: _onDayTapped,
            ),
          ),

          // Fitness plan section - updates based on selected day
          phaseDefsAsync.when(
            data: (phaseDefs) {
              return ref.watch(cycle_providers.currentCycleProvider).when(
                data: (cycle) {
                  if (cycle == null) {
                    return PlannerCard(
                      title: 'Workout Suggestion',
                      subtitle: 'Add your cycle to see recommendations',
                      headerIcon: Icons.fitness_center,
                      accentColor: AppColors.blush,
                      body: Text('No cycle data available',
                          style: AppTypography.body2),
                    );
                  }

                  // Use selected day or today
                  final displayDate = _selectedDay ?? DateTime.now();
                  final normalizedDate = DateTime(displayDate.year, displayDate.month, displayDate.day);
                  final normalizedStart = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
                  final daysSinceStart = normalizedDate.difference(normalizedStart).inDays;
                  final cycleDay = (daysSinceStart % (cycle.length ?? 28)) + 1;

                  // Get phase from database definitions
                  String displayPhase = 'Follicular';
                  for (final entry in phaseDefs.entries) {
                    final def = entry.value as Map<String, dynamic>;
                    if (cycleDay >= def['start'] && cycleDay <= def['end']) {
                      displayPhase = entry.key;
                      break;
                    }
                  }

                  // Pass selected cycle day to provider (single query for all types)
                  final recommendationsAsync = ref.watch(
                    phase_providers.userPhaseRecommendationsByDayProvider(cycleDay),
                  );

                  return recommendationsAsync.when(
                    data: (allRecommendations) {
                      // Filter for Fitness category
                      final recommendations = allRecommendations['Fitness'] ?? [];
                      final rec = recommendations.isNotEmpty
                          ? recommendations[0]
                          : null;

                      // Watch daily template from database
                      // Use normalized date (midnight) to avoid constant rebuilds
                      final templateDate = _selectedDay ?? DateTime.now();
                      final normalizedDate = DateTime(templateDate.year, templateDate.month, templateDate.day);
                      final templateAsync = ref.watch(
                        dailyTemplateProvider(('Fitness', normalizedDate)),
                      );

                      return templateAsync.when(
                        data: (template) {
                          // Debug: Log recommendation structure
                          if (rec != null) {
                            print('🏋️ [fitness_screen] Recommendation keys: ${rec.keys.toList()}');
                            print('🏋️ [fitness_screen] Recommendation: $rec');
                          }
                          
                          final templateText = template != null && rec != null
                              ? template.fillTemplate(rec['workout_mode'] ?? rec['title'] ?? rec['recommendation_value'] ?? 'movement')
                              : 'No workout recommendation';

                          return PlannerCard(
                            title: 'Day $cycleDay · $displayPhase phase',
                            headerIcon: Icons.fitness_center,
                            accentColor: AppColors.blush,
                            body: Text(
                              templateText,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                        loading: () => PlannerCard(
                          title: 'Day $cycleDay · $displayPhase phase',
                          headerIcon: Icons.fitness_center,
                          accentColor: AppColors.blush,
                          body: const SizedBox(
                            height: 50,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        error: (err, stack) => PlannerCard(
                          title: 'Workout Suggestion',
                          headerIcon: Icons.fitness_center,
                          accentColor: AppColors.blush,
                          body: Text('Error loading template: $err',
                              style: AppTypography.body2),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => PlannerCard(
                      title: 'Workout Suggestion',
                      headerIcon: Icons.fitness_center,
                      accentColor: AppColors.blush,
                      body: Text('Error loading recommendations: $err',
                          style: AppTypography.body2),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error loading phases: $err'),
          ),

          // Workouts Plan Section
          SizedBox(height: AppSpacing.xl),
          Text('Workouts Plan', style: AppTypography.header2),
          SizedBox(height: AppSpacing.md),
          ref.watch(fitnessLogsForDateProvider(_selectedDay)).when(
            data: (logs) {
              debugPrint('🏋️ [fitness_screen] Rendering workouts: ${logs.length} items for date: $_selectedDay');
              if (logs.isEmpty) {
                final dateText = _selectedDay != null 
                    ? 'No workouts logged for ${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}. Tap + to add one!'
                    : 'No workouts logged today. Tap + to add one!';
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      dateText,
                      style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return Column(
                children: logs.map((log) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    color: log.completed ? Colors.green[50] : null,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.activityType,
                                        style: AppTypography.subtitle2.copyWith(
                                          decoration: log.completed
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: log.completed
                                              ? AppColors.textSecondary
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (log.completed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Completed',
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '${log.durationMinutes ?? 0} min',
                                      style: AppTypography.caption,
                                    ),
                                    SizedBox(width: AppSpacing.md),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: log.intensity == 'High'
                                            ? Colors.red[100]
                                            : log.intensity == 'Moderate'
                                                ? Colors.orange[100]
                                                : Colors.blue[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log.intensity,
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await ref.read(toggleFitnessLogCompletionProvider(log.id).future);
                                  // Invalidate both providers to refresh UI
                                  ref.invalidate(todaysFitnessLogsProvider);
                                  ref.invalidate(fitnessLogsForDateProvider);
                                },
                                icon: Icon(
                                  log.completed
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                  size: 24,
                                  color: log.completed ? Colors.green : Colors.grey,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref.read(deleteFitnessLogProvider(log.id).future);
                                  // Invalidate both providers to refresh UI
                                  ref.invalidate(todaysFitnessLogsProvider);
                                  ref.invalidate(fitnessLogsForDateProvider);
                                },
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () {
              debugPrint('⏳ [fitness_screen] Loading workouts...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (err, stack) {
              debugPrint('❌ [fitness_screen] Error loading workouts: $err');
              return Text('Error: $err');
            },
          ),
        ],
      ),
    );
  }

}
