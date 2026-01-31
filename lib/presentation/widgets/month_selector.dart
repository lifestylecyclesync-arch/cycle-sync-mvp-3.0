import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';

/// Month Selector Component
/// Allows user to navigate between months with previous/next buttons
class MonthSelector extends StatelessWidget {
  /// Selected month/year
  final DateTime selectedDate;

  /// Callback when previous month is tapped
  final VoidCallback onPreviousMonth;

  /// Callback when next month is tapped
  final VoidCallback onNextMonth;

  const MonthSelector({
    Key? key,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  }) : super(key: key);

  /// Format date as "January 2026"
  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.textSecondary,
            iconSize: 24,
          ),

          // Month/Year display
          Text(
            _formatMonthYear(selectedDate),
            style: AppTypography.header3,
          ),

          // Next month button
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.textSecondary,
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}
