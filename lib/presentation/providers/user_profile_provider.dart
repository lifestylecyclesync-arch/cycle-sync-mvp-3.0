import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';

// NOTE: User profile loading disabled for MVP - no Supabase

/// Holds the current user ID (typically from auth)
final currentUserIdProvider = StateProvider<String?>((ref) {
  // TODO: Get from auth service after Supabase is implemented
  return null;
});

/// Mock user profile for MVP testing - loads saved data from SharedPreferences
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  
  // Load saved data from onboarding
  final lastPeriodDateStr = prefs.getString('lastPeriodDate');
  final cycleLength = prefs.getInt('cycleLength') ?? 28;
  final menstrualLength = prefs.getInt('menstrualLength') ?? 5;
  final lutealPhaseLength = prefs.getInt('lutealPhaseLength') ?? 14;
  final lifestyleAreas = prefs.getStringList('lifestyleAreas') ?? [];
  final fastingPreference = prefs.getString('fastingPreference') ?? 'Beginner';
  final userName = prefs.getString('userName') ?? 'User';
  
  // Must have a saved period date from onboarding
  if (lastPeriodDateStr == null) {
    throw Exception('No period date set. Please complete onboarding.');
  }

  return UserProfile(
    id: 'test-user',
    name: userName,
    menstrualLength: menstrualLength,
    cycleLength: cycleLength,
    lutealPhaseLength: lutealPhaseLength,
    lastPeriodDate: DateTime.parse(lastPeriodDateStr),
    lifestyleAreas: lifestyleAreas,
    fastingPreference: fastingPreference,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
});
