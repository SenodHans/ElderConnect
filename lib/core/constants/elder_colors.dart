import 'package:flutter/material.dart';

/// ElderConnect colour tokens.
/// Source: Stitch project "ElderConnect - Design Finalised" (projects/8009688606630486881).
/// Never use hardcoded hex values anywhere in the app — always reference this class.
class ElderColors {
  ElderColors._();

  // ── Primary — Deep Teal ───────────────────────────────────────────────────
  /// Main CTAs, key interactive elements
  static const Color primary = Color(0xFF005050);

  /// CTA gradient end, tinted containers
  static const Color primaryContainer = Color(0xFF006A6A);

  /// "Big Action" tile backgrounds
  static const Color primaryFixed = Color(0xFFA0F0F0);
  static const Color primaryFixedDim = Color(0xFF84D4D3);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text/icons on primaryContainer
  static const Color onPrimaryContainer = Color(0xFF97E7E6);
  static const Color onPrimaryFixed = Color(0xFF002020);
  static const Color onPrimaryFixedVariant = Color(0xFF004F4F);
  static const Color inversePrimary = Color(0xFF84D4D3);

  // ── Secondary — Warm Amber (Human / Connection) ───────────────────────────
  /// Human-connection elements — call family, caretaker
  static const Color secondary = Color(0xFF8E4E00);

  /// Secondary buttons — warm, visible
  static const Color secondaryContainer = Color(0xFFFDA54F);
  static const Color secondaryFixed = Color(0xFFFFDCC1);
  static const Color secondaryFixedDim = Color(0xFFFFB778);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF6F3C00);
  static const Color onSecondaryFixed = Color(0xFF2E1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6C3A00);

  // ── Tertiary — Ocean Blue (Progress / Status) ─────────────────────────────
  /// Status rings, daily progress indicators, caretaker portal accent
  static const Color tertiary = Color(0xFF004B74);
  static const Color tertiaryContainer = Color(0xFF0E6496);
  static const Color tertiaryFixed = Color(0xFFCCE5FF);
  static const Color tertiaryFixedDim = Color(0xFF93CCFF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFBBDDFF);
  static const Color onTertiaryFixed = Color(0xFF001D31);
  static const Color onTertiaryFixedVariant = Color(0xFF004B73);

  // ── Surface Hierarchy ─────────────────────────────────────────────────────
  /// Elevated focus — primary interactive cards
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Subtle recess — secondary content areas
  static const Color surfaceContainerLow = Color(0xFFF4F3F4);

  /// Base layer — app background
  static const Color surface = Color(0xFFFAF9FA);
  static const Color surfaceBright = Color(0xFFFAF9FA);
  static const Color background = Color(0xFFFAF9FA);

  /// Mid-level containers
  static const Color surfaceContainer = Color(0xFFEEEEEE);

  /// Deep context — nav bars, persistent footers
  static const Color surfaceContainerHigh = Color(0xFFE8E8E9);

  /// Input field "well" backgrounds
  static const Color surfaceContainerHighest = Color(0xFFE3E2E3);

  /// Dimmed / disabled surfaces
  static const Color surfaceDim = Color(0xFFDADADB);
  static const Color surfaceVariant = Color(0xFFE3E2E3);
  static const Color surfaceTint = Color(0xFF006A6A);

  // ── Text & Icons ──────────────────────────────────────────────────────────
  /// Primary text — all body copy
  static const Color onSurface = Color(0xFF1A1C1D);
  static const Color onBackground = Color(0xFF1A1C1D);

  /// Secondary text, captions
  static const Color onSurfaceVariant = Color(0xFF3E4948);

  /// Subtle dividers — use sparingly, see No-Line Rule in design.md
  static const Color outline = Color(0xFF6E7979);

  /// Ghost borders — use at 15% opacity only
  static const Color outlineVariant = Color(0xFFBEC9C8);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F0F1);

  // ── Error States ──────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);

  /// Error background — fade in slowly, never shake
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
}
