/// Cycle Sync App-wide Constants
/// Cycle calculations, thresholds, and durations
class AppConstants {
  // ============================================================================
  // CYCLE PARAMETERS - Based on menstrual research
  // ============================================================================
  
  /// Typical menstrual cycle length in days (28 ± 7)
  static const int typicalCycleLength = 28;
  
  /// Minimum cycle length (lower bound) - 21 days
  static const int minCycleLength = 21;
  
  /// Maximum cycle length (upper bound) - 35 days
  static const int maxCycleLength = 35;
  
  /// Typical menstrual period length in days
  static const int typicalMenstrualLength = 5;
  
  /// Minimum menstrual period length - 2 days
  static const int minMenstrualLength = 2;
  
  /// Maximum menstrual period length - 10 days
  static const int maxMenstrualLength = 10;
  
  // ============================================================================
  // PHASE DURATIONS (in days) - For 28-day cycle
  // ============================================================================
  
  /// Menstrual phase - days 1-5
  static const int menstrualPhaseDays = 5;
  
  /// Follicular phase - days 1-13 (overlaps with menstrual)
  static const int follicularPhaseDays = 13;
  
  /// Ovulation phase - days 13-15 (peak fertility)
  static const int ovulationPhaseDays = 3;
  
  /// Luteal phase - days 16-28
  static const int lutealPhaseDays = 13;
  
  /// Default luteal phase length if not specified
  static const int defaultLutealLength = 14;
  
  // ============================================================================
  // OVULATION CALCULATION
  // ============================================================================
  
  /// Day of ovulation from cycle start (14th day for 28-day cycle)
  static const int ovulationDayOffset = 14;
  
  /// Fertile window starts N days before ovulation
  static const int fertileWindowPreOvulation = 5;
  
  /// Fertile window ends N days after ovulation
  static const int fertileWindowPostOvulation = 1;
  
  // ============================================================================
  // PMS/PMDD THRESHOLDS
  // ============================================================================
  
  /// Days before menstruation when PMS typically starts
  static const int pmsDaysBeforeMenstruation = 5;
  
  /// Minimum severity score (1-5 scale) to mark as PMS day
  static const int pmsMinimumSeverity = 2;
  
  // ============================================================================
  // HYDRATION & NUTRITION
  // ============================================================================
  
  /// Recommended daily water intake in mL
  static const int recommendedDailyWaterMl = 2000;
  
  /// Recommended daily caffeine limit in mg
  static const int recommendedDailyCaffeineLimitMg = 400;
  
  /// Recommended iron intake during menstruation (mg)
  static const int ironIntakeMenstruation = 18;
  
  /// Recommended iron intake outside menstruation (mg)
  static const int ironIntakeNormal = 15;
  
  // ============================================================================
  // SLEEP & ENERGY
  // ============================================================================
  
  /// Recommended sleep duration (hours) - general
  static const int recommendedSleepHours = 8;
  
  /// Recommended minimum sleep hours
  static const int minimumSleepHours = 7;
  
  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  
  /// Fast animation duration (ms) - UI elements, transitions
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  
  /// Standard animation duration (ms) - default transitions
  static const Duration animationDurationStandard = Duration(milliseconds: 300);
  
  /// Slow animation duration (ms) - complex animations
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  /// Very slow animation duration (ms) - emphasis animations
  static const Duration animationDurationVerySlow = Duration(milliseconds: 800);
  
  // ============================================================================
  // TIME CONSTRAINTS
  // ============================================================================
  
  /// Session timeout duration (15 minutes)
  static const Duration sessionTimeoutDuration = Duration(minutes: 15);
  
  /// Cache expiration time (1 hour)
  static const Duration cacheExpirationDuration = Duration(hours: 1);
  
  /// Debounce duration for text input (300ms)
  static const Duration debounceTextInputDuration = Duration(milliseconds: 300);
  
  /// Debounce duration for API calls (500ms)
  static const Duration debounceApiCallDuration = Duration(milliseconds: 500);
  
  // ============================================================================
  // UI CONSTRAINTS
  // ============================================================================
  
  /// Maximum width for content on tablet/desktop screens (px)
  static const double maxContentWidth = 600.0;
  
  /// Standard FAB size - 56px (Material spec)
  static const double fabSize = 56.0;
  
  /// Small FAB size - 40px
  static const double fabSizeSmall = 40.0;
  
  /// Maximum snackbar width (px)
  static const double maxSnackbarWidth = 500.0;
  
  // ============================================================================
  // DATETIME FORMATS
  // ============================================================================
  
  /// Date format for display: "Jan 15, 2024"
  static const String dateFormatDisplay = 'MMM d, yyyy';
  
  /// Date format for storage: "2024-01-15"
  static const String dateFormatStorage = 'yyyy-MM-dd';
  
  /// Time format: "2:30 PM"
  static const String timeFormatDisplay = 'h:mm a';
  
  /// Time format 24-hour: "14:30"
  static const String timeFormat24Hour = 'HH:mm';
  
  /// DateTime format with time: "Jan 15, 2024, 2:30 PM"
  static const String dateTimeFormatDisplay = 'MMM d, yyyy, h:mm a';
  
  // ============================================================================
  // VALIDATION
  // ============================================================================
  
  /// Minimum password length
  static const int minPasswordLength = 8;
  
  /// Minimum email length
  static const int minEmailLength = 5;
  
  /// Maximum email length
  static const int maxEmailLength = 254;
  
  /// Maximum cycle note length (characters)
  static const int maxCycleNoteLength = 500;
  
  /// Maximum user bio length (characters)
  static const int maxUserBioLength = 160;
  
  // ============================================================================
  // PAGINATION & LISTS
  // ============================================================================
  
  /// Default page size for paginated lists
  static const int defaultPageSize = 20;
  
  /// Maximum list items to load before pagination
  static const int maxListItemsBeforePagination = 50;
  
  // ============================================================================
  // TRACKING PARAMETERS
  // ============================================================================
  
  /// Maximum number of symptoms that can be logged per day
  static const int maxSymptomsPerDay = 10;
  
  /// Maximum number of workout entries per day
  static const int maxWorkoutsPerDay = 5;
  
  /// Maximum number of meal entries per day
  static const int maxMealsPerDay = 6;
  
  /// Maximum number of fasting logs per day
  static const int maxFastingLogsPerDay = 1;
  
  // ============================================================================
  // PHASE LIFESTYLE NAMES - Maps hormonal phase to lifestyle phase name
  // ============================================================================
  
  /// Maps each cycle phase to its lifestyle/wellness name
  static const Map<String, String> phaseLifestyleNames = {
    'Menstrual': 'Cozy Care',       // Rest, comfort, self-care
    'Follicular': 'Power Up',       // Energy, growth, building
    'Ovulation': 'Shine',            // Radiance, peak, social
    'Luteal': 'Restore',             // Restoration, slowdown, reflection
  };
  
  /// Get lifestyle name for a given hormonal phase
  static String getLifestyleName(String hormonalPhase) {
    return phaseLifestyleNames[hormonalPhase] ?? 'Wellness';
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get cycle length in days
  static int getCycleLength({int? customCycleLength}) {
    if (customCycleLength != null) {
      return customCycleLength.clamp(minCycleLength, maxCycleLength);
    }
    return typicalCycleLength;
  }
  
  /// Calculate ovulation day for given cycle length
  static int calculateOvulationDay(int cycleLength) {
    // Typical formula: Cycle length - 14 days
    // For 28 day cycle: 28 - 14 = 14 (day 14 of cycle)
    return cycleLength - 14;
  }
  
  /// Calculate fertile window start day
  static int calculateFertileWindowStart(int cycleLength) {
    final ovulationDay = calculateOvulationDay(cycleLength);
    return (ovulationDay - fertileWindowPreOvulation).clamp(1, cycleLength);
  }
  
  /// Calculate fertile window end day
  static int calculateFertileWindowEnd(int cycleLength) {
    final ovulationDay = calculateOvulationDay(cycleLength);
    return (ovulationDay + fertileWindowPostOvulation).clamp(1, cycleLength);
  }
}
