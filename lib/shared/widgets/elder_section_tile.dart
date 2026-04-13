/// Home-screen navigation tile for the ElderConnect elderly portal.
///
/// Renders a 140 × 140 px coloured tile with a large icon and bold label.
/// A subtle scale-down animation on press provides tactile feedback without
/// relying on the InkWell ripple, which is invisible against coloured surfaces.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/elder_colors.dart';
import '../../core/constants/elder_spacing.dart';

/// Section navigation tile for the elderly portal's icon-grid home screen.
///
/// The [color] parameter must always be an [ElderColors] constant so that
/// contrast ratios are guaranteed by the design system.
///
/// Usage:
/// ```dart
/// ElderSectionTile(
///   label: 'Social',
///   icon: Icons.people_alt_rounded,
///   color: ElderColors.socialBlue,
///   onTap: () => context.go('/social'),
/// )
/// ```
class ElderSectionTile extends StatefulWidget {
  const ElderSectionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  /// Section name shown below the icon. Rendered at 18 sp bold, max 2 lines.
  final String label;

  /// Icon rendered at 48 px inside the tile.
  final IconData icon;

  /// Tile background colour. Must be an [ElderColors] constant.
  final Color color;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  State<ElderSectionTile> createState() => _ElderSectionTileState();
}

class _ElderSectionTileState extends State<ElderSectionTile> {
  // Local UI state only — not business logic. setState is acceptable here.
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.95);
  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        // 150 ms is well under the 300 ms animation maximum.
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Semantics(
          button: true,
          label: widget.label,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // Shadow colour derived from the tile colour — stays
                  // thematically consistent without a hardcoded hex.
                  color: widget.color.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 48,
                  color: ElderColors.onPrimary,
                ),
                const SizedBox(height: ElderSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ElderSpacing.sm,
                  ),
                  child: Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48px   — Container is fixed 140 × 140 px.
// ✅ Font sizes ≥ 16sp        — label 18 sp bold.
// ✅ Colour contrast WCAG AA  — cardWhite (#FFF) on tile colours (large text,
//                              18 sp bold → WCAG "large text" threshold):
//                              socialBlue  3.8:1 ✅  newsOrange  3.1:1 ✅
//                              healthGreen 3.7:1 ✅  emergencyRed 4.5:1 ✅
// ✅ Semantic labels           — Semantics(button:true, label: label).
// ✅ No colour as sole cue     — icon + text label present for every tile.
// ✅ Animation ≤ 300 ms        — scale animation is 150 ms.
// ─────────────────────────────────────────────────────────────────────────────
