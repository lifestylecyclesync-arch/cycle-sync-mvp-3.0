/// Template System for Learn Cards
/// Provides dynamic, randomly-selected messages for Fitness, Diet, and Fasting recommendations
/// Each template uses placeholders like {Workout Mode}, {Food Vibe}, {Fast Style}
library;

class TemplateReference {
  /// Fitness templates - displayed when showing workout recommendations
  /// Placeholder: {Workout Mode}
  static const List<String> fitnessTemplates = [
    "Your body feels best with {Workout Mode} today.",
    "Your body is primed for {Workout Mode} today.",
    "Today your energy aligns with {Workout Mode}.",
    "Your energy naturally supports {Workout Mode} today.",
    "Your body responds well to {Workout Mode} right now.",
    "Your body welcomes {Workout Mode} today.",
    "{Workout Mode} feels most supportive.",
    "Your body finds harmony with {Workout Mode} today.",
  ];

  /// Diet templates - displayed when showing nutrition recommendations
  /// Placeholder: {Food Vibe}
  static const List<String> dietTemplates = [
    "Your body thrives on {Food Vibe} today.",
    "Your body feels deeply nourished by {Food Vibe} today.",
    "Today's best nourishment is {Food Vibe}.",
    "Your body responds beautifully to {Food Vibe} today.",
    "Lean into {Food Vibe} today.",
    "Let {Food Vibe} guide your meals today.",
    "With your body in this phase, {Food Vibe} supports balance.",
    "{Food Vibe} brings the balance you need today.",
  ];

  /// Fasting templates - displayed when showing fasting recommendations
  /// Placeholder: {Fast Style}
  static const List<String> fastingTemplates = [
    "Your ideal fasting window today is {Fast Style}.",
    "Your body settles well into a {Fast Style} today.",
    "Your body feels supported by a {Fast Style} today.",
    "Your system adapts well to a {Fast Style} today.",
    "Keep fasting to {Fast Style} today.",
    "A {Fast Style} keeps things balanced today.",
    "With today's rhythm, a {Fast Style} works best.",
    "Your rhythm today pairs well with a {Fast Style}.",
  ];

  /// Get a random template for the given day and category
  /// Uses the day to seed consistent randomization (same template per day)
  static String getTemplate({
    required List<String> templates,
    required DateTime date,
  }) {
    // Use date to seed randomization - ensures same template throughout the day
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final index = seed % templates.length;
    return templates[index];
  }

  /// Fill template placeholders with actual values
  static String fillTemplate({
    required String template,
    String? workoutMode,
    String? foodVibe,
    String? fastStyle,
  }) {
    var result = template;
    if (workoutMode != null) {
      result = result.replaceAll('{Workout Mode}', workoutMode);
    }
    if (foodVibe != null) {
      result = result.replaceAll('{Food Vibe}', foodVibe);
    }
    if (fastStyle != null) {
      result = result.replaceAll('{Fast Style}', fastStyle);
    }
    return result;
  }

  /// Get fitness template for a specific day
  static String getFitnessTemplate(DateTime date) {
    return getTemplate(templates: fitnessTemplates, date: date);
  }

  /// Get diet template for a specific day
  static String getDietTemplate(DateTime date) {
    return getTemplate(templates: dietTemplates, date: date);
  }

  /// Get fasting template for a specific day
  static String getFastingTemplate(DateTime date) {
    return getTemplate(templates: fastingTemplates, date: date);
  }
}
