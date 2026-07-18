// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Static light constants (used in const contexts / gradients) ───────────────
class AppColors {
  static const primary     = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const background  = Color(0xFFF4F7FD);
  static const surface     = Colors.white;
  static const textDark    = Color(0xFF0F172A);
  static const textGrey    = Color(0xFF64748B);
  static const textLight   = Color(0xFF94A3B8);
  static const red         = Color(0xFFFF4757);
  static const star        = Color(0xFFF59E0B);
  static const green       = Color(0xFF22C55E);
  static const divider     = Color(0xFFF0F4F8);
}

// ── Dynamic colour token set (resolved at runtime) ────────────────────────────
class AppColorSet {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textDark;
  final Color textGrey;
  final Color textLight;
  final Color divider;
  final Color iconBg;
  final Color cardShadow;
  final Color primary;
  final Color red;
  final Color star;
  final Color green;

  const AppColorSet({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textDark,
    required this.textGrey,
    required this.textLight,
    required this.divider,
    required this.iconBg,
    required this.cardShadow,
    required this.primary,
    required this.red,
    required this.star,
    required this.green,
  });

  static const light = AppColorSet(
    background:     Color(0xFFF4F7FD),
    surface:        Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF4F7FD),
    textDark:       Color(0xFF0F172A),
    textGrey:       Color(0xFF64748B),
    textLight:      Color(0xFF94A3B8),
    divider:        Color(0xFFF0F4F8),
    iconBg:         Color(0xFFF4F7FD),
    cardShadow:     Color(0x12000000),
    primary:        Color(0xFF2563EB),
    red:            Color(0xFFFF4757),
    star:           Color(0xFFF59E0B),
    green:          Color(0xFF22C55E),
  );

  static const dark = AppColorSet(
    background:     Color(0xFF0F172A),
    surface:        Color(0xFF1E293B),
    surfaceVariant: Color(0xFF273548),
    textDark:       Color(0xFFF1F5F9),
    textGrey:       Color(0xFF94A3B8),
    textLight:      Color(0xFF64748B),
    divider:        Color(0xFF1E293B),
    iconBg:         Color(0xFF273548),
    cardShadow:     Color(0x4D000000),
    primary:        Color(0xFF3B82F6),
    red:            Color(0xFFFF4757),
    star:           Color(0xFFF59E0B),
    green:          Color(0xFF22C55E),
  );
}

// ── Convenience extension ─────────────────────────────────────────────────────
extension AppColorsContext on BuildContext {
  AppColorSet get colors =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColorSet.dark
          : AppColorSet.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ── Theme builders ────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColorSet.light.background,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorSet.light.background,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorSet.dark.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColorSet.dark.background,
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorSet.dark.background,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
