import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Singleton pattern for app theme configuration
/// Provides centralized access to colors, typography, and styling
class AppTheme {
  static final AppTheme _instance = AppTheme._internal();

  factory AppTheme() {
    return _instance;
  }

  AppTheme._internal();

  // Color Palette - Modern SST with Gradients
  static const Color primaryNavy = Color(0xFF1E3A5F);
  static const Color secondaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF7FB3E8);
  static const Color veryLightBlue = Color(0xFFE8F4FD);
  static const Color successGreen = Color(0xFF34D399);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundGradientStart = Color(0xFFE0F2FE);
  static const Color backgroundGradientEnd = Color(0xFFFFFBEB);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Shared dashboard palette, kept here so future workspace pages stay consistent.
  static const Color dashboardBackground = Color(0xFFEAF5FD);
  static const Color dashboardBlue = Color(0xFF1684F8);
  static const Color dashboardBlueDark = Color(0xFF082D68);
  static const Color dashboardGreen = Color(0xFF10C995);
  static const Color dashboardOrange = Color(0xFFFFAF25);
  static const Color dashboardRed = Color(0xFFFF5A5F);
  static const Color dashboardPurple = Color(0xFF8D4CF6);
  static const Color dashboardMuted = Color(0xFF5673A2);
  static const Color dashboardPanel = Color(0xFFFFFFFF);
  static const Color dashboardLine = Color(0xFFDCEBFA);

  // Typography - Inter font family
  static const String fontFamily = 'Inter';

  // Text Styles
  static const TextStyle heroTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 80,
    fontWeight: FontWeight.w900,
    color: primaryNavy,
    height: 1.1,
    letterSpacing: -2.5,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: primaryNavy,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: primaryNavy,
    height: 1.4,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: textDark,
    height: 1.6,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textDark,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // Spacing
  static const double spacingXS = 8.0;
  static const double spacingS = 16.0;
  static const double spacingM = 24.0;
  static const double spacingL = 32.0;
  static const double spacingXL = 48.0;
  static const double spacingXXL = 64.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: secondaryBlue.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: primaryNavy.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadowHover => [
    BoxShadow(
      color: secondaryBlue.withValues(alpha: 0.15),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: primaryNavy.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: secondaryBlue.withValues(alpha: 0.3),
      blurRadius: 40,
      offset: const Offset(0, 0),
      spreadRadius: 5,
    ),
  ];

  // Material Theme Data
  ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: secondaryBlue,
        surface: white,
        surfaceContainer: backgroundLight,
      ),
      scaffoldBackgroundColor: white,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: heroTitle,
          displayMedium: heading1,
          displaySmall: heading2,
          headlineMedium: heading3,
          bodyLarge: bodyLarge,
          bodyMedium: bodyRegular,
          bodySmall: bodySmall,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryBlue,
          side: const BorderSide(color: secondaryBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
      ),
    );
  }
}
