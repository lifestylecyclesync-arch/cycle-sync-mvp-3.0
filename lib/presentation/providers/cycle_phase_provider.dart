import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_profile_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/guest_mode_provider.dart';

enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal,
}

/// Represents a lifestyle suggestion from the Adaptive Table
class LifestyleSuggestion {
  final String foodVibe;
  final String workoutMode;
  final String fastStyleBeginner;
  final String fastStyleAdvanced;
  final String lifestylePhase;
  final String hormonalPhase;

  LifestyleSuggestion({
    required this.foodVibe,
    required this.workoutMode,
    required this.fastStyleBeginner,
    required this.fastStyleAdvanced,
    required this.lifestylePhase,
    required this.hormonalPhase,
  });
}

class PhaseInfo {
  final CyclePhase phase;
  final int dayOfCycle;
  final int ovulationDay;
  final int startDay;
  final int endDay;
  final String displayName;
  final String hormonePhase;
  final String lifestylePhase;
  final String colorCode;
  final LifestyleSuggestion suggestion;

  PhaseInfo({
    required this.phase,
    required this.dayOfCycle,
    required this.ovulationDay,
    required this.startDay,
    required this.endDay,
    required this.displayName,
    required this.hormonePhase,
    required this.lifestylePhase,
    required this.colorCode,
    required this.suggestion,
  });
}

/// Adaptive Cycle Syncing Table
/// Maps cycle days to lifestyle and hormonal phases with recommendations
class AdaptiveTable {
  static LifestyleSuggestion getSuggestion(
    int cycleDay,
    int cycleLength,
    int menstrualLength,
  ) {
    // Calculate ovulation day: cycleLength - 14 (default luteal phase)
    final ovulationDay = cycleLength - 14;

    // Menstrual Phase: Days 1 to menstrualLength
    if (cycleDay >= 1 && cycleDay <= menstrualLength) {
      return LifestyleSuggestion(
        foodVibe: 'Gut-Friendly Low-Carb',
        workoutMode: 'Low-Impact Workout',
        fastStyleBeginner: 'Short Fast (13h)',
        fastStyleAdvanced: 'Medium Fast (15h)',
        lifestylePhase: 'Glow Reset',
        hormonalPhase: 'Low E, Low P',
      );
    }

    // Follicular Early: Days menstrualLength+1 to menstrualLength+5
    if (cycleDay > menstrualLength && cycleDay <= menstrualLength + 5) {
      return LifestyleSuggestion(
        foodVibe: 'Gut-Friendly Low-Carb',
        workoutMode: 'Moderate to High-Intensity Workout',
        fastStyleBeginner: 'Long Fast (17h)',
        fastStyleAdvanced: 'Extended Fast (24h)',
        lifestylePhase: 'Power Up',
        hormonalPhase: 'Rising E',
      );
    }

    // Follicular Late: Days menstrualLength+6 to ovulationDay-2
    if (cycleDay > menstrualLength + 5 && cycleDay < ovulationDay - 1) {
      return LifestyleSuggestion(
        foodVibe: 'Carb-Boost Hormone Fuel',
        workoutMode: 'Strength & Resistance',
        fastStyleBeginner: 'Short Fast (13h)',
        fastStyleAdvanced: 'Medium Fast (15h)',
        lifestylePhase: 'Main Character',
        hormonalPhase: 'Peak E',
      );
    }

    // Ovulation: Days ovulationDay-1 to ovulationDay+1
    if (cycleDay >= ovulationDay - 1 && cycleDay <= ovulationDay + 1) {
      return LifestyleSuggestion(
        foodVibe: 'Carb-Boost Hormone Fuel',
        workoutMode: 'Strength & Resistance',
        fastStyleBeginner: 'Short Fast (13h)',
        fastStyleAdvanced: 'Long Fast (17h)',
        lifestylePhase: 'Main Character',
        hormonalPhase: 'Peak E',
      );
    }

    // Early Luteal: Days ovulationDay+2 to ovulationDay+5
    if (cycleDay > ovulationDay + 1 && cycleDay <= ovulationDay + 5) {
      return LifestyleSuggestion(
        foodVibe: 'Gut-Friendly Low-Carb',
        workoutMode: 'Moderate to High-Intensity Workout',
        fastStyleBeginner: 'Medium Fast (15h)',
        fastStyleAdvanced: 'Long Fast (17h)',
        lifestylePhase: 'Power Up',
        hormonalPhase: 'Declining E, Rising P',
      );
    }

    // Late Luteal: Days ovulationDay+6 to cycleLength
    return LifestyleSuggestion(
      foodVibe: 'Carb-Boost Hormone Fuel',
      workoutMode: 'Moderate to Low-Impact Strength',
      fastStyleBeginner: 'Short Fast (13h)',
      fastStyleAdvanced: 'Short Fast (13h)',
      lifestylePhase: 'Cozy Care',
      hormonalPhase: 'Low E, High P',
    );
  }
}

/// Provider to get the cycle phase information for a given date
final cyclePhaseProvider = FutureProvider.family<PhaseInfo, DateTime>((ref, date) async {
  final isGuest = ref.watch(guestModeProvider);

  late DateTime cycleStartDate;
  late int cycleLength;
  late int menstrualLength;

  if (isGuest) {
    // Load from SharedPreferences in guest mode
    final prefs = await SharedPreferences.getInstance();
    final lastPeriodStr = prefs.getString('lastPeriodDate');
    final cycleLen = prefs.getInt('cycleLength');
    final menstrualLen = prefs.getInt('menstrualLength');

    if (lastPeriodStr == null || cycleLen == null || menstrualLen == null) {
      throw Exception('Guest mode: Cycle data not found. Please complete onboarding.');
    }

    cycleStartDate = DateTime.parse(lastPeriodStr);
    cycleLength = cycleLen;
    menstrualLength = menstrualLen;
  } else {
    // Load from Supabase user profile in authenticated mode
    final userProfile = await ref.watch(userProfileProvider.future);

    if (userProfile == null) {
      throw Exception('User profile not found');
    }

    cycleStartDate = userProfile.lastPeriodDate;
    cycleLength = userProfile.cycleLength;
    menstrualLength = userProfile.menstrualLength;
  }

  // Normalize dates to midnight to avoid time zone issues
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final normalizedCycleStart = DateTime(cycleStartDate.year, cycleStartDate.month, cycleStartDate.day);
  
  final daysSinceCycleStart = normalizedDate.difference(normalizedCycleStart).inDays;
  final cycleDay = (daysSinceCycleStart % cycleLength) + 1;

  // Calculate ovulation day: cycleLength − 14
  final ovulationDay = cycleLength - 14;

  // Get suggestion from adaptive table
  final suggestion = AdaptiveTable.getSuggestion(cycleDay, cycleLength, menstrualLength);

  // Determine phase
  late CyclePhase phase;
  late String displayName;
  late String colorCode;
  late int startDay;
  late int endDay;

  if (cycleDay >= 1 && cycleDay <= menstrualLength) {
    phase = CyclePhase.menstrual;
    displayName = 'Menstrual';
    colorCode = '#FF6B9D'; // Red/Pink
    startDay = 1;
    endDay = menstrualLength;
  } else if (cycleDay > menstrualLength && cycleDay < ovulationDay - 1) {
    phase = CyclePhase.follicular;
    displayName = 'Follicular';
    colorCode = '#FFB347'; // Orange
    startDay = menstrualLength + 1;
    endDay = ovulationDay - 2;
  } else if (cycleDay >= ovulationDay - 1 && cycleDay <= ovulationDay + 1) {
    phase = CyclePhase.ovulation;
    displayName = 'Ovulation';
    colorCode = '#87CEEB'; // Sky Blue
    startDay = ovulationDay - 1;
    endDay = ovulationDay + 1;
  } else {
    phase = CyclePhase.luteal;
    displayName = 'Luteal';
    colorCode = '#DDA0DD'; // Plum
    startDay = ovulationDay + 2;
    endDay = cycleLength;
  }

  return PhaseInfo(
    phase: phase,
    dayOfCycle: cycleDay,
    ovulationDay: ovulationDay,
    startDay: startDay,
    endDay: endDay,
    displayName: displayName,
    hormonePhase: suggestion.hormonalPhase,
    lifestylePhase: suggestion.lifestylePhase,
    colorCode: colorCode,
    suggestion: suggestion,
  );
});

/// Provider to get phase info for today
final currentPhaseProvider = FutureProvider<PhaseInfo>((ref) async {
  return ref.watch(cyclePhaseProvider(DateTime.now()).future);
});
