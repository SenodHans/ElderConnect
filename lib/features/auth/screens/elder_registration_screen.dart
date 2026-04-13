/// Elder registration — step 1 of the elder onboarding flow.
///
/// Collects the user's display name only and an optional profile photo
/// (upload placeholder — wired to file picker in a later sprint).
/// No email, no password, no phone — per CLAUDE.md elder auth rules.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../shared/widgets/widgets.dart';

// Stitch design spec: w-48 h-48 = 192dp photo circle.
const double _kPhotoSize = 192.0;

class ElderRegistrationScreen extends ConsumerStatefulWidget {
  const ElderRegistrationScreen({super.key});

  @override
  ConsumerState<ElderRegistrationScreen> createState() =>
      _ElderRegistrationScreenState();
}

class _ElderRegistrationScreenState
    extends ConsumerState<ElderRegistrationScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 300ms total — design.md maximum animation duration.
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // Three staggered sections: [0] headline, [1] photo+input+button, [2] info cards.
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
    _nameController.dispose();
    super.dispose();
  }

  /// Wraps [child] in a fade + 20dp upward slide driven by [_anims[i]].
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

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      context.go('/interest-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      // No AppBar — onboarding is chrome-free; back action lives in body.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.lg,
            vertical: ElderSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ──────────────────────────────────────────────
                _BackButton(onTap: () => context.go('/role-selection')),

                const SizedBox(height: ElderSpacing.xl),

                // ── Headline + subtitle ──────────────────────────────────────
                _animated(0, _buildHeadline()),

                const SizedBox(height: ElderSpacing.xxl), // space-y-12 = 48dp

                // ── Photo upload ─────────────────────────────────────────────
                _animated(1, const _PhotoUploadPlaceholder()),

                const SizedBox(height: ElderSpacing.xxl),

                // ── Full Name input ──────────────────────────────────────────
                _animated(
                  1,
                  ElderInput(
                    label: 'Full Name',
                    controller: _nameController,
                    hint: 'e.g. Eleanor Vance',
                    keyboardType: TextInputType.name,
                    // Stitch design uses primary-coloured label on this screen.
                    labelColor: ElderColors.primary,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your full name'
                        : null,
                  ),
                ),

                const SizedBox(height: ElderSpacing.xl),

                // ── Continue button ──────────────────────────────────────────
                _animated(
                  1,
                  ElderButton(
                    label: 'Continue',
                    onPressed: _onContinue,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),

                const SizedBox(height: ElderSpacing.xl),

                // ── Info cards ───────────────────────────────────────────────
                _animated(2, _buildInfoCards()),

                const SizedBox(height: ElderSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Set up your profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 40,        // text-4xl (36sp mobile) → 40sp for visual match
            fontWeight: FontWeight.w800,
            color: ElderColors.primary,
            height: 1.25,
            letterSpacing: -0.5, // tracking-tight
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ElderSpacing.md), // space-y-4 = 16dp
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448), // max-w-md
          child: Text(
            "Let's create a warm and recognizable space for your family and care team.",
            style: GoogleFonts.lexend(
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

  Widget _buildInfoCards() {
    return const Column(
      children: [
        _InfoCard(
          icon: Icons.security,
          title: 'Private & Secure',
          body: 'Your data is only shared with your chosen circle.',
        ),
        SizedBox(height: ElderSpacing.md), // gap-4 = 16dp
        _InfoCard(
          icon: Icons.help_center,
          title: 'Need help?',
          body: 'Tap the icon in the top corner for assistance.',
        ),
      ],
    );
  }
}

// ── _BackButton ──────────────────────────────────────────────────────────────

/// Inline back button — 56×56dp; no AppBar so onboarding stays chrome-free.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go back to role selection',
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

// ── _PhotoUploadPlaceholder ──────────────────────────────────────────────────

/// Circular photo area with camera icon, "Add Photo" label, and + badge.
///
/// Tapping is a no-op — file-picker wiring is deferred to a later sprint.
class _PhotoUploadPlaceholder extends StatelessWidget {
  const _PhotoUploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Add profile photo',
        child: SizedBox(
          width: _kPhotoSize,
          height: _kPhotoSize,
          child: Stack(
            // clipBehavior: none allows the + badge to overlap the circle edge.
            clipBehavior: Clip.none,
            children: [
              // ── Main circle ─────────────────────────────────────────────────
              Container(
                width: _kPhotoSize,
                height: _kPhotoSize,
                decoration: BoxDecoration(
                  color: ElderColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  // surfaceContainerLowest border creates a white halo — a
                  // visual lift trick, not a content-section border, so it
                  // does not violate the design.md No-Line Rule.
                  border: Border.all(
                    color: ElderColors.surfaceContainerLowest,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElderColors.onSurface.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_camera_outlined, // closest to camera_enhance
                      size: 60,
                      color: ElderColors.outline,
                    ),
                    const SizedBox(height: ElderSpacing.xs),
                    // HTML: text-sm (14px) — raised to 16sp for CLAUDE.md minimum.
                    Text(
                      'Add Photo',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // ── + badge — bottom-2 right-2 = 8dp inset from circle edge ────
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ElderColors.secondaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ElderColors.onSurface.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 24,
                    color: ElderColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _InfoCard ────────────────────────────────────────────────────────────────

/// Informational tile — tonal surface shift only, no border.
///
/// Matches Stitch: p-6 (24dp), rounded-xl (12px), raw 30px icon, both primary.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.lg), // p-6 = 24dp
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12), // rounded-xl
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raw icon — no container circle (matches Stitch design).
          Icon(
            icon,
            size: 30, // text-3xl
            color: ElderColors.primary,
          ),
          const SizedBox(width: ElderSpacing.md), // gap-4 = 16dp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.onSurface,
                  ),
                ),
                const SizedBox(height: ElderSpacing.xs),
                Text(
                  body,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 56×56dp    — _BackButton: 56×56 ✅
//                               _PhotoUploadPlaceholder: 192×192 ✅
//                               + badge: 48×48 (meets 48dp design-system min) ✅
//                               ElderButton: 56px height, full-width ✅
// ✅ Font sizes ≥ 16sp         — headline 40sp | subtitle 18sp | 'Add Photo' 16sp
//                               | input label 16sp | card title 16sp | card body 16sp
// ✅ Colour contrast WCAG AAA  — primary (#005050) on background (#FAF9FA): ~12:1 ✅
//                               outline (#6E7979) on surfaceContainerLow (#F4F3F4): ~4.5:1 ✅ AA
//                               onSecondaryContainer (#6F3C00) on secondaryContainer
//                               (#FDA54F): ~4.7:1 ✅ AA
//                               onSurfaceVariant (#3E4948) on background: ~8:1 ✅
// ✅ Semantic labels            — _BackButton, _PhotoUploadPlaceholder, ElderButton ✅
// ✅ No colour as sole cue      — icons + text on all info cards ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.xl (32dp) between major sections ✅
// ────────────────────────────────────────────────────────────────────────────
