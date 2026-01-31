import 'package:flutter/material.dart';

/// Cycle Sync Typography System
/// Warm, readable, hierarchical text styles
class AppTypography {
  // ============================================================================
  // TEXT THEMES - For use with DefaultTextStyle
  // ============================================================================
  
  /// Header 1 - Extra large, bold, used for screen titles
  static const TextStyle header1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: Color(0xFF2D2D2D),
  );
  
  /// Header 2 - Large, bold, used for section titles
  static const TextStyle header2 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: Color(0xFF2D2D2D),
  );
  
  /// Header 3 - Medium, semibold, used for subsection titles
  static const TextStyle header3 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
    color: Color(0xFF2D2D2D),
  );
  
  /// Subtitle 1 - Smaller header style, for secondary titles
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.4,
    color: Color(0xFF2D2D2D),
  );
  
  /// Subtitle 2 - Small header style, for tertiary titles
  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
    color: Color(0xFF2D2D2D),
  );
  
  /// Body 1 - Large body text for main content
  static const TextStyle body1 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: Color(0xFF4A4A4A),
  );
  
  /// Body 2 - Normal body text for primary content
  static const TextStyle body2 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
    color: Color(0xFF4A4A4A),
  );
  
  /// Caption - Small text for secondary/tertiary info
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.6,
    color: Color(0xFF7A7A7A),
  );
  
  /// Overline - Extra small text for labels/badges
  static const TextStyle overline = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.6,
    color: Color(0xFF7A7A7A),
  );
  
  /// Button Text - Medium weight for button labels
  static const TextStyle button = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.5,
    color: Color(0xFFFFFFFF),
  );
  
  /// Button Small - Smaller button text
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.5,
    color: Color(0xFFFFFFFF),
  );
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Apply custom color to a text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  /// Apply opacity to text color
  static TextStyle withOpacity(TextStyle style, double opacity) {
    if (style.color == null) return style;
    return style.copyWith(
      color: style.color!.withOpacity(opacity),
    );
  }
  
  /// Create custom text style based on body1
  static TextStyle custom({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0.2,
    double height = 1.5,
    Color color = const Color(0xFF4A4A4A),
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
}
