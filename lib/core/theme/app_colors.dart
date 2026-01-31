import 'package:flutter/material.dart';

/// Cycle Sync Color Palette
/// Warm minimalist design system
class AppColors {
  // ============================================================================
  // TAB ACCENT COLORS (per handbook)
  // ============================================================================
  
  /// My Cycle tab color - Lavender
  static const Color tabCycleLavender = Color(0xFFC8B6D6);
  
  /// Fitness tab color - Blush
  static const Color tabFitnessBlush = Color(0xFFF5D4C8);
  
  /// Diet tab color - Sage
  static const Color tabDietSage = Color(0xFFD4E8D4);
  
  /// Fasting tab color - Peach
  static const Color tabFastingPeach = Color(0xFFFFC9B9);
  
  /// Reports tab color - Mint
  static const Color tabReportsMint = Color(0xFFC8E6E1);
  
  // ============================================================================
  // SHORTHAND ALIASES
  // ============================================================================
  
  /// Alias for lavender (My Cycle tab)
  static const Color lavender = tabCycleLavender;
  
  /// Alias for blush (Fitness tab)
  static const Color blush = tabFitnessBlush;
  
  /// Alias for sage (Diet tab)
  static const Color sage = tabDietSage;
  
  /// Alias for peach (Fasting tab)
  static const Color peach = tabFastingPeach;
  
  /// Alias for mint (Reports tab)
  static const Color mint = tabReportsMint;
  
  /// Alias for menstrual phase
  static const Color menstrual = phasesMenstrual;
  
  /// Alias for follicular phase
  static const Color follicular = phasesFollicular;
  
  /// Alias for ovulation phase
  static const Color ovulation = phasesOvulation;
  
  /// Alias for luteal phase
  static const Color luteal = phasesLuteal;
  
  // ============================================================================
  // CYCLE PHASE COLORS
  // ============================================================================
  
  /// Menstrual phase color - Red/Rose
  static const Color phasesMenstrual = Color(0xFFE57373);
  
  /// Follicular phase color - Green
  static const Color phasesFollicular = Color(0xFF81C784);
  
  /// Ovulation phase color - Yellow
  static const Color phasesOvulation = Color(0xFFFFD54F);
  
  /// Luteal phase color - Purple
  static const Color phasesLuteal = Color(0xFFBA68C8);
  
  // ============================================================================
  // PRIMARY & SECONDARY
  // ============================================================================
  
  /// Primary brand color - Deep Purple
  static const Color primary = Color(0xFF6A4C93);
  
  /// Primary light variant
  static const Color primaryLight = Color(0xFFA78BCC);
  
  /// Primary dark variant
  static const Color primaryDark = Color(0xFF4A2C73);
  
  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================
  
  /// Pure white
  static const Color white = Color(0xFFFFFFFF);
  
  /// Pure black
  static const Color black = Color(0xFF000000);
  
  /// Gray 50 - Lightest gray
  static const Color gray50 = Color(0xFFFAFAFA);
  
  /// Gray 100
  static const Color gray100 = Color(0xFFF5F5F5);
  
  /// Gray 200
  static const Color gray200 = Color(0xFFEEEEEE);
  
  /// Gray 300
  static const Color gray300 = Color(0xFFE0E0E0);
  
  /// Gray 400
  static const Color gray400 = Color(0xFFBDBDBD);
  
  /// Gray 500
  static const Color gray500 = Color(0xFF9E9E9E);
  
  /// Gray 600
  static const Color gray600 = Color(0xFF757575);
  
  /// Gray 700
  static const Color gray700 = Color(0xFF616161);
  
  /// Gray 800
  static const Color gray800 = Color(0xFF424242);
  
  /// Gray 900 - Darkest gray
  static const Color gray900 = Color(0xFF212121);
  
  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================
  
  /// Success/positive state - Green
  static const Color success = Color(0xFF4CAF50);
  
  /// Warning/caution state - Orange
  static const Color warning = Color(0xFFFFA500);
  
  /// Error/negative state - Red
  static const Color error = Color(0xFFE53935);
  
  /// Info/informational state - Blue
  static const Color info = Color(0xFF2196F3);
  
  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================
  
  /// Primary background - Warm off-white
  static const Color backgroundPrimary = Color(0xFFFFFBF9);
  
  /// Secondary background
  static const Color backgroundSecondary = Color(0xFFFAF5F2);
  
  /// Tertiary background
  static const Color backgroundTertiary = Color(0xFFF5EFEA);
  
  // ============================================================================
  // TEXT COLORS
  // ============================================================================
  
  /// Primary text color - Dark gray/black
  static const Color textPrimary = Color(0xFF212121);
  
  /// Secondary text color - Medium gray
  static const Color textSecondary = Color(0xFF757575);
  
  /// Tertiary text color - Light gray
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  /// Placeholder text color
  static const Color textPlaceholder = Color(0xFFBDBDBD);
  
  // ============================================================================
  // OPACITY VARIANTS (For transparent phase circles per handbook)
  // ============================================================================
  
  /// Light opacity - 30%
  static const double opacityLight = 0.30;
  
  /// Medium opacity - 40%
  static const double opacityMedium = 0.40;
  
  /// Heavy opacity - 50%
  static const double opacityHeavy = 0.50;
  
  /// Disabled opacity
  static const double opacityDisabled = 0.5;
  
  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Get tab color by tab index
  static Color getTabColor(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return tabCycleLavender;
      case 1:
        return tabFitnessBlush;
      case 2:
        return tabDietSage;
      case 3:
        return tabFastingPeach;
      case 4:
        return tabReportsMint;
      default:
        return primary;
    }
  }
  
  /// Get phase color by phase name
  static Color getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return phasesMenstrual;
      case 'follicular':
        return phasesFollicular;
      case 'ovulation':
        return phasesOvulation;
      case 'luteal':
        return phasesLuteal;
      default:
        return gray300;
    }
  }
  
  /// Get tab name by tab index
  static String getTabName(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'My Cycle';
      case 1:
        return 'Fitness';
      case 2:
        return 'Diet';
      case 3:
        return 'Fasting';
      case 4:
        return 'Reports';
      default:
        return '';
    }
  }
}
