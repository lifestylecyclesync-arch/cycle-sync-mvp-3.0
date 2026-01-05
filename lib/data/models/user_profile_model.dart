import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  UserProfileModel({
    required super.id,
    required super.name,
    required super.cycleLength,
    required super.menstrualLength,
    super.lutealPhaseLength = 14,
    required super.lastPeriodDate,
    super.lifestyleAreas = const [],
    super.fastingPreference = 'Beginner',
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      cycleLength: json['cycleLength'] as int,
      menstrualLength: json['menstrualLength'] as int,
      lutealPhaseLength: json['lutealPhaseLength'] as int? ?? 14,
      lastPeriodDate: DateTime.parse(json['lastPeriodDate'] as String),
      lifestyleAreas: List<String>.from(json['lifestyleAreas'] as List? ?? []),
      fastingPreference: json['fastingPreference'] as String? ?? 'Beginner',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cycleLength': cycleLength,
      'menstrualLength': menstrualLength,
      'lutealPhaseLength': lutealPhaseLength,
      'lastPeriodDate': lastPeriodDate.toIso8601String(),
      'lifestyleAreas': lifestyleAreas,
      'fastingPreference': fastingPreference,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  UserProfileModel copyWith({
    String? id,
    String? name,
    int? cycleLength,
    int? menstrualLength,
    int? lutealPhaseLength,
    DateTime? lastPeriodDate,
    List<String>? lifestyleAreas,
    String? fastingPreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cycleLength: cycleLength ?? this.cycleLength,
      menstrualLength: menstrualLength ?? this.menstrualLength,
      lutealPhaseLength: lutealPhaseLength ?? this.lutealPhaseLength,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      lifestyleAreas: lifestyleAreas ?? this.lifestyleAreas,
      fastingPreference: fastingPreference ?? this.fastingPreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to entity (domain layer)
  UserProfile toEntity() => this;
}
