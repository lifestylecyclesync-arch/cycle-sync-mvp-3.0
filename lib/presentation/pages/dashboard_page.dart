import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final lifestyleAreas = ref.watch(lifestyleAreasProvider);
    // Watch cached data for instant display
    final cachedLifestyleAreas = ref.watch(cachedLifestyleAreasProvider);

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: isGuest ? _buildGuestMode(context, ref) : _buildAuthenticatedMode(context, userProfile, lifestyleAreas, cachedLifestyleAreas),
    );
  }

  Widget _buildAuthenticatedMode(BuildContext context, AsyncValue userProfile, AsyncValue lifestyleAreas, List<String> cachedLifestyleAreas) {
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
        
        return lifestyleAreas.when(
          data: (areas) {
            final isEmpty = (areas ?? []).isEmpty;
            return Column(
              children: [
                // Note: _buildHeader uses ref, so it needs to be called from build context
                Consumer(
                  builder: (context, ref, _) => _buildHeader(context, ref),
                ),
                if (isEmpty)
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
                          Consumer(
                            builder: (context, ref, _) {
                              return ElevatedButton(
                                onPressed: () {
                                  // Immediate haptic feedback for instant response
                                  HapticFeedback.lightImpact();
                                  
                                  // Get current lifestyle areas from provider
                                  final currentAreas = ref.read(cachedLifestyleAreasProvider);
                                  _showAddLifestyleAreaModal(context, ref, currentAreas);
                                },
                                child: const Text('Update lifestyle areas'),
                              );
                            },
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
            // Show cached data while loading
            if (cachedLifestyleAreas.isNotEmpty) {
              return Column(
                children: [
                  Consumer(
                    builder: (context, ref, _) => _buildHeader(context, ref),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Refreshing...', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
          error: (err, stack) {
            // Show cached data on error
            if (cachedLifestyleAreas.isNotEmpty) {
              return Column(
                children: [
                  Consumer(
                    builder: (context, ref, _) => _buildHeader(context, ref),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Connection error', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                ],
              );
            }
            return Center(child: Text('Error: $err'));
          },
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
    // Use provider instead of FutureBuilder to avoid rebuilding on every access
    return ref.watch(sharedPreferencesProvider).when(
      data: (prefs) {
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
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

  void _showAddLifestyleAreaModal(BuildContext context, WidgetRef ref, List<String> initialAreas) {
    final List<String> availableAreas = [
      'Work',
      'Exercise',
      'Social',
      'Sleep',
      'Stress',
      'Mood',
      'Energy',
      'Health',
      'Family',
      'Productivity',
      'Travel',
      'Hobby',
    ];

    List<String> selectedAreas = List.from(initialAreas);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // isSaving is managed via setState
            return AlertDialog(
              title: const Text('Update Lifestyle Areas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableAreas.map((area) {
                    return CheckboxListTile(
                      title: Text(area),
                      value: selectedAreas.contains(area),
                      onChanged: (bool? checked) {
                        // Instant haptic feedback on tap
                        HapticFeedback.selectionClick();
                        
                        setState(() {
                          if (checked == true) {
                            if (!selectedAreas.contains(area)) {
                              selectedAreas.add(area);
                            }
                          } else {
                            selectedAreas.removeWhere((a) => a == area);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () {
                    // Instant haptic feedback
                    HapticFeedback.mediumImpact();
                    
                    setState(() {
                      isSaving = true;
                    });
                    
                    // Invalidate profile IMMEDIATELY for instant UI response
                    ref.invalidate(userProfileProvider);
                    
                    // Close dialog immediately - don't wait for saves
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    
                    // Background save to Supabase - non-blocking
                    ref.read(updateLifestyleAreasProvider(selectedAreas).future)
                      .then((_) => print('[Dashboard] Supabase saved'))
                      .catchError((e) => print('[Dashboard] Supabase error: $e'));
                    
                    // Show confirmation
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Lifestyle areas updated'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


