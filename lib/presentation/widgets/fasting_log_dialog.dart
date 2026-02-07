import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/fasting_logs_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_provider.dart';
import 'package:logger/logger.dart';

/// Fasting Log Dialog - with phase-based default duration and beginner/advanced toggle
void showFastingLogDialog(BuildContext context, WidgetRef ref, {DateTime? selectedDate}) {
  final Logger logger = Logger();
  
  // Default duration will be set based on cycle phase
  double durationHours = 16.0;
  bool isAdvancedMode = false;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      // Get current phase to set default duration
      final currentPhase = ref.watch(currentPhaseProvider);
      
      // Set default duration based on phase
      currentPhase.whenData((phase) {
        // These defaults match the reference table from the database
        durationHours = _getDefaultFastingDuration(phase);
      });

      return AlertDialog(
        title: const Text('Log Fasting Window'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAdvancedMode ? 'Advanced Mode' : 'Beginner Mode',
                        style: AppTypography.subtitle2,
                      ),
                      Switch(
                        value: isAdvancedMode,
                        onChanged: (value) {
                          setState(() => isAdvancedMode = value);
                        },
                        activeThumbColor: AppColors.peach,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Phase Info (Beginner Mode only)
                  if (!isAdvancedMode)
                    currentPhase.when(
                      data: (phase) {
                        final defaultValue = _getDefaultFastingDuration(phase);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suggested for $phase phase',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              '${defaultValue.toStringAsFixed(1)}h',
                              style: AppTypography.header2.copyWith(
                                color: AppColors.peach,
                              ),
                            ),
                            SizedBox(height: AppSpacing.lg),
                          ],
                        );
                      },
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculating phase...',
                            style: AppTypography.caption,
                          ),
                          SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                      error: (_, __) => SizedBox(height: AppSpacing.lg),
                    ),

                  // Instructions
                  Text(
                    isAdvancedMode
                        ? 'Set your custom fasting duration'
                        : 'Adjust the slider to customize your fasting window',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),


                  // Duration Display
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
                  SizedBox(height: AppSpacing.md),

                  // Slider for adjusting duration (8-24 hour range)
                  Slider(
                    value: durationHours,
                    min: 8.0,
                    max: 24.0,
                    divisions: 32,
                    label: '${durationHours.toStringAsFixed(1)}h',
                    onChanged: (value) {
                      setState(() => durationHours = value);
                    },
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('8h', style: AppTypography.caption),
                        Text('24h', style: AppTypography.caption),
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
              try {
                // Calculate start and end times based on duration
                final endTime = DateTime.now();
                final startTime = endTime.subtract(Duration(hours: durationHours.toInt(), minutes: ((durationHours % 1) * 60).toInt()));

                await ref.read(
                  createFastingLogProvider((startTime, endTime, null, selectedDate)).future,
                );

                logger.i('✅ Fasting logged: ${durationHours.toStringAsFixed(1)}h');
                
                // Invalidate providers to refresh UI with new fasting log
                ref.invalidate(todaysFastingLogsProvider);
                ref.invalidate(fastingLogsForDateProvider);
                
                // Give the invalidation time to propagate
                await Future.delayed(const Duration(milliseconds: 500));

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${durationHours.toStringAsFixed(1)}h fast logged! ⏱️'),
                      duration: const Duration(seconds: 2),
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

/// Get default fasting duration based on cycle phase
/// Based on phase recommendations from the database reference table
double _getDefaultFastingDuration(String? phase) {
  switch (phase) {
    case 'Menstrual': // Days 1-5: Short to Medium Fast
      return 13.0;
    case 'Follicular': // Days 6-12: Long to Extended Fast
      return 17.0;
    case 'Ovulation': // Days 13-15: Short to Long Fast
      return 13.0;
    case 'Luteal': // Days 16-28: Medium to Long Fast
      return 15.0;
    default:
      return 16.0; // Default fallback
  }
}
