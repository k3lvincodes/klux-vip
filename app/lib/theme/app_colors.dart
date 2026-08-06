import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFEAB308);
  static const Color background = Color(0xFFEBE5E4);
  static const Color backgroundGradient = Color(0xFFFFFBEB);
  static const Color text = Color(0xFF111827);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color secondary = Color(0xFFF5F5F5);
  static const Color softYellow = Color(0xFFFEF08A);

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFF9FAFB);

  static ColorScheme lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFEAB308),
    onPrimary: Color(0xFF1A1A1A),
    primaryContainer: Color(0xFFFFF8E1),
    onPrimaryContainer: Color(0xFF1A1A1A),
    secondary: Color(0xFF6B7280),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF3F4F6),
    onSecondaryContainer: Color(0xFF111827),
    tertiary: Color(0xFF8B5CF6),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFEDE9FE),
    onTertiaryContainer: Color(0xFF1E1B4B),
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFEBE5E4),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFD1D5DB),
    outlineVariant: Color(0xFFE5E7EB),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF5F0EF),
    surfaceContainer: Color(0xFFEDE5E4),
    surfaceContainerHigh: Color(0xFFE0D8D7),
    surfaceContainerHighest: Color(0xFFD4CBCB),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Color(0xFFF9FAFB),
    surfaceTint: Color(0xFFEAB308),
    shadow: Color(0x1A000000),
  );

  static ColorScheme darkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFEAB308),
    onPrimary: Color(0xFF1A1A1A),
    primaryContainer: Color(0xFF422006),
    onPrimaryContainer: Color(0xFFFEF3C7),
    secondary: Color(0xFF9CA3AF),
    onSecondary: Color(0xFF1F2937),
    secondaryContainer: Color(0xFF374151),
    onSecondaryContainer: Color(0xFFF9FAFB),
    tertiary: Color(0xFFA78BFA),
    onTertiary: Color(0xFF1E1B4B),
    tertiaryContainer: Color(0xFF2E1065),
    onTertiaryContainer: Color(0xFFEDE9FE),
    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFF9FAFB),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF4B5563),
    outlineVariant: Color(0xFF374151),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0D0D0D),
    surfaceContainer: Color(0xFF141414),
    surfaceContainerHigh: Color(0xFF1E1E1E),
    surfaceContainerHighest: Color(0xFF282828),
    inverseSurface: Color(0xFFF3F4F6),
    onInverseSurface: Color(0xFF1F2937),
    surfaceTint: Color(0xFFEAB308),
    shadow: Color(0x33000000),
  );
}
