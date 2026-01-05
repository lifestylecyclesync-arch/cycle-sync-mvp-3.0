import 'package:cycle_sync_mvp_2/core/constants/enums.dart';

/// Represents a single calculation/snapshot of cycle information for a specific date
class CycleCalculation {
  final String id;
  final String userId;
  final DateTime calculationDate;
  final int cycleDay;
  final PhaseType phaseType;
  final LifestylePhase lifestylePhase;
  final HormonalState hormonalState;
  final int daysUntilNextPeriod;
  final bool isOvulationWindow;
  final bool isFirstDayOfCycle;
  final DateTime nextPeriodDate;
  final DateTime cycleStartDate;
  final int cycleDayOfMonth; // Which cycle we're in (for multi-month tracking)
  final DateTime createdAt;
  final DateTime updatedAt;

  const CycleCalculation({
    required this.id,
    required this.userId,
    required this.calculationDate,
    required this.cycleDay,
    required this.phaseType,
    required this.lifestylePhase,
    required this.hormonalState,
    required this.daysUntilNextPeriod,
    required this.isOvulationWindow,
    required this.isFirstDayOfCycle,
    required this.nextPeriodDate,
    required this.cycleStartDate,
    required this.cycleDayOfMonth,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get a human-readable phase name
  String get phaseDisplayName => phaseType.toDisplayString();

  /// Get a human-readable lifestyle phase name
  String get lifestyleDisplayName => lifestylePhase.toDisplayString();

  /// Create a copy with optional field overrides
  CycleCalculation copyWith({
    String? id,
    String? userId,
    DateTime? calculationDate,
    int? cycleDay,
    PhaseType? phaseType,
    LifestylePhase? lifestylePhase,
    HormonalState? hormonalState,
    int? daysUntilNextPeriod,
    bool? isOvulationWindow,
    bool? isFirstDayOfCycle,
    DateTime? nextPeriodDate,
    DateTime? cycleStartDate,
    int? cycleDayOfMonth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleCalculation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      calculationDate: calculationDate ?? this.calculationDate,
      cycleDay: cycleDay ?? this.cycleDay,
      phaseType: phaseType ?? this.phaseType,
      lifestylePhase: lifestylePhase ?? this.lifestylePhase,
      hormonalState: hormonalState ?? this.hormonalState,
      daysUntilNextPeriod: daysUntilNextPeriod ?? this.daysUntilNextPeriod,
      isOvulationWindow: isOvulationWindow ?? this.isOvulationWindow,
      isFirstDayOfCycle: isFirstDayOfCycle ?? this.isFirstDayOfCycle,
      nextPeriodDate: nextPeriodDate ?? this.nextPeriodDate,
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      cycleDayOfMonth: cycleDayOfMonth ?? this.cycleDayOfMonth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'CycleCalculation(userId: $userId, date: $calculationDate, cycleDay: $cycleDay, phase: $phaseType)';
}
