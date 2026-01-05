/// Cycle day calculator utility
class CycleDayCalculator {
  /// Calculate current cycle day
  /// Formula: cycleDay = (currentDate - lastPeriodDate) mod cycleLength + 1
  ///
  /// Example:
  /// - lastPeriodDate: 2024-01-01
  /// - currentDate: 2024-01-15
  /// - cycleLength: 28
  /// - Result: 15
  static int calculateCycleDay({
    required DateTime lastPeriodDate,
    required int cycleLength,
    DateTime? currentDate,
  }) {
    final today = currentDate ?? DateTime.now();
    final daysDiff = today.difference(lastPeriodDate).inDays;
    return (daysDiff % cycleLength) + 1;
  }

  /// Check if a given date is within the cycle
  static bool isDateInCurrentCycle({
    required DateTime date,
    required DateTime lastPeriodDate,
    required int cycleLength,
  }) {
    final cycleStart = lastPeriodDate;
    final cycleEnd = lastPeriodDate.add(Duration(days: cycleLength));
    return date.isAfter(cycleStart) && date.isBefore(cycleEnd);
  }

  /// Get next period date based on current cycle
  static DateTime getNextPeriodDate({
    required DateTime lastPeriodDate,
    required int cycleLength,
  }) {
    return lastPeriodDate.add(Duration(days: cycleLength));
  }

  /// Get current cycle start date
  static DateTime getCurrentCycleStart({
    required DateTime lastPeriodDate,
    required int cycleLength,
    DateTime? currentDate,
  }) {
    final today = currentDate ?? DateTime.now();
    final daysSinceLast = today.difference(lastPeriodDate).inDays;
    final cyclesCompleted = daysSinceLast ~/ cycleLength;
    return lastPeriodDate.add(Duration(days: cycleLength * cyclesCompleted));
  }
}
