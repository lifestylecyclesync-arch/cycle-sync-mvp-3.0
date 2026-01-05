import 'package:cycle_sync_mvp_2/core/constants/enums.dart';

/// Represents a phase of the menstrual cycle with its characteristics
class CyclePhase {
  final String id;
  final String name;
  final String description;
  final PhaseType phaseType;
  final LifestylePhase lifestylePhase;
  final HormonalState hormonalState;
  final int startDay; // Relative to cycle start (1-based)
  final int endDay; // Relative to cycle start (1-based)
  final String color;
  final List<String> recommendations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CyclePhase({
    required this.id,
    required this.name,
    required this.description,
    required this.phaseType,
    required this.lifestylePhase,
    required this.hormonalState,
    required this.startDay,
    required this.endDay,
    required this.color,
    required this.recommendations,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the duration of this phase in days
  int get duration => endDay - startDay + 1;

  /// Check if a cycle day falls within this phase
  bool containsDay(int cycleDay) => cycleDay >= startDay && cycleDay <= endDay;

  /// Create a copy with optional field overrides
  CyclePhase copyWith({
    String? id,
    String? name,
    String? description,
    PhaseType? phaseType,
    LifestylePhase? lifestylePhase,
    HormonalState? hormonalState,
    int? startDay,
    int? endDay,
    String? color,
    List<String>? recommendations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CyclePhase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      phaseType: phaseType ?? this.phaseType,
      lifestylePhase: lifestylePhase ?? this.lifestylePhase,
      hormonalState: hormonalState ?? this.hormonalState,
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
      color: color ?? this.color,
      recommendations: recommendations ?? this.recommendations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'CyclePhase(id: $id, name: $name, phaseType: $phaseType, days: $startDay-$endDay)';
}
