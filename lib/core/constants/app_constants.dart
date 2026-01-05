import 'package:flutter/material.dart';

/// App-wide design system constants
/// Easily configurable for future theme changes
class AppConstants {
  // ============================================
  // Spacing & Layout
  // ============================================
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double paddingDefault = spacingMd;
  static const double paddingLarge = spacingLg;

  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusCircle = 50.0;

  // ============================================
  // Typography
  // ============================================
  static const String fontFamilyPrimary = 'Roboto'; // Material default

  static const FontWeight fontWeightThin = FontWeight.w100;
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // Font sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSizeXxl = 24.0;
  static const double fontSizeHuge = 32.0;

  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // ============================================
  // Colors (Minimalist Palette)
  // ============================================

  // Neutral colors
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorBlack = Color(0xFF000000);
  static const Color colorGray50 = Color(0xFFFAFAFA);
  static const Color colorGray100 = Color(0xFFF5F5F5);
  static const Color colorGray200 = Color(0xFFEEEEEE);
  static const Color colorGray300 = Color(0xFFE0E0E0);
  static const Color colorGray400 = Color(0xFFBDBDBD);
  static const Color colorGray500 = Color(0xFF9E9E9E);
  static const Color colorGray600 = Color(0xFF757575);
  static const Color colorGray700 = Color(0xFF616161);
  static const Color colorGray800 = Color(0xFF424242);
  static const Color colorGray900 = Color(0xFF212121);

  // Semantic colors
  static const Color colorPrimary = Color(0xFF6A4C93); // Deep Purple
  static const Color colorPrimaryLight = Color(0xFFA78BCC);
  static const Color colorPrimaryDark = Color(0xFF4A2C73);

  static const Color colorSuccess = Color(0xFF4CAF50); // Green
  static const Color colorWarning = Color(0xFFFFA500); // Orange
  static const Color colorError = Color(0xFFE53935); // Red
  static const Color colorInfo = Color(0xFF2196F3); // Blue

  // Background
  static const Color colorBackground = colorWhite;
  static const Color colorBackgroundLight = colorGray50;
  static const Color colorBackgroundLighter = colorGray100;

  // Text colors
  static const Color colorTextPrimary = colorGray900;
  static const Color colorTextSecondary = colorGray600;
  static const Color colorTextTertiary = colorGray500;
  static const Color colorTextPlaceholder = colorGray400;

  // ============================================
  // Opacity & Transparency
  // ============================================
  static const double opacityDisabled = 0.5;
  static const double opacityHover = 0.8;
  static const double opacityPhaseLight = 0.3; // Transparent phase circles
  static const double opacityPhaseMedium = 0.35;
  static const double opacityPhaseHeavy = 0.4;

  // ============================================
  // Component sizes
  // ============================================
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXl = 48.0;

  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXl = 96.0;

  // ============================================
  // Animations
  // ============================================
  static const Duration durationQuick = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ============================================
  // Shadows
  // ============================================
  static const BoxShadow shadowSmall = BoxShadow(
    color: Color(0x12000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowLarge = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  // ============================================
  // Misc
  // ============================================
  static const double dividerThickness = 1.0;
  static const double bottomNavBarHeight = 64.0;
  static const double appBarHeight = 56.0;
  static const double fabSize = 56.0;
}
