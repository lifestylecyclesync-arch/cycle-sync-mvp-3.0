/// Simple data model for phase recommendations
/// No code generation needed - straightforward class
class PhaseRecommendation {
  final String id;
  final String phaseName; // 'Menstrual', 'Follicular', 'Ovulation', 'Luteal'
  final String category; // 'Fitness', 'Nutrition', 'Fasting'
  final String title;
  final String? subtitle;
  final String description;
  final List<String> tips;
  
  // For Fasting category
  final int? fastingHoursMin;
  final int? fastingHoursMax;
  final String? fastingStyle;
  
  final int? orderIndex;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PhaseRecommendation({
    required this.id,
    required this.phaseName,
    required this.category,
    required this.title,
    this.subtitle,
    required this.description,
    this.tips = const [],
    this.fastingHoursMin,
    this.fastingHoursMax,
    this.fastingStyle,
    this.orderIndex,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert from Supabase response (snake_case to camelCase)
  factory PhaseRecommendation.fromSupabase(Map<String, dynamic> json) {
    return PhaseRecommendation(
      id: json['id'] as String,
      phaseName: json['phase_name'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String,
      tips: List<String>.from(json['tips'] as List? ?? []),
      fastingHoursMin: json['fasting_hours_min'] as int?,
      fastingHoursMax: json['fasting_hours_max'] as int?,
      fastingStyle: json['fasting_style'] as String?,
      orderIndex: json['order_index'] as int?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }
}
