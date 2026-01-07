import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_phase_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/guest_mode_provider.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(guestModeProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: isGuest ? _buildGuestMode(context, ref) : _buildAuthenticatedMode(context, userProfile),
    );
  }

  Widget _buildAuthenticatedMode(BuildContext context, AsyncValue userProfile) {
    AppLogger.info('DashboardPage._buildAuthenticatedMode called with userProfile state');
    return userProfile.when(
      data: (profile) {
        AppLogger.info('DashboardPage userProfile data: $profile');
        if (profile == null) {
          AppLogger.info('DashboardPage: profile is null');
          return Center(
            child: Text('No profile data', style: Theme.of(context).textTheme.bodyLarge),
          );
        }
        AppLogger.info('DashboardPage: profile loaded successfully: ${(profile as UserProfile).name}');
        return Column(
          children: [
            // Note: _buildHeader uses ref, so it needs to be called from build context
            Consumer(
              builder: (context, ref, _) => _buildHeader(context, ref),
            ),
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
        );
      },
      loading: () {
        AppLogger.info('DashboardPage userProfile is loading');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, st) {
        AppLogger.error('DashboardPage userProfile error: $error', error, st);
        return Center(
          child: Text('Error: ${error.toString()}'),
        );
      },
    );
  }

  Widget _buildGuestMode(BuildContext context, WidgetRef ref) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prefs = snapshot.data!;
        final userName = prefs.getString('userName') ?? 'Guest User';
        final cycleLength = prefs.getInt('cycleLength') ?? 28;
        final lastPeriodDateStr = prefs.getString('lastPeriodDate');
        
        if (lastPeriodDateStr == null) {
          return Center(
            child: Text('Cycle data not found', style: Theme.of(context).textTheme.bodyLarge),
          );
        }

        final lastPeriodDate = DateTime.parse(lastPeriodDateStr);
        final now = DateTime.now();
        // Normalize to midnight to avoid time zone issues
        final normalizedNow = DateTime(now.year, now.month, now.day);
        final normalizedLastPeriod = DateTime(lastPeriodDate.year, lastPeriodDate.month, lastPeriodDate.day);
        final dayOfCycle = normalizedNow.difference(normalizedLastPeriod).inDays % cycleLength + 1;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppConstants.spacingLg),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $userName!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingSm),
                  Text(
                    'Day $dayOfCycle of your cycle (Guest Mode)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingMd),
                  Container(
                    padding: EdgeInsets.all(AppConstants.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: Text(
                            'Sign up to save your data and get personalized recommendations.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacingLg),
                  child: Text(
                    'In guest mode, your data is stored locally and will be cleared when you close the app.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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


