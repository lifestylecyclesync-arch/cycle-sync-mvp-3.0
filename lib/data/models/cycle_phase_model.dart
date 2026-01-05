import 'package:cycle_sync_mvp_2/core/constants/enums.dart';
import 'package:cycle_sync_mvp_2/domain/entities/cycle_phase.dart';

/// JSON-serializable model for CyclePhase, used for Supabase and caching
class CyclePhaseModel extends CyclePhase {
  const CyclePhaseModel({
    required super.id,
    required super.name,
    required super.description,
    required super.phaseType,
    required super.lifestylePhase,
    required super.hormonalState,
    required super.startDay,
    required super.endDay,
    required super.color,
    required super.recommendations,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from JSON (from Supabase or cache)
  factory CyclePhaseModel.fromJson(Map<String, dynamic> json) {
    return CyclePhaseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      phaseType: PhaseType.fromString(json['phase_type'] as String),
      lifestylePhase:
          LifestylePhase.fromString(json['lifestyle_phase'] as String),
      hormonalState: HormonalState.fromString(json['hormonal_state'] as String),
      startDay: json['start_day'] as int,
      endDay: json['end_day'] as int,
      color: json['color'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase or cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'phase_type': phaseType.toString().split('.').last,
      'lifestyle_phase': lifestylePhase.toString().split('.').last,
      'hormonal_state': hormonalState.toString().split('.').last,
      'start_day': startDay,
      'end_day': endDay,
      'color': color,
      'recommendations': recommendations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity (domain layer)
  CyclePhase toEntity() => this;
}
