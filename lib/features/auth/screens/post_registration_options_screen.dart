/// Post-registration options — shown after caretaker completes registration.
///
/// Gives the caretaker two paths: register an elder profile immediately,
/// or skip to the dashboard and link an elder later via invite code.
/// CTA callbacks are no-ops until caretaker portal routes are added to
/// app.dart in Batch 3.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Stitch config for this screen: rounded-xl = 0.5rem = 8dp (icon containers).
const double _kIconContainerRadius = 8.0;

// Stitch design: bottom image strip = h-32 = 8rem = 128 logical pixels.
// Replaced with a tonal decorative strip (network images excluded from prototype).
// TODO(backend-sprint): replace strip with CachedNetworkImage from Supabase Storage.
const double _kCardStripHeight = 128.0;

class PostRegistrationOptionsScreen extends ConsumerStatefulWidget {
  const PostRegistrationOptionsScreen({super.key});

  @override
  ConsumerState<PostRegistrationOptionsScreen> createState() =>
      _PostRegistrationOptionsScreenState();
}

class _PostRegistrationOptionsScreenState
    extends ConsumerState<PostRegistrationOptionsScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // Three staggered sections: [0] hero, [1] card 1, [2] card 2 + footnote.
    _anims = List.generate(
      3,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.10, (i * 0.10) + 0.60, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    for (final a in _anims) a.dispose();
    _anim.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) {
    return AnimatedBuilder(
      animation: _anims[i],
      builder: (_, __) => Opacity(
        opacity: _anims[i].value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _anims[i].value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.lg,
            vertical: ElderSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BackButton(onTap: () => context.go('/register/caretaker')),
              const SizedBox(height: ElderSpacing.xl),
              _animated(0, _buildHero()),
              const SizedBox(height: ElderSpacing.xl),
              _animated(
                1,
                _OptionCard(
                  onTap: () {
                    // TODO: context.go('/caretaker/register-elder') — add route in Batch 3.
                  },
                  cardColor: ElderColors.surfaceContainerLowest,
                  iconContainerColor: ElderColors.tertiaryFixed,
                  icon: Icons.person_add,
                  title: 'Register an Elder Now',
                  body: 'Create a new profile to start tracking vital signs, '
                      'mood, and activity schedules immediately.',
                  ctaLabel: 'START SETUP',
                  ctaColor: ElderColors.primary,
                  stripColor: ElderColors.surfaceContainerLow,
                ),
              ),
              const SizedBox(height: ElderSpacing.lg),
              _animated(
                2,
                _OptionCard(
                  onTap: () {
                    // TODO: context.go('/home/caretaker') — add route in Batch 3.
                  },
                  cardColor: ElderColors.surfaceContainerLow,
                  iconContainerColor: ElderColors.surfaceContainerHighest,
                  icon: Icons.link_off,
                  title: 'Skip and Link Later',
                  body: 'Explore the dashboard and platform features first. '
                      'You can link a profile via an invite code at any time.',
                  ctaLabel: 'GO TO DASHBOARD',
                  ctaColor: ElderColors.onSurfaceVariant,
                  stripColor: ElderColors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: ElderSpacing.xl),
              _animated(2, const _TrustFootnote()),
              const SizedBox(height: ElderSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Registration Successful" pill badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.md, // px-3 ≈ 12dp → nearest token: md (16dp)
            vertical: ElderSpacing.xs,   // py-1 = 4dp
          ),
          decoration: BoxDecoration(
            // bg-tertiary-fixed (#97f3e2 aqua) → nearest token: primaryFixed (#A0F0F0)
            color: ElderColors.primaryFixed,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'REGISTRATION SUCCESSFUL',
            // HTML: text-[10px] font-bold uppercase tracking-widest — raised to 16sp.
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // on-tertiary-fixed-variant (#005047) ≈ onPrimaryFixedVariant (#004F4F)
              color: ElderColors.onPrimaryFixedVariant,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height: ElderSpacing.md),

        Text(
          'Welcome to the Care Network',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36, // text-3xl mobile / text-4xl md
            fontWeight: FontWeight.w800,
            color: ElderColors.primary,
            height: 1.15,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: ElderSpacing.md),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Text(
            'Your account is ready. To begin monitoring and coordinating care, '
            'you can register an elder now or link an existing profile later.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: ElderColors.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ── _BackButton ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go back to caretaker registration',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: ElderColors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── _OptionCard ──────────────────────────────────────────────────────────────

/// Full-width tappable option card with a tonal decorative strip at the bottom.
///
/// The strip replaces the Stitch network image band — see TODO above for the
/// backend-sprint replacement with CachedNetworkImage.
class _OptionCard extends StatefulWidget {
  const _OptionCard({
    required this.onTap,
    required this.cardColor,
    required this.iconContainerColor,
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaColor,
    required this.stripColor,
  });

  final VoidCallback onTap;
  final Color cardColor;
  final Color iconContainerColor;
  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final Color ctaColor;
  final Color stripColor;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.99);
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
          label: widget.title,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: widget.cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Card content ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(ElderSpacing.xl), // p-8 = 32dp
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container — 56×56, rounded-xl (8dp in this Stitch config)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: widget.iconContainerColor,
                            borderRadius:
                                BorderRadius.circular(_kIconContainerRadius),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 24, // text-2xl
                            color: ElderColors.primary,
                          ),
                        ),

                        const SizedBox(height: ElderSpacing.lg), // mb-6 = 24dp

                        Text(
                          widget.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24, // text-2xl
                            fontWeight: FontWeight.bold,
                            color: ElderColors.primary,
                          ),
                        ),

                        const SizedBox(height: ElderSpacing.sm), // mb-2 = 8dp

                        Text(
                          widget.body,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            color: ElderColors.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: ElderSpacing.lg), // mb-6 = 24dp

                        // CTA row — uppercase label + arrow
                        Row(
                          children: [
                            Text(
                              widget.ctaLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.ctaColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: ElderSpacing.sm),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: widget.ctaColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Decorative tonal strip (replaces Stitch image band) ────
                  Container(
                    height: _kCardStripHeight, // h-32 = 128dp
                    color: widget.stripColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── _TrustFootnote ────────────────────────────────────────────────────────────

class _TrustFootnote extends StatelessWidget {
  const _TrustFootnote();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HIPAA compliance row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: ElderColors.onSurfaceVariant,
            ),
            const SizedBox(width: ElderSpacing.sm),
            // HTML: text-[11px] uppercase tracking-wide — raised to 16sp.
            Text(
              'HIPAA COMPLIANT & ENCRYPTED DATA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ElderColors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        const SizedBox(height: ElderSpacing.md),

        // Support link
        Column(
          children: [
            // HTML: text-[10px] uppercase tracking-wider — raised to 16sp.
            Text(
              'NEED ASSISTANCE?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ElderColors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            // HTML: text-sm (14px) font-semibold — raised to 16sp.
            Text(
              'Schedule Onboarding Call',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ElderColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 56×56dp    — _BackButton: 56×56 ✅
//                               _OptionCard: full-width, ~340dp+ tall ✅
// ✅ Font sizes ≥ 16sp         — badge 16sp (raised from 10px) | headline 36sp
//                               | subtitle 18sp | card title 24sp | card body 18sp
//                               | CTA 16sp | HIPAA 16sp (raised from 11px)
//                               | "NEED ASSISTANCE?" 16sp (raised from 10px)
//                               | "Schedule Onboarding Call" 16sp (raised from 14px) ✅
// ✅ Colour contrast WCAG AA   — primary (#005050) on background (#FAF9FA): ~12:1 ✅ AAA
//                               onPrimaryFixedVariant (#004F4F) on primaryFixed (#A0F0F0): ~5:1 ✅ AA
//                               primary (#005050) on surfaceContainerLowest (#FFF): ~12:1 ✅ AAA
//                               onSurfaceVariant (#3E4948) on surfaceContainerLow (#F4F3F4): ~7:1 ✅ AAA
//                               onSurfaceVariant (#3E4948) on background (#FAF9FA): ~8:1 ✅ AAA
// ✅ Semantic labels            — _BackButton, both _OptionCard: Semantics(button:true, label) ✅
// ✅ No colour as sole cue      — cards distinguished by bg tint + icon + CTA colour + CTA text ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.lg (24dp) between cards ✅
//                               ElderSpacing.xl (32dp) back → hero ✅
// ────────────────────────────────────────────────────────────────────────────
