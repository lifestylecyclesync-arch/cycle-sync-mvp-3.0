class LearnTemplate {
  final String id;
  final String category; // 'My Cycle', 'Fitness', 'Diet', 'Fasting'
  final String templateText; // 'Your body feels best with {Workout Mode} today.'
  final String? placeholderKeys; // 'Workout Mode' or 'Hormonal Phase|Lifestyle Phase' (pipe-separated for multiple)
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearnTemplate({
    required this.id,
    required this.category,
    required this.templateText,
    this.placeholderKeys,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get list of placeholder keys (handles both single and pipe-separated)
  List<String> getPlaceholderKeysList() {
    if (placeholderKeys == null || placeholderKeys!.isEmpty) {
      return [];
    }
    return placeholderKeys!.split('|');
  }

  /// Create from Supabase JSON response
  factory LearnTemplate.fromMap(Map<String, dynamic> map) {
    return LearnTemplate(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      templateText: map['template_text'] ?? '',
      placeholderKeys: map['placeholder_key'],
      sortOrder: map['sort_order'] ?? 0,
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'template_text': templateText,
      'placeholder_key': placeholderKeys,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Replace single placeholder with value
  /// e.g., "Your body feels best with {Workout Mode} today." + "Yoga" = "Your body feels best with Yoga today."
  String fillTemplate(String? value) {
    if (placeholderKeys == null || value == null || value.isEmpty) {
      return templateText;
    }
    // For single placeholder, just replace directly
    final keys = getPlaceholderKeysList();
    if (keys.length == 1) {
      return templateText.replaceAll('{${keys[0]}}', value);
    }
    // For multiple placeholders, replace first one only (caller should handle multiple)
    return templateText.replaceAll('{${keys[0]}}', value);
  }

  /// Replace multiple placeholders with values
  /// e.g., "You are in your {Hormonal Phase} phase\nthis is a {Lifestyle Phase} day." + ["Menstrual", "Low Energy"] 
  /// = "You are in your Menstrual phase\nthis is a Low Energy day."
  String fillTemplateMultiple(List<String> values) {
    if (placeholderKeys == null || placeholderKeys!.isEmpty) {
      return templateText;
    }
    
    final keys = getPlaceholderKeysList();
    String result = templateText;
    
    for (int i = 0; i < keys.length && i < values.length; i++) {
      if (values[i].isNotEmpty) {
        result = result.replaceAll('{${keys[i]}}', values[i]);
      }
    }
    
    return result;
  }

  @override
  String toString() =>
      'LearnTemplate(id: $id, category: $category, placeholders: $placeholderKeys)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearnTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          category == other.category;

  @override
  int get hashCode => id.hashCode ^ category.hashCode;
}
