import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_profile_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_phase_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: userProfile.when(
        data: (profile) => Column(
          children: [
            _buildHeader(context, ref),
            if (profile.lifestyleAreas.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacingLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add Nutrition, Fitness, or Fasting to get personalized tips.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: AppConstants.spacingXl),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to add lifestyle areas
                          },
                          child: const Text('Add lifestyle areas'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return ref.watch(currentPhaseProvider).when(
      data: (phaseInfo) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppConstants.spacingLg),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phase info
              Text(
                'Day ${phaseInfo.dayOfCycle} • ${phaseInfo.lifestylePhase}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Text(
                '${phaseInfo.displayName} Phase (Days ${phaseInfo.startDay}–${phaseInfo.endDay})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppConstants.spacingLg),
        color: Colors.white,
        child: const CircularProgressIndicator(),
      ),
      error: (err, stack) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppConstants.spacingLg),
        color: Colors.white,
        child: Text('Error: $err'),
      ),
    );
  }
}


