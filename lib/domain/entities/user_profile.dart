class UserProfile {
  final String id;
  final String name;
  final int cycleLength;
  final int menstrualLength;
  final DateTime lastPeriodDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.cycleLength,
    required this.menstrualLength,
    required this.lastPeriodDate,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    int? cycleLength,
    int? menstrualLength,
    DateTime? lastPeriodDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
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
