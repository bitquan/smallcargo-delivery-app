import 'package:flutter/material.dart';

/// Enhanced design system for Small Cargo Delivery App
class AppDesignSystem {
  // Enhanced Color Palette
  static const Color primaryGold = Color(0xFFFFEB3B);
  static const Color primaryGoldDark = Color(0xFFFBC02D);
  static const Color primaryGoldLight = Color(0xFFFFF176);
  
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color backgroundCard = Color(0xFF161B22);
  static const Color backgroundSurface = Color(0xFF21262D);
  
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFFB1BAC4);
  static const Color textMuted = Color(0xFF8B949E);
  
  static const Color accentBlue = Color(0xFF58A6FF);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentRed = Color(0xFFF85149);
  static const Color accentOrange = Color(0xFFDB6D28);
  static const Color accentPurple = Color(0xFFA5A5FF);
  
  // Status Colors
  static const Color statusSuccess = Color(0xFF28A745);
  static const Color statusWarning = Color(0xFFFFC107);
  static const Color statusError = Color(0xFFDC3545);
  static const Color statusInfo = Color(0xFF17A2B8);
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGold, primaryGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundCard, backgroundSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryGold, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Typography System
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.25,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.3,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );
  
  // Spacing System
  static const double spacing2xs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacing2xl = 24.0;
  static const double spacing3xl = 32.0;
  static const double spacing4xl = 48.0;
  static const double spacing5xl = 64.0;
  
  // Border Radius System
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;
  static const double radius3xl = 24.0;
  static const double radiusFull = 9999.0;
  
  // Shadow System
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
  );
  
  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 4),
    blurRadius: 6,
    spreadRadius: -1,
  );
  
  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 10),
    blurRadius: 15,
    spreadRadius: -3,
  );
  
  static const BoxShadow shadowXl = BoxShadow(
    color: Color(0x25000000),
    offset: Offset(0, 20),
    blurRadius: 25,
    spreadRadius: -5,
  );
  
  // Glow effects for primary elements
  static const BoxShadow glowPrimary = BoxShadow(
    color: Color(0x40FFEB3B),
    offset: Offset(0, 0),
    blurRadius: 20,
    spreadRadius: 0,
  );
  
  static const BoxShadow glowAccent = BoxShadow(
    color: Color(0x4058A6FF),
    offset: Offset(0, 0),
    blurRadius: 15,
    spreadRadius: 0,
  );
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Component Styles
  static BoxDecoration primaryCardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(
      color: primaryGold.withValues(alpha: 0.2),
      width: 1,
    ),
    boxShadow: const [shadowMd, glowPrimary],
  );
  
  static BoxDecoration heroCardDecoration = BoxDecoration(
    gradient: heroGradient,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: const [shadowLg, glowPrimary],
  );
  
  static BoxDecoration surfaceCardDecoration = BoxDecoration(
    color: backgroundCard,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(
      color: textMuted.withValues(alpha: 0.2),
      width: 1,
    ),
    boxShadow: const [shadowSm],
  );
  
  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryGold,
    foregroundColor: backgroundDark,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXl,
      vertical: spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    elevation: 0,
    textStyle: labelLarge,
  );
  
  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryGold,
    side: const BorderSide(color: primaryGold, width: 1),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXl,
      vertical: spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    textStyle: labelLarge,
  );
  
  // Input Decoration
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: bodyMedium,
      prefixIcon: icon != null ? Icon(icon, color: textSecondary) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: textMuted),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: textMuted.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryGold, width: 2),
      ),
      filled: true,
      fillColor: backgroundSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingLg,
        vertical: spacingMd,
      ),
    );
  }
}
