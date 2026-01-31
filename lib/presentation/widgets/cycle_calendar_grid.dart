import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';

/// Phase color mapping
class PhaseColorMap {
  static const menstrual = Color(0xFFF4A4C0); // Blush
  static const follicular = Color(0xFFD4E9E2); // Sage
  static const ovulation = Color(0xFFFFD6BA); // Peach
  static const luteal = Color(0xFFE8D5C4); // Light taupe

  static Color getColor(String phaseName) {
    switch (phaseName) {
      case 'Menstrual':
        return menstrual;
      case 'Follicular':
        return follicular;
      case 'Ovulation':
        return ovulation;
      case 'Luteal':
        return luteal;
      default:
        return Colors.transparent;
    }
  }
}

/// Cycle Calendar Grid Component
/// Displays calendar grid with cycle phase information
class CycleCalendarGrid extends StatelessWidget {
  /// Selected month/year for the calendar
  final DateTime selectedDate;

  /// Callback when a day is tapped (optional)
  final Function(DateTime)? onDayTapped;

  /// Currently selected day (optional)
  final DateTime? selectedDay;

  /// Cycle start date (to calculate phases)
  final DateTime? cycleStartDate;

  /// Cycle length in days (default 28)
  final int cycleLength;

  /// Phase definitions: [(name, dayStart, dayEnd), ...]
  final List<(String, int, int)> phases;

  const CycleCalendarGrid({
    Key? key,
    required this.selectedDate,
    this.onDayTapped,
    this.selectedDay,
    this.cycleStartDate,
    this.cycleLength = 28,
    this.phases = const [
      ('Menstrual', 1, 5),
      ('Follicular', 6, 12),
      ('Ovulation', 13, 15),
      ('Luteal', 16, 28),
    ],
  }) : super(key: key);

  /// Get cycle day number for a given calendar date
  int _getCycleDayForDate(DateTime date) {
    if (cycleStartDate == null) return 0;
    
    // Normalize both dates to midnight to avoid timezone issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(cycleStartDate!.year, cycleStartDate!.month, cycleStartDate!.day);
    
    final daysSinceStart = normalizedDate.difference(normalizedStart).inDays;
    if (daysSinceStart < 0) return 0; // Before cycle start
    
    // Calculate day of cycle (1-based, wraps around)
    return (daysSinceStart % cycleLength) + 1;
  }

  /// Get phase name for a given cycle day
  String _getPhaseForCycleDay(int cycleDay) {
    if (cycleDay <= 0) return '';
    
    for (final phase in phases) {
      if (cycleDay >= phase.$2 && cycleDay <= phase.$3) {
        return phase.$1;
      }
    }
    return '';
  }

  /// Get cycle phase color for a given day
  Color _getPhaseColor(DateTime date) {
    final cycleDay = _getCycleDayForDate(date);
    final phaseName = _getPhaseForCycleDay(cycleDay);
    
    if (phaseName.isEmpty) {
      return Colors.transparent;
    }
    
    return PhaseColorMap.getColor(phaseName).withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1).weekday;
    final daysInMonth = selectedDate.month == 12
        ? DateTime(selectedDate.year + 1, 1, 0).day
        : DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // Build week day headers
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.map((day) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - AppSpacing.screenPadding * 2) / 7,
                child: Center(
                  child: Text(
                    day,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: AppSpacing.calendarGridGap,
            mainAxisSpacing: AppSpacing.calendarGridGap,
          ),
          itemCount: 42, // 6 weeks * 7 days
          itemBuilder: (context, index) {
            // Calculate day number
            final dayNumber = index - firstDay + 2; // +2 because weekday() returns 1-7

            // Check if day is in current month
            final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
            final day = isCurrentMonth ? dayNumber : 0;

            if (!isCurrentMonth) {
              return const SizedBox(); // Empty cell for days outside month
            }

            final dayDate = DateTime(selectedDate.year, selectedDate.month, day);
            final isSelected =
                selectedDay != null &&
                selectedDay!.year == dayDate.year &&
                selectedDay!.month == dayDate.month &&
                selectedDay!.day == dayDate.day;
            final isToday =
                dayDate.year == DateTime.now().year &&
                dayDate.month == DateTime.now().month &&
                dayDate.day == DateTime.now().day;

            // Get cycle info for this date
            final cycleDay = _getCycleDayForDate(dayDate);
            final phaseName = _getPhaseForCycleDay(cycleDay);
            final phaseColor = _getPhaseColor(dayDate);

            return GestureDetector(
              onTap: () => onDayTapped?.call(dayDate),
              child: Container(
                decoration: BoxDecoration(
                  color: phaseColor,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textPrimary
                        : isToday
                            ? Colors.red
                            : Colors.transparent,
                    width: isSelected ? 2 : isToday ? 2 : 0,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: AppTypography.body2.copyWith(
                        color: isToday ? Colors.red : AppColors.textPrimary,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (cycleDay > 0)
                      Text(
                        'D$cycleDay',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Phase legend
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cycle Phases',
                style: AppTypography.subtitle2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: phases.map((phase) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: PhaseColorMap.getColor(phase.$1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '${phase.$1} (D${phase.$2}-${phase.$3})',
                        style: AppTypography.caption,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
