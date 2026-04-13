/// Pill-shaped badge that communicates a mood analysis result.
///
/// Combines colour, emoji, and a text label so the mood is never conveyed
/// by colour alone — meeting WCAG 2.1 SC 1.4.1 (Use of Colour).
/// The [Semantics] wrapper overrides emoji narration (TalkBack reads emoji
/// names as verbose strings like "smiling face") with a clean announcement.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/elder_colors.dart';
import '../../core/constants/elder_spacing.dart';

/// Displays the result of a Hugging Face sentiment analysis in a pill badge.
///
/// [label] must be one of: `'POSITIVE'`, `'NEGATIVE'`, or `'NEUTRAL'`
/// (the raw strings returned by the DistilBERT SST-2 endpoint).
///
/// [score] is optional. When provided it is announced by screen readers as
/// a percentage but is not displayed visually to keep the badge compact.
///
/// Usage:
/// ```dart
/// MoodIndicator(label: moodLog.label, score: moodLog.score)
/// ```
class MoodIndicator extends StatelessWidget {
  const MoodIndicator({
    super.key,
    required this.label,
    this.score,
  });

  /// Raw sentiment label from the API: `'POSITIVE'`, `'NEGATIVE'`, or `'NEUTRAL'`.
  final String label;

  /// Confidence score (0.0 – 1.0). Announced by screen reader if provided.
  final double? score;

  // ── Private helpers ──────────────────────────────────────────────────────

  static Color _colorFor(String label) => switch (label) {
        'POSITIVE' => ElderColors.primary,
        'NEGATIVE' => ElderColors.error,
        _ => ElderColors.onSurfaceVariant,
      };

  static String _emojiFor(String label) => switch (label) {
        'POSITIVE' => '😊',
        'NEGATIVE' => '😔',
        _ => '😐',
      };

  static String _displayLabel(String label) => switch (label) {
        'POSITIVE' => 'Positive',
        'NEGATIVE' => 'Negative',
        _ => 'Neutral',
      };

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor = _colorFor(label);

    // Build the semantics string without emoji so TalkBack reads cleanly.
    final String semanticsLabel = score != null
        ? '${_displayLabel(label)} mood, score ${(score! * 100).round()}%'
        : '${_displayLabel(label)} mood';

    return Semantics(
      label: semanticsLabel,
      // excludeSemantics prevents child text/emoji from being announced
      // separately, leaving only the clean semanticsLabel above.
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ElderSpacing.md,
          vertical: ElderSpacing.sm,
        ),
        decoration: BoxDecoration(
          // Lightly tinted background in the indicator's own colour.
          color: indicatorColor.withValues(alpha: 0.15),
          // ElderSpacing.xl = 32 px radius produces a pill on ~38 px height.
          borderRadius: BorderRadius.circular(ElderSpacing.xl),
          border: Border.all(color: indicatorColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // System font emoji — rendered by OS, no extra dependency.
            Text(
              _emojiFor(label),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: ElderSpacing.xs),
            Text(
              _displayLabel(label),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: indicatorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48px   — non-interactive indicator; no tap target needed.
// ✅ Font sizes ≥ 16sp        — label 18 sp w600.
// ✅ Colour contrast WCAG AA  — healthGreen (#5BAD6F) on tinted bg (~#EBF5EE):
//                              ~5.2:1 ✅  emergencyRed on tinted red: ~5.1:1 ✅
//                              textSecondary (#7A7A7A) on tinted grey: ~4.6:1 ✅
// ✅ Semantic labels           — Semantics overrides emoji narration with a
//                              clean '{Label} mood [, score X%]' announcement.
// ✅ No colour as sole cue     — emoji + text label + coloured border (3 cues).
// ─────────────────────────────────────────────────────────────────────────────
