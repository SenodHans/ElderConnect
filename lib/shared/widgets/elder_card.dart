/// A generic surface container used throughout ElderConnect.
///
/// Provides the project-standard card appearance: warm-white background,
/// 16 px rounded corners, and a soft shadow — all derived from design tokens.
/// Optionally tappable via [onTap]; the ripple effect clips correctly to the
/// card's border radius.
library;

import 'package:flutter/material.dart';
import '../../core/constants/elder_colors.dart';
import '../../core/constants/elder_spacing.dart';

/// Reusable card container that enforces ElderConnect surface styling.
///
/// Usage — static card:
/// ```dart
/// ElderCard(child: Text('Hello'))
/// ```
///
/// Usage — tappable card:
/// ```dart
/// ElderCard(onTap: () => _doSomething(), child: Text('Tap me'))
/// ```
class ElderCard extends StatelessWidget {
  const ElderCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  /// Content rendered inside the card.
  final Widget child;

  /// Inner padding. Defaults to [ElderSpacing.md] on all sides.
  final EdgeInsetsGeometry? padding;

  /// If non-null, the card becomes tappable with an ink ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? const EdgeInsets.all(ElderSpacing.md);

    // The Container provides shadow + shape. Material + InkWell are inserted
    // only when the card is tappable so the ripple clips to the border radius.
    return Container(
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurfaceVariant.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ClipRRect ensures the ink ripple never leaks outside the card shape.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: ElderColors.outlineVariant,
                  highlightColor: ElderColors.outlineVariant.withValues(alpha: 0.5),
                  child: Padding(
                    padding: effectivePadding,
                    child: child,
                  ),
                ),
              )
            : Padding(
                padding: effectivePadding,
                child: child,
              ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48px   — tappable variant: child content sets height;
//                              callers must ensure ≥ 48 px content height.
// ✅ Font sizes ≥ 16sp        — delegated to child widget.
// ✅ Colour contrast WCAG AA  — cardWhite surface; text contrast delegated
//                              to child widget.
// ✅ Semantic labels           — delegated to child and onTap call site.
// ✅ No colour as sole cue     — container only; not applicable.
// ✅ Touch targets separated   — enforced at call site by callers.
// ─────────────────────────────────────────────────────────────────────────────
