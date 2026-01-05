/// Fasting preference level
enum FastingPreference {
  beginner,
  advanced;

  String toDisplayString() {
    return name[0].toUpperCase() + name.substring(1);
  }

  static FastingPreference fromString(String value) {
    return FastingPreference.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => FastingPreference.beginner,
    );
  }
}

/// Lifestyle areas for personalization
enum LifestyleArea {
  nutrition,
  fitness,
  fasting;

  String toDisplayString() {
    return name[0].toUpperCase() + name.substring(1);
  }

  static LifestyleArea fromString(String value) {
    return LifestyleArea.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => LifestyleArea.nutrition,
    );
  }
}

/// Bottom navigation tabs
enum BottomNavTab {
  dashboard,
  planner,
  insights,
  profile;

  String toDisplayString() {
    return name[0].toUpperCase() + name.substring(1);
  }

  static BottomNavTab fromString(String value) {
    return BottomNavTab.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => BottomNavTab.dashboard,
    );
  }
}

/// Cycle phases
enum PhaseType {
  menstrual,
  follicularEarly,
  follicularLate,
  ovulation,
  earlyLuteal,
  lateLuteal;

  String toDisplayString() {
    switch (this) {
      case PhaseType.menstrual:
        return 'Menstrual';
      case PhaseType.follicularEarly:
        return 'Follicular (Early)';
      case PhaseType.follicularLate:
        return 'Follicular (Late)';
      case PhaseType.ovulation:
        return 'Ovulation';
      case PhaseType.earlyLuteal:
        return 'Early Luteal';
      case PhaseType.lateLuteal:
        return 'Late Luteal';
    }
  }

  static PhaseType fromString(String value) {
    return PhaseType.values.firstWhere(
      (e) => e.toDisplayString().toLowerCase() == value.toLowerCase(),
      orElse: () => PhaseType.menstrual,
    );
  }
}

/// Lifestyle phases for UI presentation
enum LifestylePhase {
  glowReset,
  powerUp,
  mainCharacter,
  cozyCare;

  String toDisplayString() {
    switch (this) {
      case LifestylePhase.glowReset:
        return 'Glow Reset';
      case LifestylePhase.powerUp:
        return 'Power Up';
      case LifestylePhase.mainCharacter:
        return 'Main Character';
      case LifestylePhase.cozyCare:
        return 'Cozy Care';
    }
  }

  static LifestylePhase fromString(String value) {
    return LifestylePhase.values.firstWhere(
      (e) => e.toDisplayString().toLowerCase() == value.toLowerCase(),
      orElse: () => LifestylePhase.glowReset,
    );
  }
}

/// Hormonal state descriptions
enum HormonalState {
  lowELowP,
  risingE,
  peakE,
  decliningERisingP,
  lowEHighP;

  String toDisplayString() {
    switch (this) {
      case HormonalState.lowELowP:
        return 'Low E, Low P';
      case HormonalState.risingE:
        return 'Rising E';
      case HormonalState.peakE:
        return 'Peak E';
      case HormonalState.decliningERisingP:
        return 'Declining E, Rising P';
      case HormonalState.lowEHighP:
        return 'Low E, High P';
    }
  }

  static HormonalState fromString(String value) {
    return HormonalState.values.firstWhere(
      (e) => e.toDisplayString().toLowerCase() == value.toLowerCase(),
      orElse: () => HormonalState.lowELowP,
    );
  }
}
