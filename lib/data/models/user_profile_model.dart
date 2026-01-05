import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.cycleLength,
    required super.menstrualLength,
    required super.lastPeriodDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      cycleLength: json['cycleLength'] as int,
      menstrualLength: json['menstrualLength'] as int,
      lastPeriodDate: DateTime.parse(json['lastPeriodDate'] as String),
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
      'lastPeriodDate': lastPeriodDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? name,
    int? cycleLength,
    int? menstrualLength,
    DateTime? lastPeriodDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cycleLength: cycleLength ?? this.cycleLength,
      menstrualLength: menstrualLength ?? this.menstrualLength,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
