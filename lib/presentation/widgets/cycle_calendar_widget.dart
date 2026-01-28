import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_phase_provider.dart';

/// Reusable calendar widget for all lifestyle screens
/// Handles calendar grid rendering with phase colors and optional indicators
class CycleCalendarWidget extends ConsumerWidget {
  final List<DateTime> days;
  final DateTime selectedDate;
  final DateTime currentMonth;
  final Function(DateTime) onDateSelected;
  
  /// If true, shows green completion circle for completed items (Fitness/Diet)
  final bool showCompletionIndicator;
  
  /// Type of completion to check ('completed_workouts', 'completed_recipes', etc.)
  /// Only used if showCompletionIndicator is true
  final String completionIndicatorKey;
  
  /// If true, renders as circular dots (Hormonal style)
  /// If false, renders as text with optional border (Fitness/Diet/Fasting style)
  final CalendarStyle calendarStyle;

  const CycleCalendarWidget({
    required this.days,
    required this.selectedDate,
    required this.currentMonth,
    required this.onDateSelected,
    this.showCompletionIndicator = false,
    this.completionIndicatorKey = 'completed_workouts',
    this.calendarStyle = CalendarStyle.dots,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.5,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isCurrentMonth = day.month == currentMonth.month;
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;

          return GestureDetector(
            onTap: isCurrentMonth
                ? () => onDateSelected(day)
                : null,
            child: isCurrentMonth
                ? _buildCurrentMonthDay(context, ref, day, isSelected)
                : _buildOtherMonthDay(day),
          );
        },
      ),
    );
  }

  /// Builds a day from the current month
  Widget _buildCurrentMonthDay(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    bool isSelected,
  ) {
    return ref.watch(cyclePhaseProvider(day)).when(
      data: (phaseInfo) {
        final colorCode = phaseInfo.colorCode;
        final hexColor = colorCode.replaceFirst('#', '');
        final phaseColor = Color(int.parse('ff$hexColor', radix: 16));

        if (calendarStyle == CalendarStyle.dots) {
          return _buildDotStyle(context, day, phaseColor, isSelected);
        } else {
          return _buildTextStyle(context, ref, day, phaseColor, isSelected);
        }
      },
      loading: () => _buildLoadingDay(day),
      error: (_, __) => _buildErrorDay(day),
    );
  }

  /// Builds a day from another month (grayed out)
  Widget _buildOtherMonthDay(DateTime day) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Dot style (Hormonal screen) - circular background with phase color
  Widget _buildDotStyle(
    BuildContext context,
    DateTime day,
    Color phaseColor,
    bool isSelected,
  ) {
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday
            ? phaseColor.withOpacity(0.6)
            : phaseColor.withOpacity(0.25),
        border: isToday ? Border.all(color: phaseColor, width: 2) : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isToday ? Colors.white : phaseColor.withOpacity(0.9),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Text style (Fitness/Diet/Fasting) - text with optional border and indicator
  Widget _buildTextStyle(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    Color phaseColor,
    bool isSelected,
  ) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue.shade400 : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: phaseColor.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showCompletionIndicator)
            _buildCompletionIndicator(context, ref, day),
        ],
      ),
    );
  }

  /// Shows a completion indicator (green filled circle with checkmark) if items are completed
  Widget _buildCompletionIndicator(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) {
    return ref.watch(dailySelectionsProvider(day)).when(
      data: (selections) {
        final completedJson = selections?[completionIndicatorKey] as String?;
        if (completedJson != null && completedJson.isNotEmpty) {
          try {
            final completed = jsonDecode(completedJson) as List;
            if (completed.isNotEmpty) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade400,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade400.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              );
            }
          } catch (e) {
            print('[Error] Failed to parse completion indicator: $e');
          }
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Loading state for a day
  Widget _buildLoadingDay(DateTime day) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Error state for a day
  Widget _buildErrorDay(DateTime day) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Calendar styling options
enum CalendarStyle {
  /// Circular dots with phase colors (Hormonal screen style)
  dots,
  
  /// Text-based with optional border (Fitness/Diet/Fasting style)
  text,
}
