import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/constants/workout_reference.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/fitness_logs_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_provider.dart';
import 'package:logger/logger.dart';

/// Fitness Log Dialog - Uses approved workouts from reference table
void showFitnessLogDialog(BuildContext context, WidgetRef ref, {DateTime? selectedDate}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _FitnessLogDialogContent(selectedDate: selectedDate);
    },
  );
}

/// Dialog content - fetches approved workouts by phase
class _FitnessLogDialogContent extends ConsumerStatefulWidget {
  final DateTime? selectedDate;
  
  const _FitnessLogDialogContent({this.selectedDate});

  @override
  ConsumerState<_FitnessLogDialogContent> createState() => _FitnessLogDialogContentState();
}

class _FitnessLogDialogContentState extends ConsumerState<_FitnessLogDialogContent> {
  String? selectedWorkoutId; // Start as null - nothing selected
  Workout? selectedWorkout; // Start as null - nothing selected
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    // No pre-selection - let user choose
  }

  @override
  Widget build(BuildContext context) {
    final phaseAsync = ref.watch(currentPhaseProvider);

    return phaseAsync.when(
      data: (phase) {
        // phase is a String (e.g., 'Follicular', 'Ovulation', etc.)
        final workouts = WorkoutReference.getWorkoutsForPhase(phase);

        if (workouts.isEmpty) {
          return AlertDialog(
            title: const Text('No Workouts Available'),
            content: const Text('No approved workouts for your current phase'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }

        logger.i('🏋️ Rendering dialog for phase: $phase');
        logger.i('📋 Found ${workouts.length} workouts');

        return AlertDialog(
          title: const Text('Plan & Track Workout'),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500,
              minWidth: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase info
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Optimal for $phase Phase',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Choose from approved workouts',
                                style: AppTypography.body2.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Workout selection title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('Select Workout', style: AppTypography.subtitle2),
                ),
                SizedBox(height: AppSpacing.md),

                // Workout list
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      final isSelected = selectedWorkout != null && selectedWorkout!.id == workout.id;
                      return Card(
                        color: isSelected ? Colors.blue[50] : null,
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          selected: isSelected,
                          title: Text(
                            workout.name,
                            style: AppTypography.body2.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${workout.durationMinutes} min • ${workout.intensity}',
                            style: AppTypography.caption,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : null,
                          onTap: () {
                            logger.i('✅ Selected workout: ${workout.name}');
                            setState(() {
                              selectedWorkout = workout;
                              selectedWorkoutId = workout.id;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedWorkout == null ? null : () async {
                try {
                  logger.i('➕ Starting to add workout...');
                  
                  // Create the fitness log with selected date
                  final params = (
                    selectedWorkout!.name,
                    selectedWorkout!.durationMinutes,
                    selectedWorkout!.intensity,
                    'Planned: ${selectedWorkout!.benefits}',
                    widget.selectedDate,
                  );
                  
                  logger.i('⏳ Calling createFitnessLogProvider with params: ${selectedWorkout!.name}');
                  
                  // Create the workout
                  await ref.read(createFitnessLogProvider(params).future);
                  
                  logger.i('✅ createFitnessLogProvider completed, invalidating providers...');
                  
                  // Invalidate providers to refresh UI with new workout
                  ref.invalidate(todaysFitnessLogsProvider);
                  ref.invalidate(fitnessLogsForDateProvider);
                  
                  logger.i('✅ Providers invalidated, waiting for rebuild...');
                  
                  // Give the invalidation time to propagate and the UI to rebuild
                  await Future.delayed(const Duration(milliseconds: 500));
                  
                  logger.i('✅ Delay complete, showing snackbar and closing dialog');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${selectedWorkout!.name} planned for today!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  logger.e('❌ Error adding workout: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blush,
              ),
              child: const Text('Plan Workout'),
            ),
          ],
        );
      },
      loading: () => AlertDialog(
        title: const Text('Loading...'),
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text('Error loading phase: $err'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
