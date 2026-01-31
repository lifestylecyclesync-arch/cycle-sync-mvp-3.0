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
          SizedBox(height: AppSpacing.xl),

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

                      return PlannerCard(
                        title: 'Workout Suggestion',
                        subtitle: '$displayPhase Phase - Day $cycleDay',
                        headerIcon: Icons.fitness_center,
                        accentColor: AppColors.blush,
                        body: rec != null
                            ? Text(
                                'Workout Mode: ${rec['workout_mode'] ?? rec['title'] ?? 'Workout'}',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : Text(
                                'No workout recommendation',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
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
          ref.watch(todaysFitnessLogsProvider).when(
            data: (logs) {
              if (logs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      'No workouts logged today. Tap + to add one!',
                      style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return Column(
                children: logs.map((log) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.activityType,
                                  style: AppTypography.subtitle2,
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
                                            : log.intensity == 'Medium'
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
                                onPressed: () {
                                  // Mark as complete
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 24, color: Colors.green),
                              ),
                              IconButton(
                                onPressed: () {
                                  ref.read(deleteFitnessLogProvider(log.id));
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }

}
