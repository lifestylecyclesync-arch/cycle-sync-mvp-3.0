import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/constants/enums.dart';

/// Phase color configuration
/// Easily swappable for future aesthetic changes
class PhaseColors {
  // Menstrual phase
  static const Color menstrual = Color(0xFF9C27B0); // Deep Purple

  // Follicular phase
  static const Color follicular = Color(0xFFFFA500); // Orange

  // Ovulation phase
  static const Color ovulation = Color(0xFFE91E63); // Pink

  // Luteal phase
  static const Color luteal = Color(0xFF3F51B5); // Indigo

  /// Get color for phase type
  static Color getPhaseColor(PhaseType phase) {
    switch (phase) {
      case PhaseType.menstrual:
        return menstrual;
      case PhaseType.follicularEarly:
      case PhaseType.follicularLate:
        return follicular;
      case PhaseType.ovulation:
        return ovulation;
      case PhaseType.earlyLuteal:
      case PhaseType.lateLuteal:
        return luteal;
    }
  }

  /// Get color with reduced opacity for planner circles
  /// Default opacity: 30-40%
  static Color getPhaseColorWithOpacity(
    PhaseType phase, {
    double opacity = 0.35,
  }) {
    return getPhaseColor(phase).withOpacity(opacity);
  }

  /// Update colors easily - just modify these constants
  static void updateColors({
    Color? menstrualColor,
    Color? follicularColor,
    Color? ovulationColor,
    Color? lutealColor,
  }) {
    // Note: In a real app, you'd use a provider or ValueNotifier for reactive updates
    // For now, modify the constants directly above
  }
}
