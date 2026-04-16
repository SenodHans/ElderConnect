/// Interest selection — step 2 of the elder onboarding flow.
///
/// The user picks at least one of the 6 NewsAPI category tiles.
/// Selected categories are written to [selectedInterestsProvider] and
/// read back to gate the Get Started button. No Supabase call yet.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../providers/interest_provider.dart';

// Stitch design spec: rounded-xl = 1.5rem = 24dp (this Tailwind config maps xl to 1.5rem,
// unlike the default Tailwind xl which is 0.75rem).
const double _kTileRadius = 24.0;

class InterestSelectionScreen extends ConsumerStatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  ConsumerState<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState
    extends ConsumerState<InterestSelectionScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 300ms total — design.md maximum animation duration.
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // Two staggered sections: [0] header, [1] grid.
    _anims = List.generate(
      2,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.15, (i * 0.15) + 0.60, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    for (final a in _anims) { a.dispose(); }
    _anim.dispose();
    super.dispose();
  }

  /// Wraps [child] in a fade + 20 dp upward slide driven by [_anims[i]].
  Widget _animated(int i, Widget child) {
    return AnimatedBuilder(
      animation: _anims[i],
      builder: (_, _) => Opacity(
        opacity: _anims[i].value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _anims[i].value)),
          child: child,
        ),
      ),
    );
  }

  /// Persists the selected interests to the users table then navigates to
  /// the elder home screen. Shows an error message on failure so the elder
  /// (or assisting caretaker) can try again without losing their selection.
  Future<void> _saveAndNavigate(Set<String> interests) async {
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('No signed-in user found.');

      await Supabase.instance.client
          .from('users')
          .update({'interests': interests.toList()})
          .eq('id', uid);

      if (mounted) context.go('/home/elder');
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Could not save. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedInterestsProvider);

    return Scaffold(
      backgroundColor: ElderColors.background,
      // No AppBar — onboarding stays chrome-free.
      body: Column(
        children: [
          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ElderSpacing.lg,
                  ElderSpacing.md,
                  ElderSpacing.lg,
                  ElderSpacing.xxl, // extra clearance so grid doesn't sit behind bottom bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Back button ──────────────────────────────────────
                    _BackButton(onTap: () => context.go('/register/elder')),

                    const SizedBox(height: ElderSpacing.xl),

                    // ── Headline + subtitle ──────────────────────────────
                    _animated(0, _buildHeader()),

                    const SizedBox(height: ElderSpacing.xl),

                    // ── 6-tile interest grid (2 cols) ────────────────────
                    _animated(1, _buildGrid(selected)),
                  ],
                ),
              ),
            ),
          ),

          // ── Fixed bottom action bar ────────────────────────────────────
          _buildBottomBar(selected),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you enjoy?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36, // text-4xl
            fontWeight: FontWeight.w800,
            color: ElderColors.primary,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: ElderSpacing.sm),
        Text(
          "Select the things you'd like to see in your feed.",
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: ElderColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(Set<String> selected) {
    return GridView.count(
      crossAxisCount: 2, // grid-cols-2
      crossAxisSpacing: ElderSpacing.lg, // gap-6 = 24dp
      mainAxisSpacing: ElderSpacing.lg,
      // childAspectRatio: tile width ≈ (390 - 48 - 24) / 2 ≈ 159dp → height = 159/0.90 ≈ 177dp
      childAspectRatio: 0.90,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _interests.map((item) {
        final isSelected = selected.contains(item.category);
        return _InterestTile(
          label: item.label,
          icon: item.icon,
          category: item.category,
          iconBgColor: item.iconBgColor,
          iconColor: item.iconColor,
          selected: isSelected,
          onTap: () =>
              ref.read(selectedInterestsProvider.notifier).toggle(item.category),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(Set<String> selected) {
    final canProceed = selected.isNotEmpty && !_isSaving;
    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ElderSpacing.lg), // p-6 = 24dp
            decoration: BoxDecoration(
              // bg-white/80 backdrop-blur-md
              color: ElderColors.surfaceContainerLowest.withValues(alpha: 0.80),
              border: const Border(
                top: BorderSide(color: ElderColors.surfaceContainer),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient "Get Started" button ───────────────────────
                Semantics(
                  button: true,
                  label: 'Get Started',
                  enabled: canProceed,
                  child: GestureDetector(
                    onTap: canProceed ? () => _saveAndNavigate(selected) : null,
                    child: AnimatedOpacity(
                      opacity: canProceed ? 1.0 : 0.40,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          maxWidth: 448, // max-w-md
                          minHeight: 56,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20), // py-5 = 20dp
                        decoration: BoxDecoration(
                          // bg-gradient-to-r from-primary to-primary-container
                          gradient: const LinearGradient(
                            colors: [ElderColors.primary, ElderColors.primaryContainer],
                          ),
                          borderRadius: BorderRadius.circular(_kTileRadius),
                          boxShadow: canProceed
                              ? [
                                  BoxShadow(
                                    color: ElderColors.primary.withValues(alpha: 0.30),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20, // text-xl font-headline font-bold
                                fontWeight: FontWeight.bold,
                                color: ElderColors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: ElderSpacing.sm),
                            if (_isSaving)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: ElderColors.onPrimary,
                                ),
                              )
                            else
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: ElderColors.onPrimary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Error message — shown if Supabase update fails.
                if (_errorMessage != null) ...[
                  const SizedBox(height: ElderSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      color: ElderColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: ElderSpacing.md),

                // HTML: text-sm text-slate-500 (14px) — raised to 16sp for CLAUDE.md minimum.
                Text(
                  'You can change these anytime in settings.',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ElderColors.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Interest definitions ───────────────────────────────────────────────────

/// Immutable data class for a single interest tile.
class _InterestItem {
  const _InterestItem({
    required this.label,
    required this.icon,
    required this.category,
    required this.iconBgColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;

  /// Lowercase NewsAPI category key stored in [selectedInterestsProvider].
  final String category;

  /// Icon circle background — unique per tile per Stitch design.
  final Color iconBgColor;

  /// Icon foreground colour — unique per tile per Stitch design.
  final Color iconColor;
}

/// Non-const because Color.withValues(alpha:) cannot appear in const constructors.
final List<_InterestItem> _interests = [
  _InterestItem(
    label: 'Health',
    icon: Icons.health_and_safety,
    category: 'health',
    // bg-primary-container/10, icon text-primary-container
    iconBgColor: ElderColors.primaryContainer.withValues(alpha: 0.10),
    iconColor: ElderColors.primaryContainer,
  ),
  _InterestItem(
    label: 'Sports',
    icon: Icons.sports_tennis,
    category: 'sports',
    // bg-secondary-fixed/30, icon text-secondary
    iconBgColor: ElderColors.secondaryFixed.withValues(alpha: 0.30),
    iconColor: ElderColors.secondary,
  ),
  _InterestItem(
    label: 'Technology',
    icon: Icons.devices,
    category: 'technology',
    // bg-tertiary-fixed-dim/20, icon text-tertiary
    iconBgColor: ElderColors.tertiaryFixedDim.withValues(alpha: 0.20),
    iconColor: ElderColors.tertiary,
  ),
  _InterestItem(
    label: 'Entertainment',
    icon: Icons.movie,
    category: 'entertainment',
    // bg-error-container/40, icon text-on-error-container
    iconBgColor: ElderColors.errorContainer.withValues(alpha: 0.40),
    iconColor: ElderColors.onErrorContainer,
  ),
  _InterestItem(
    label: 'Science',
    icon: Icons.biotech,
    category: 'science',
    // bg-tertiary-container/10, icon text-tertiary-container
    iconBgColor: ElderColors.tertiaryContainer.withValues(alpha: 0.10),
    iconColor: ElderColors.tertiaryContainer,
  ),
  _InterestItem(
    label: 'Business',
    icon: Icons.trending_up,
    category: 'business',
    // bg-secondary-container/20, icon text-on-secondary-container
    iconBgColor: ElderColors.secondaryContainer.withValues(alpha: 0.20),
    iconColor: ElderColors.onSecondaryContainer,
  ),
];

// ── _BackButton ────────────────────────────────────────────────────────────

/// Inline back button — 56×56 dp; no AppBar so onboarding stays chrome-free.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go back to name entry',
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

// ── _InterestTile ──────────────────────────────────────────────────────────

/// Single interest category tile.
///
/// Selected state adds a 3px primary ring + primary/5% tint + check badge
/// and switches the label colour to primary — three independent visual cues
/// beyond colour alone, meeting WCAG non-colour-as-sole-cue requirement.
class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.label,
    required this.icon,
    required this.category,
    required this.iconBgColor,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String category;
  final Color iconBgColor;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${selected ? "selected" : "not selected"}',
      // Suppress icon's internal description — the label above is the correct announcement.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(ElderSpacing.lg), // p-6 = 24dp
          decoration: BoxDecoration(
            // bg-primary/5 when selected, bg-surface-container-lowest when not
            color: selected
                ? ElderColors.primary.withValues(alpha: 0.05)
                : ElderColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(_kTileRadius),
            // interest-tile-active: box-shadow 0 0 0 3px primary = solid ring
            border: selected
                ? Border.all(color: ElderColors.primary, width: 3)
                : null,
          ),
          child: Stack(
            children: [
              // ── Tile content ────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // text-left
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon circle — w-14 h-14 = 56dp, rounded-full
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 28, // text-3xl ≈ 30px; 28dp fits neatly in 56dp circle
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: ElderSpacing.md), // mb-4 = 16dp

                  // Label — text-xl font-bold; primary when selected, onSurface otherwise
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: selected ? ElderColors.primary : ElderColors.onSurface,
                    ),
                  ),
                ],
              ),

              // ── Check badge — shown only when selected ──────────────────
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: ElderColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: ElderColors.onPrimary,
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

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 56×56dp    — _BackButton: 56×56 Container ✅
//                              _InterestTile: ~159dp wide × ~177dp tall on 390dp screen ✅
//                              Get Started button: minHeight 56, actual ~64dp ✅
// ✅ Font sizes ≥ 16sp         — headline 36sp w800 | subtitle 18sp w300
//                              | tile label 20sp bold | button 20sp bold
//                              | hint 16sp w500 (raised from HTML's 14px text-sm) ✅
// ✅ Colour contrast WCAG AA   — primary (#005050) on background (#FAF9FA): ~12:1 ✅ AAA
//                              onSurfaceVariant (#3E4948) on background: ~8:1 ✅ AAA
//                              onSurface (#1A1C1D) on surfaceContainerLowest (#FFF): ~17:1 ✅ AAA
//                              primary (#005050) on primary/5% on white: ~12:1 ✅ (selected label)
//                              onPrimary (#FFF) on primary (#005050) gradient: ~12:1 ✅ AAA
//                              outline (#6E7979) on white/80%: ~4.5:1 ✅ AA (hint text)
// ✅ Selection indicators       — 3px primary ring + check badge + label colour change
//                              (three independent cues — not colour alone) ✅
// ✅ Semantic labels on tiles   — Semantics(button:true, selected:selected,
//                              label:'$label, selected/not selected') ✅
//                              excludeSemantics suppresses icon noise ✅
// ✅ Touch targets ≥ 8dp apart  — grid crossAxisSpacing / mainAxisSpacing:
//                              ElderSpacing.lg (24dp) ✅
//                              Back → grid: ElderSpacing.xl (32dp) ✅
// ─────────────────────────────────────────────────────────────────────────────
