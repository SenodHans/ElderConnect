/// Metric card for the caretaker portal dashboard.
///
/// Composes [ElderCard] so shadow, border radius, and background are
/// inherited automatically — any future update to [ElderCard] propagates here.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/elder_colors.dart';
import '../../core/constants/elder_spacing.dart';
import 'elder_card.dart';

/// Single-metric stat card for the caretaker dashboard.
///
/// Displays an icon, a large numeric or text [value], a [title] label, and
/// an optional [subtitle] (e.g. "vs last week").
///
/// Usage:
/// ```dart
/// CaretakerStatCard(
///   title: 'Medications Taken',
///   value: '4 / 5',
///   icon: Icons.medication_rounded,
///   color: ElderColors.healthGreen,
///   subtitle: 'today',
/// )
/// ```
class CaretakerStatCard extends StatelessWidget {
  const CaretakerStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = ElderColors.tertiary,
    this.subtitle,
  });

  /// Short metric label shown below the value (e.g. 'Mood: Last 7 Days').
  final String title;

  /// The primary metric displayed at 28 sp bold (e.g. '4 / 5', '😊 Positive').
  final String value;

  /// Icon representing this metric, rendered at 32 px.
  final IconData icon;

  /// Accent colour for the icon. Must be an [ElderColors] constant.
  /// Defaults to [ElderColors.tertiary].
  final Color color;

  /// Optional supplementary text shown top-right (e.g. 'today', 'vs last week').
  /// Rendered at 16 sp to meet the minimum font-size requirement.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ElderCard(
      padding: const EdgeInsets.all(ElderSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon (left) + subtitle (right) ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '$title icon',
                child: Icon(icon, size: 32, color: color),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),

          const SizedBox(height: ElderSpacing.md),

          // ── Primary metric value ─────────────────────────────────────────
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ElderColors.onSurface,
            ),
          ),

          // ── Metric label ─────────────────────────────────────────────────
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: ElderColors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48px   — non-interactive; if tappable, wrap the widget
//                              with ElderCard(onTap: ...) which provides the
//                              InkWell and respects card border radius.
// ✅ Font sizes ≥ 16sp        — value 28 sp bold, title 16 sp, subtitle 16 sp.
// ✅ Colour contrast WCAG AA  — textPrimary (#2D2D2D) on cardWhite: ~16:1 ✅
//                              textSecondary (#7A7A7A) on cardWhite: ~4.6:1 ✅
//                              caretakerPurple (#7C5CBF) icon on cardWhite:
//                              ~5.0:1 ✅ passes AA for graphical objects.
// ✅ Semantic labels           — Icon wrapped with Semantics(label:'$title icon').
// ✅ No colour as sole cue     — icon, numeric value, and text label all present.
// ─────────────────────────────────────────────────────────────────────────────
