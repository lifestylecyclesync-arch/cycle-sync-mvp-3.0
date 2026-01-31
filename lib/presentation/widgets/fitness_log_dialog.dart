import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/fitness_logs_provider.dart';
import 'package:logger/logger.dart';

/// Fitness Log Dialog
void showFitnessLogDialog(BuildContext context, WidgetRef ref) {
  final Logger logger = Logger();
  String selectedActivity = 'Yoga';
  int duration = 30;
  String selectedIntensity = 'Medium';
  String? notes;

  final activities = ['Yoga', 'Running', 'Strength', 'HIIT', 'Pilates', 'Walking', 'Cycling', 'Swimming'];
  final intensities = ['Low', 'Medium', 'High'];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Log Fitness Activity'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Type
                  Text('Activity Type', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  DropdownButton<String>(
                    value: selectedActivity,
                    isExpanded: true,
                    items: activities.map((activity) {
                      return DropdownMenuItem(
                        value: activity,
                        child: Text(activity),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedActivity = value ?? 'Yoga');
                    },
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Duration
                  Text('Duration (minutes)', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (duration > 5) {
                            setState(() => duration -= 5);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$duration min', style: AppTypography.header2),
                      IconButton(
                        onPressed: () {
                          if (duration < 180) {
                            setState(() => duration += 5);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Intensity
                  Text('Intensity', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: intensities.map((intensity) {
                      final isSelected = selectedIntensity == intensity;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? AppColors.peach : Colors.grey[300],
                            ),
                            onPressed: () => setState(() => selectedIntensity = intensity),
                            child: Text(
                              intensity,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Notes
                  Text('Notes (optional)', style: AppTypography.subtitle2),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'How did it feel?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (value) => notes = value,
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
                await ref.read(
                  createFitnessLogProvider(
                    (selectedActivity, duration, selectedIntensity, notes),
                  ).future,
                );

                logger.i('✅ Fitness logged: $selectedActivity');

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout logged! 💪'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                logger.e('❌ Error logging fitness: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Log Activity'),
          ),
        ],
      );
    },
  );
}
