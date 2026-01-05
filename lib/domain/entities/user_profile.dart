class UserProfile {
  final String id;
  final String name;
  final int cycleLength;
  final int menstrualLength;
  final int lutealPhaseLength; // Default: 14 days
  final DateTime lastPeriodDate;
  final List<String> lifestyleAreas; // e.g., ['Nutrition', 'Fitness', 'Fasting']
  final String fastingPreference; // 'Beginner' or 'Advanced'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.cycleLength,
    required this.menstrualLength,
    this.lutealPhaseLength = 14,
    required this.lastPeriodDate,
    this.lifestyleAreas = const [],
    this.fastingPreference = 'Beginner',
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
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
    return UserProfile(
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
}
