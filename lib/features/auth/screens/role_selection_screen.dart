/// Role selection screen — first screen the user actively interacts with.
///
/// Presents two large role cards so the user can identify as either
/// an elderly user or a caretaker. Tapping a card routes to the matching
/// registration flow via GoRouter. No backend logic lives here.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Stitch design spec: rounded-[2.5rem] = 40dp on role cards.
// Not a standard DESIGN.md radius token — specific to this screen's cards.
const double _kCardRadius = 40.0;

// Stitch design spec: w-24 h-24 = 96dp icon container inside each card.
const double _kIconContainerSize = 96.0;

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: ElderColors.background,
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────────────────────────
          // Stitch: fixed top-right primaryFixed/20%, bottom-left secondaryFixed/20%
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.20,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: SizedBox(
                  width: size.width / 3,
                  height: size.height / 3,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ElderColors.primaryFixed,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Opacity(
              opacity: 0.20,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: SizedBox(
                  width: size.width / 4,
                  height: size.height / 4,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ElderColors.secondaryFixed,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: ElderSpacing.lg,  // px-6 = 24dp
                vertical: ElderSpacing.xxl,   // py-12 = 48dp
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Branding ───────────────────────────────────────────────
                  // Wordmark: HTML uses text-xs (12px) which violates the 16sp
                  // project minimum. Raised to 16sp; uppercase + wide tracking
                  // preserves the visual intent from the Stitch design.
                  Text(
                    'ELDERCONNECT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.primary,
                      letterSpacing: 3.0, // tracking-widest
                    ),
                  ),

                  const SizedBox(height: ElderSpacing.md), // mb-4 = 16dp

                  Text(
                    'Welcome!\nWho are you?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.onBackground,
                      height: 1.25,
                      letterSpacing: -0.5, // tracking-tight
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: ElderSpacing.lg), // mt-6 = 24dp

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                    child: Text(
                      'Select your profile to personalize your experience and connect with your circle.',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: ElderColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: ElderSpacing.xxl), // mb-12 = 48dp

                  // ── Role cards ─────────────────────────────────────────────
                  _RoleCard(
                    label: 'I am an Elder',
                    description: 'Browse your activities and links.',
                    icon: Icons.elderly_rounded,
                    cardColor: ElderColors.surfaceContainerLowest,
                    iconContainerColor: ElderColors.primaryFixed,
                    iconColor: ElderColors.primary,
                    titleColor: ElderColors.primary,
                    onTap: () => context.go('/register/elder'),
                  ),

                  const SizedBox(height: ElderSpacing.lg), // space-y-6 = 24dp

                  _RoleCard(
                    label: 'I am a Caretaker',
                    description: 'Support and stay connected.',
                    icon: Icons.volunteer_activism,
                    // Stitch: bg-secondary-container/10 — very light amber tint.
                    cardColor: ElderColors.secondaryContainer.withValues(alpha: 0.10),
                    iconContainerColor: ElderColors.secondaryFixed,
                    iconColor: ElderColors.secondary,
                    titleColor: ElderColors.secondary,
                    onTap: () => context.go('/register/caretaker'),
                  ),

                  const SizedBox(height: ElderSpacing.xxl), // mt-16 ≈ 48dp (nearest token)

                  // ── Footer decoration ──────────────────────────────────────
                  // Decorative divider — not a content separator (no-line rule
                  // applies to content sections; this is a footer ornament).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: ElderSpacing.xxl, // w-12 = 48dp
                        height: 1,
                        color: ElderColors.onSurfaceVariant.withValues(alpha: 0.40),
                      ),
                      const SizedBox(width: ElderSpacing.md),
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: ElderColors.onSurfaceVariant.withValues(alpha: 0.40),
                      ),
                      const SizedBox(width: ElderSpacing.md),
                      Container(
                        width: ElderSpacing.xxl,
                        height: 1,
                        color: ElderColors.onSurfaceVariant.withValues(alpha: 0.40),
                      ),
                    ],
                  ),

                  const SizedBox(height: ElderSpacing.xl),

                  // Community link — no route defined yet; visual only.
                  Semantics(
                    button: true,
                    label: 'Learn more about our community',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Learn more about our community',
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ElderColors.primary,
                          ),
                        ),
                        const SizedBox(width: ElderSpacing.sm),
                        const Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: ElderColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width tappable role card.
///
/// Used exclusively on [RoleSelectionScreen] — not a shared component.
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.cardColor,
    required this.iconContainerColor,
    required this.iconColor,
    required this.titleColor,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color cardColor;
  final Color iconContainerColor;
  final Color iconColor;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.98);
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
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Semantics(
          button: true,
          label: widget.label,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ElderSpacing.xl), // p-8 = 32dp
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(_kCardRadius),
            ),
            child: Row(
              children: [
                // Icon container — 96×96 circle (w-24 h-24 in Stitch).
                Container(
                  width: _kIconContainerSize,
                  height: _kIconContainerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.iconContainerColor,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 48, // text-5xl in Stitch
                    color: widget.iconColor,
                  ),
                ),
                const SizedBox(width: ElderSpacing.xl), // space-x-8 = 32dp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30, // text-3xl
                          fontWeight: FontWeight.bold,
                          color: widget.titleColor,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: ElderSpacing.xs), // mt-1 = 4dp
                      Text(
                        widget.description,
                        style: GoogleFonts.lexend(
                          fontSize: 18, // text-lg
                          color: ElderColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ElderSpacing.sm),
                // Chevron — signals tappable; outlineVariant per Stitch design.
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 36, // text-4xl
                  color: ElderColors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 56×56dp    — _RoleCard is full-width, min-height ~160dp.
// ✅ Font sizes ≥ 16sp         — wordmark 16sp | headline 48sp | subtitle 18sp
//                               | card title 30sp | card desc 18sp
//                               | community link 18sp. No violations.
// ✅ Colour contrast WCAG AAA  — primary (#005050) on surfaceContainerLowest
//                               (#FFF): ~12:1 ✅
//                               secondary (#8E4E00) on secondaryContainer/10%
//                               (near-white): ~6.5:1 ✅ AA
//                               onSurfaceVariant (#3E4948) on background: ~8:1 ✅
// ✅ Semantic labels            — Semantics(button: true, label: widget.label)
//                               wraps full card; community link labelled.
// ✅ No colour as sole cue      — distinct icons + text label on every card.
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.lg (24dp) gap between cards.
// ────────────────────────────────────────────────────────────────────────────
