import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/month_selector.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/cycle_calendar_grid.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/cycle_calendar_grid.dart' show PhaseColorMap;
import 'package:cycle_sync_mvp_2/presentation/widgets/cycle_info_card.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_provider.dart' as cycle_providers;
import 'package:cycle_sync_mvp_2/presentation/providers/phase_provider.dart' as phase_providers;
import 'package:logger/logger.dart';

/// My Cycle Screen
/// Track cycle phases, symptoms, and cycle history
class MyCycleScreen extends ConsumerStatefulWidget {
  const MyCycleScreen({super.key});

  @override
  ConsumerState<MyCycleScreen> createState() => _MyCycleScreenState();
}

class _MyCycleScreenState extends ConsumerState<MyCycleScreen> {
  late DateTime _selectedDate;
  DateTime? _selectedDay;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  /// Public method to show the cycle input dialog
  void showAddCycleDialog() {
    _showAddCycleDialog(context);
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

  /// Calculate cycle day for any given date
  int _calculateCycleDayForDate(DateTime date, DateTime cycleStartDate, int cycleLength) {
    // Normalize both dates to midnight to avoid timezone issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(cycleStartDate.year, cycleStartDate.month, cycleStartDate.day);
    
    final daysSinceStart = normalizedDate.difference(normalizedStart).inDays;
    if (daysSinceStart < 0) return 0;
    return (daysSinceStart % cycleLength) + 1;
  }

  /// Calculate days until next period from any given date
  int _calculateDaysUntilPeriod(DateTime date, DateTime cycleStartDate, int cycleLength, int menstrualLength) {
    final cycleDay = _calculateCycleDayForDate(date, cycleStartDate, cycleLength);
    final daysInCurrentCycle = cycleLength - cycleDay + 1;
    return (daysInCurrentCycle + menstrualLength - 1).clamp(0, cycleLength);
  }

  /// Check if a given date is in fertile window (ovulation phase)
  bool _isFertileWindow(int cycleDay) {
    return cycleDay >= 14 && cycleDay <= 16;
  }

  /// Show dialog to add new cycle
  void _showAddCycleDialog(BuildContext context) {
    DateTime selectedStartDate = DateTime.now();
    int cycleLength = AppConstants.typicalCycleLength; // 28 default
    int menstrualLength = 5; // 5 days default
    bool showMenstrualWarning = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Cycle Information'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Date of Last Period
                    Text(
                      'First Date of Last Period',
                      style: AppTypography.subtitle2,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                          helpText: 'Select the first day of your last period',
                        );
                        if (picked != null) {
                          setState(() {
                            selectedStartDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textTertiary),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedStartDate.month}/${selectedStartDate.day}/${selectedStartDate.year}',
                              style: AppTypography.body1,
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),

                    // Cycle Length
                    Text(
                      'Cycle Length (days)',
                      style: AppTypography.subtitle2,
                    ),
                    Text(
                      'Typical range: 21–35 days',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (cycleLength > 21) {
                              setState(() {
                                cycleLength--;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$cycleLength',
                          style: AppTypography.header2,
                        ),
                        IconButton(
                          onPressed: () {
                            if (cycleLength < 35) {
                              setState(() {
                                cycleLength++;
                              });
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),

                    // Menstrual Length
                    Text(
                      'Menstrual Length (days)',
                      style: AppTypography.subtitle2,
                    ),
                    Text(
                      'Typical range: 2–10 days',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (menstrualLength > 2) {
                              setState(() {
                                menstrualLength--;
                                showMenstrualWarning = menstrualLength > 10;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$menstrualLength',
                          style: AppTypography.header2,
                        ),
                        IconButton(
                          onPressed: () {
                            if (menstrualLength < 20) {
                              setState(() {
                                menstrualLength++;
                                showMenstrualWarning = menstrualLength > 10;
                              });
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),

                    // Menstrual Length Warning
                    if (showMenstrualWarning) ...[
                      SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Most cycles range between 2–10 days. If your period is consistently longer, please consult a healthcare provider.',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                try {
                  // Validate date is not in future
                  if (selectedStartDate.isAfter(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Period start date cannot be in the future'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  // Create the cycle
                  await ref.read(
                    cycle_providers.createCycleProvider((
                      selectedStartDate,
                      cycleLength,
                      menstrualLength,
                    )).future,
                  );

                  _logger.i('✅ Cycle created with all parameters');

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cycle information saved! 🎉'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  _logger.e('❌ Error creating cycle: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Cycle'),
            ),
          ],
        );
      },
    );
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

          // Cycle info cards
          phaseDefsAsync.when(
            data: (phaseDefs) {
              return ref.watch(cycle_providers.currentCycleProvider).when(
                data: (cycle) {
                  if (cycle == null) {
                    return Center(
                      child: Text(
                        'Add your cycle information to see phase details',
                        style: AppTypography.body2,
                      ),
                    );
                  }

                  // Use selected day or today
                  final displayDate = _selectedDay ?? DateTime.now();
                  final cycleDay = _calculateCycleDayForDate(displayDate, cycle.startDate, cycle.length ?? 28);
                  
                  // Get phase from database definitions
                  String displayPhase = 'Follicular';
                  for (final entry in phaseDefs.entries) {
                    final def = entry.value as Map<String, dynamic>;
                    if (cycleDay >= def['start'] && cycleDay <= def['end']) {
                      displayPhase = entry.key;
                      break;
                    }
                  }
                  
                  final daysUntil = _calculateDaysUntilPeriod(displayDate, cycle.startDate, cycle.length ?? 28, 5);
                  final isFertile = _isFertileWindow(cycleDay);

                  // Get phase color dynamically
                  final phaseColor = PhaseColorMap.getColor(displayPhase);

                  return Column(
                    children: [
                      // Current phase card with dynamic color
                      CycleInfoCard(
                        title: displayPhase,
                        subtitle: 'Day $cycleDay of cycle',
                        description: _selectedDay != null
                            ? 'Cycle phase for selected date'
                            : 'Current cycle phase',
                        accentColor: phaseColor,
                        icon: Icons.calendar_today,
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // Fertile window card (if applicable)
                      if (displayPhase != 'Luteal')
                        CycleInfoCard(
                          title: isFertile ? 'Fertile Window' : 'Not in Fertile Window',
                          subtitle: isFertile ? 'High fertility' : '',
                          description: isFertile
                              ? 'This is your most fertile time'
                              : 'Low fertility window',
                          accentColor: isFertile ? AppColors.success : AppColors.textTertiary,
                          icon: isFertile ? Icons.favorite : Icons.favorite_border,
                        ),
                      if (displayPhase != 'Luteal')
                        SizedBox(height: AppSpacing.xl),

                      // Days until period card
                      CycleInfoCard(
                        title: 'Until Next Period',
                        subtitle: '$daysUntil days',
                        description: 'Approximately $daysUntil days until menstruation',
                        accentColor: AppColors.menstrual,
                        icon: Icons.calendar_today,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error loading phases: $err'),
          ),
        ],
      ),
    );
  }

  /// Build recommendation card widget
  Widget _buildRecommendationCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    int? fastingMin,
    int? fastingMax,
    String? fastingStyle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.subtitle2.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: color.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.body2.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (fastingMin != null && fastingMax != null) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fasting Window',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$fastingMin - $fastingMax hours',
                        style: AppTypography.subtitle2.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fastingStyle != null)
                  Chip(
                    label: Text(
                      fastingStyle,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Get icon for phase
  IconData _getPhaseIcon(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return Icons.favorite;
      case 'follicular':
        return Icons.energy_savings_leaf;
      case 'ovulation':
        return Icons.star;
      case 'luteal':
        return Icons.sentiment_satisfied;
      default:
        return Icons.help;
    }
  }

  /// Get description for phase
  String _getPhaseDescription(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return 'Your period has started. Rest and hydration are important. You may experience mild cramping and mood changes.';
      case 'follicular':
        return 'Estrogen levels are rising. You\'ll likely feel more energized and social. This is a great time for intense workouts.';
      case 'ovulation':
        return 'Your most fertile time! You may feel confident and attractive. Testosterone levels peak, giving you extra strength.';
      case 'luteal':
        return 'Progesterone is high. You may feel more introspective. Focus on rest, nutrition, and gentle activities. PMS may start.';
      default:
        return 'Track your cycle to see insights about this phase.';
    }
  }
}
