import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/elder_colors.dart';

/// App-wide ThemeData for ElderConnect.
/// Light mode only — no dark mode.
class AppTheme {
  AppTheme._();

  /// High-contrast variant: bolder text, black-on-white, increased font sizes.
  static ThemeData get highContrast {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      textTheme: GoogleFonts.lexendTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
      dividerColor: Colors.black,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ElderColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ElderColors.primary,
        surface: ElderColors.surface,
        onSurface: ElderColors.onSurface,
      ),
      textTheme: GoogleFonts.lexendTextTheme(base.textTheme).copyWith(
        // Body text — 18sp default
        bodyLarge: GoogleFonts.lexend(
          fontSize: 18,
          color: ElderColors.onSurface,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 16,
          color: ElderColors.onSurface,
        ),
        // Heading — 24sp minimum
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ElderColors.onSurface,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ElderColors.onSurface,
        ),
        labelLarge: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ElderColors.surfaceContainerLowest,
        ),
      ),
      dividerColor: ElderColors.outlineVariant,
      cardTheme: CardThemeData(
        color: ElderColors.surfaceContainerLowest,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ElderColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ElderColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ElderColors.outlineVariant),
        ),
        labelStyle: GoogleFonts.lexend(
          fontSize: 16,
          color: ElderColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
