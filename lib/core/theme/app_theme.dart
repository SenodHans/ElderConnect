import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/elder_colors.dart';

/// App-wide ThemeData for ElderConnect.
/// Light mode only — no dark mode.
/// Font pairing: Plus Jakarta Sans (display/headlines) + Lexend (body/titles/labels).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ElderColors.surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ElderColors.primary,
        onPrimary: ElderColors.onPrimary,
        primaryContainer: ElderColors.primaryContainer,
        onPrimaryContainer: ElderColors.onPrimaryContainer,
        secondary: ElderColors.secondary,
        onSecondary: ElderColors.onSecondary,
        secondaryContainer: ElderColors.secondaryContainer,
        onSecondaryContainer: ElderColors.onSecondaryContainer,
        tertiary: ElderColors.tertiary,
        onTertiary: ElderColors.onTertiary,
        tertiaryContainer: ElderColors.tertiaryContainer,
        onTertiaryContainer: ElderColors.onTertiaryContainer,
        error: ElderColors.error,
        onError: ElderColors.onError,
        errorContainer: ElderColors.errorContainer,
        onErrorContainer: ElderColors.onErrorContainer,
        surface: ElderColors.surface,
        onSurface: ElderColors.onSurface,
        onSurfaceVariant: ElderColors.onSurfaceVariant,
        outline: ElderColors.outline,
        outlineVariant: ElderColors.outlineVariant,
        inverseSurface: ElderColors.inverseSurface,
        onInverseSurface: ElderColors.inverseOnSurface,
        inversePrimary: ElderColors.inversePrimary,
        surfaceTint: ElderColors.surfaceTint,
      ),
      textTheme: TextTheme(
        // ── Display — Plus Jakarta Sans ──────────────────────────────────
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: ElderColors.onSurface,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: ElderColors.onSurface,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: ElderColors.onSurface,
          height: 1.2,
        ),
        // ── Headlines — Plus Jakarta Sans ────────────────────────────────
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: ElderColors.onSurface,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: ElderColors.onSurface,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ElderColors.onSurface,
          height: 1.35,
        ),
        // ── Titles — Lexend ──────────────────────────────────────────────
        titleLarge: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: ElderColors.onSurface,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ElderColors.onSurface,
          height: 1.45,
        ),
        titleSmall: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ElderColors.onSurface,
          height: 1.5,
        ),
        // ── Body — Lexend ────────────────────────────────────────────────
        bodyLarge: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: ElderColors.onSurface,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: ElderColors.onSurface,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: ElderColors.onSurfaceVariant,
          height: 1.4,
        ),
        // ── Labels — Lexend ──────────────────────────────────────────────
        labelLarge: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ElderColors.onSurface,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ElderColors.onSurface,
          height: 1.3,
        ),
        labelSmall: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ElderColors.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      dividerColor: ElderColors.outlineVariant,
      // Cards use tonal layering — elevation 0, colour shift creates the lift
      cardTheme: const CardThemeData(
        color: ElderColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: ElderColors.primary,
          foregroundColor: ElderColors.onPrimary,
          // xl radius per design.md (1.5rem = 24px)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // "Well" effect — sunken field background
        fillColor: ElderColors.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        // No border at rest — tonal background is the boundary
        border: const UnderlineInputBorder(
          borderSide: BorderSide.none,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide.none,
        ),
        // 2px primary bottom bar on focus — not a full-box stroke
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ElderColors.primary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ElderColors.error, width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ElderColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.lexend(
          fontSize: 16,
          color: ElderColors.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.lexend(
          fontSize: 16,
          color: ElderColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
