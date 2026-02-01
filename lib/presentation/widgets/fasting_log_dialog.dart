import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/fasting_logs_provider.dart';
import 'package:logger/logger.dart';

/// Fasting Log Dialog
void showFastingLogDialog(BuildContext context, WidgetRef ref, {DateTime? selectedDate}) {
  final Logger logger = Logger();
  DateTime startTime = DateTime.now().subtract(const Duration(hours: 16));
  DateTime endTime = DateTime.now();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Log Fasting Window'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final duration = endTime.difference(startTime);
            final durationHours = duration.inMinutes / 60.0;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start Time
                  Text('Start Time', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (time != null) {
                        setState(() {
                          startTime = DateTime(
                            startTime.year,
                            startTime.month,
                            startTime.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textTertiary),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.body1,
                          ),
                          Icon(Icons.access_time, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // End Time
                  Text('End Time', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime),
                      );
                      if (time != null) {
                        setState(() {
                          endTime = DateTime(
                            endTime.year,
                            endTime.month,
                            endTime.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textTertiary),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.body1,
                          ),
                          Icon(Icons.access_time, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Duration display
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.peach.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      border: Border.all(color: AppColors.peach.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Duration', style: AppTypography.subtitle2),
                        Text(
                          '${durationHours.toStringAsFixed(1)}h',
                          style: AppTypography.header2.copyWith(color: AppColors.peach),
                        ),
                      ],
                    ),
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
              if (endTime.isBefore(startTime)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('End time must be after start time')),
                );
                return;
              }

              try {
                await ref.read(
                  createFastingLogProvider((startTime, endTime, null, selectedDate)).future,
                );

                logger.i('✅ Fasting logged');
                
                // Invalidate providers to refresh UI with new fasting log
                ref.invalidate(todaysFastingLogsProvider);
                ref.invalidate(fastingLogsForDateProvider);
                
                // Give the invalidation time to propagate
                await Future.delayed(const Duration(milliseconds: 500));

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fasting logged! ⏱️'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                logger.e('❌ Error logging fasting: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Log Fasting'),
          ),
        ],
      );
    },
  );
}
