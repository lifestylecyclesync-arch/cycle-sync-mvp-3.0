import 'package:cycle_sync_mvp_2/core/constants/enums.dart';
import 'package:cycle_sync_mvp_2/domain/entities/cycle_calculation.dart';

/// JSON-serializable model for CycleCalculation, used for Supabase and caching
class CycleCalculationModel extends CycleCalculation {
  const CycleCalculationModel({
    required super.id,
    required super.userId,
    required super.calculationDate,
    required super.cycleDay,
    required super.phaseType,
    required super.lifestylePhase,
    required super.hormonalState,
    required super.daysUntilNextPeriod,
    required super.isOvulationWindow,
    required super.isFirstDayOfCycle,
    required super.nextPeriodDate,
    required super.cycleStartDate,
    required super.cycleDayOfMonth,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from JSON (from Supabase or cache)
  factory CycleCalculationModel.fromJson(Map<String, dynamic> json) {
    return CycleCalculationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      calculationDate: DateTime.parse(json['calculation_date'] as String),
      cycleDay: json['cycle_day'] as int,
      phaseType: PhaseType.fromString(json['phase_type'] as String),
      lifestylePhase:
          LifestylePhase.fromString(json['lifestyle_phase'] as String),
      hormonalState: HormonalState.fromString(json['hormonal_state'] as String),
      daysUntilNextPeriod: json['days_until_next_period'] as int,
      isOvulationWindow: json['is_ovulation_window'] as bool,
      isFirstDayOfCycle: json['is_first_day_of_cycle'] as bool,
      nextPeriodDate: DateTime.parse(json['next_period_date'] as String),
      cycleStartDate: DateTime.parse(json['cycle_start_date'] as String),
      cycleDayOfMonth: json['cycle_day_of_month'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase or cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'calculation_date': calculationDate.toIso8601String(),
      'cycle_day': cycleDay,
      'phase_type': phaseType.toString().split('.').last,
      'lifestyle_phase': lifestylePhase.toString().split('.').last,
      'hormonal_state': hormonalState.toString().split('.').last,
      'days_until_next_period': daysUntilNextPeriod,
      'is_ovulation_window': isOvulationWindow,
      'is_first_day_of_cycle': isFirstDayOfCycle,
      'next_period_date': nextPeriodDate.toIso8601String(),
      'cycle_start_date': cycleStartDate.toIso8601String(),
      'cycle_day_of_month': cycleDayOfMonth,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity (domain layer)
  CycleCalculation toEntity() => this;
}
