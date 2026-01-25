import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';

class DailyCardPage extends ConsumerWidget {
  const DailyCardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final lifestyleAreasAsync = ref.watch(lifestyleAreasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Insights'),
        elevation: 0,
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Please complete your profile first',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return lifestyleAreasAsync.when(
            data: (lifestyleAreas) {
              AppLogger.info('DailyCardPage: lifestyleAreas = $lifestyleAreas');
              
              if (lifestyleAreas.isEmpty) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.spacingLg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No lifestyle areas selected',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: AppConstants.spacingMd),
                              Text(
                                'Add Nutrition, Fitness, or Fasting to your profile to get personalized daily insights.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Selected Areas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingMd),
                    Wrap(
                      spacing: AppConstants.spacingSm,
                      runSpacing: AppConstants.spacingSm,
                      children: lifestyleAreas.map((area) {
                        return Chip(
                          label: Text(area),
                          backgroundColor: Colors.deepPurple.shade100,
                          labelStyle: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: AppConstants.spacingLg),
                    ..._buildInsightsForAreas(context, lifestyleAreas),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, st) {
              AppLogger.error('DailyCardPage: Error loading lifestyle areas', error, st);
              return Center(
                child: Text('Error: ${error.toString()}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) {
          AppLogger.error('DailyCardPage: Error loading profile', error, st);
          return Center(
            child: Text('Error: ${error.toString()}'),
          );
        },
      ),
    );
  }

  List<Widget> _buildInsightsForAreas(BuildContext context, List<String> lifestyleAreas) {
    final insights = <Widget>[];

    for (final area in lifestyleAreas) {
      insights.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppConstants.spacingMd),
                Text(
                  _getInsightForArea(area),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
      insights.add(SizedBox(height: AppConstants.spacingMd));
    }

    return insights;
  }

  String _getInsightForArea(String area) {
    switch (area.toLowerCase()) {
      case 'nutrition':
        return 'Focus on balanced meals with adequate protein and iron intake. Stay hydrated throughout the day.';
      case 'fitness':
        return 'Adjust your workout intensity based on your cycle phase. Lighter workouts during menstruation, more intense during ovulation.';
      case 'fasting':
        return 'Consider cycle-syncing your fasting routine. Shorter fasting windows during menstruation, longer during follicular phase.';
      default:
        return 'Stay consistent with your $area routine to support your cycle health.';
    }
  }
}
