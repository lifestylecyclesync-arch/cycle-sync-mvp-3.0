import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/month_selector.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/cycle_calendar_grid.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/planner_card.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/phase_provider.dart' as phase_providers;
import 'package:cycle_sync_mvp_2/presentation/providers/diet_logs_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/templates_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_provider.dart' as cycle_providers;

/// Diet Screen
/// Log meals and track dietary intake
class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
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

  /// Get the currently selected day (for dialog to use when adding meals)
  DateTime? getSelectedDay() => _selectedDay;

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

          // Diet plan section - updates based on selected day
          phaseDefsAsync.when(
            data: (phaseDefs) {
              return ref.watch(cycle_providers.currentCycleProvider).when(
                data: (cycle) {
                  if (cycle == null) {
                    return PlannerCard(
                      title: 'Nutrition Suggestion',
                      subtitle: 'Add your cycle to see recommendations',
                      headerIcon: Icons.restaurant_menu,
                      accentColor: AppColors.sage,
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
                  final dietRec = ref.watch(
                    phase_providers.userPhaseRecommendationsByDayProvider(cycleDay),
                  );
                  return dietRec.when(
                    data: (allRecommendations) {
                      // Filter for Nutrition category
                      final recommendations = allRecommendations['Nutrition'] ?? [];
                      final rec = recommendations.isNotEmpty
                          ? recommendations[0]
                          : null;

                      // Watch daily template from database
                      // Use normalized date (midnight) to avoid constant rebuilds
                      final templateDate = _selectedDay ?? DateTime.now();
                      final normalizedDate = DateTime(templateDate.year, templateDate.month, templateDate.day);
                      final templateAsync = ref.watch(
                        dailyTemplateProvider(('Diet', normalizedDate)),
                      );

                      return templateAsync.when(
                        data: (template) {
                          final templateText = template != null && rec != null
                              ? template.fillTemplate(rec['food_vibe'] ?? rec['title'] ?? 'nourishment')
                              : 'No nutrition recommendation';

                          return PlannerCard(
                            title: 'Day $cycleDay · $displayPhase phase',
                            headerIcon: Icons.restaurant_menu,
                            accentColor: AppColors.sage,
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
                          headerIcon: Icons.restaurant_menu,
                          accentColor: AppColors.sage,
                          body: const SizedBox(
                            height: 50,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        error: (err, stack) => PlannerCard(
                          title: 'Nutrition Suggestion',
                          headerIcon: Icons.restaurant_menu,
                          accentColor: AppColors.sage,
                          body: Text('Error loading template: $err',
                              style: AppTypography.body2),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => PlannerCard(
                      title: 'Nutrition Suggestion',
                      headerIcon: Icons.restaurant_menu,
                      accentColor: AppColors.sage,
                      body: Text('Error loading recommendations: $err',
                          style: AppTypography.body2),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading phases: $err'),
          ),

          // Meals Plan Section
          SizedBox(height: AppSpacing.xl),
          Text('Meals Plan', style: AppTypography.header2),
          SizedBox(height: AppSpacing.md),
          ref.watch(dietLogsForDateProvider(_selectedDay)).when(
            data: (logs) {
              if (logs.isEmpty) {
                final dateStr = _selectedDay != null 
                    ? '${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}'
                    : 'today';
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      'No meals logged for $dateStr. Tap + to add one!',
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
                                  log.mealType,
                                  style: AppTypography.subtitle2,
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  log.foodItems.join(', '),
                                  style: AppTypography.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (log.calories != null) ...[
                                  SizedBox(height: AppSpacing.xs),
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
                                      '${log.calories} cal',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
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
                                onPressed: () async {
                                  await ref.read(deleteDietLogProvider(log.id).future);
                                  ref.invalidate(todaysDietLogsProvider);
                                  ref.invalidate(dietLogsForDateProvider);
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
