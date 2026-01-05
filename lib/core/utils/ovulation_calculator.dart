/// Ovulation day calculator
class OvulationCalculator {
  /// Calculate ovulation day
  /// Formula: ovulationDay = cycleLength - lutealPhaseLength
  ///
  /// Example:
  /// - cycleLength: 28
  /// - lutealPhaseLength: 14 (default)
  /// - Result: 14 (ovulation occurs on day 14)
  static int calculateOvulationDay({
    required int cycleLength,
    required int lutealPhaseLength,
  }) {
    return cycleLength - lutealPhaseLength;
  }

  /// Check if current cycle day is around ovulation
  /// Ovulation window: ovulationDay - 1 to ovulationDay + 1
  static bool isOvulationWindow({
    required int cycleDay,
    required int cycleLength,
    required int lutealPhaseLength,
  }) {
    final ovulationDay = calculateOvulationDay(
      cycleLength: cycleLength,
      lutealPhaseLength: lutealPhaseLength,
    );
    return cycleDay >= (ovulationDay - 1) && cycleDay <= (ovulationDay + 1);
  }

  /// Get ovulation date
  static DateTime getOvulationDate({
    required DateTime lastPeriodDate,
    required int cycleLength,
    required int lutealPhaseLength,
  }) {
    final ovulationDay = calculateOvulationDay(
      cycleLength: cycleLength,
      lutealPhaseLength: lutealPhaseLength,
    );
    return lastPeriodDate.add(Duration(days: ovulationDay - 1));
  }
}
