import 'package:cycle_sync_mvp_2/core/constants/enums.dart';
import 'package:cycle_sync_mvp_2/core/utils/ovulation_calculator.dart';

/// Phase mapper utility
/// Maps cycle day to phase information
class PhaseMapper {
  /// Get phase type for a given cycle day
  static PhaseType getPhaseType({
    required int cycleDay,
    required int cycleLength,
    required int menstrualLength,
    required int lutealPhaseLength,
  }) {
    final ovulationDay = OvulationCalculator.calculateOvulationDay(
      cycleLength: cycleLength,
      lutealPhaseLength: lutealPhaseLength,
    );

    // Menstrual phase: Day 1 to menstrualLength
    if (cycleDay >= 1 && cycleDay <= menstrualLength) {
      return PhaseType.menstrual;
    }

    // Follicular Early: Day (menstrualLength + 1) to (menstrualLength + 5)
    if (cycleDay > menstrualLength && cycleDay <= (menstrualLength + 5)) {
      return PhaseType.follicularEarly;
    }

    // Follicular Late: Day (menstrualLength + 6) to (ovulationDay - 2)
    if (cycleDay > (menstrualLength + 5) && cycleDay < (ovulationDay - 1)) {
      return PhaseType.follicularLate;
    }

    // Ovulation: Day (ovulationDay - 1) to (ovulationDay + 1)
    if (cycleDay >= (ovulationDay - 1) && cycleDay <= (ovulationDay + 1)) {
      return PhaseType.ovulation;
    }

    // Early Luteal: Day (ovulationDay + 2) to (ovulationDay + 5)
    if (cycleDay >= (ovulationDay + 2) && cycleDay <= (ovulationDay + 5)) {
      return PhaseType.earlyLuteal;
    }

    // Late Luteal: Day (ovulationDay + 6) to cycleLength
    return PhaseType.lateLuteal;
  }

  /// Get lifestyle phase for a given cycle day
  static LifestylePhase getLifestylePhase({
    required int cycleDay,
    required int cycleLength,
    required int menstrualLength,
    required int lutealPhaseLength,
  }) {
    final phaseType = getPhaseType(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      menstrualLength: menstrualLength,
      lutealPhaseLength: lutealPhaseLength,
    );

    switch (phaseType) {
      case PhaseType.menstrual:
        return LifestylePhase.glowReset;
      case PhaseType.follicularEarly:
      case PhaseType.earlyLuteal:
        return LifestylePhase.powerUp;
      case PhaseType.follicularLate:
      case PhaseType.ovulation:
        return LifestylePhase.mainCharacter;
      case PhaseType.lateLuteal:
        return LifestylePhase.cozyCare;
    }
  }

  /// Get hormonal state for a given phase
  static HormonalState getHormonalState({
    required int cycleDay,
    required int cycleLength,
    required int menstrualLength,
    required int lutealPhaseLength,
  }) {
    final phaseType = getPhaseType(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      menstrualLength: menstrualLength,
      lutealPhaseLength: lutealPhaseLength,
    );

    switch (phaseType) {
      case PhaseType.menstrual:
        return HormonalState.lowELowP;
      case PhaseType.follicularEarly:
        return HormonalState.risingE;
      case PhaseType.follicularLate:
      case PhaseType.ovulation:
        return HormonalState.peakE;
      case PhaseType.earlyLuteal:
        return HormonalState.decliningERisingP;
      case PhaseType.lateLuteal:
        return HormonalState.lowEHighP;
    }
  }

  /// Get phase range (start and end days) for a given phase type
  static ({int start, int end}) getPhaseRange({
    required PhaseType phaseType,
    required int cycleLength,
    required int menstrualLength,
    required int lutealPhaseLength,
  }) {
    final ovulationDay = OvulationCalculator.calculateOvulationDay(
      cycleLength: cycleLength,
      lutealPhaseLength: lutealPhaseLength,
    );

    switch (phaseType) {
      case PhaseType.menstrual:
        return (start: 1, end: menstrualLength);

      case PhaseType.follicularEarly:
        return (start: menstrualLength + 1, end: menstrualLength + 5);

      case PhaseType.follicularLate:
        return (start: menstrualLength + 6, end: ovulationDay - 2);

      case PhaseType.ovulation:
        return (start: ovulationDay - 1, end: ovulationDay + 1);

      case PhaseType.earlyLuteal:
        return (start: ovulationDay + 2, end: ovulationDay + 5);

      case PhaseType.lateLuteal:
        return (start: ovulationDay + 6, end: cycleLength);
    }
  }
}
