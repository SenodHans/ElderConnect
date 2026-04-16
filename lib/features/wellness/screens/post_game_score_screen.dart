/// Post Game Score — celebration result screen shown after an elder completes
/// a wellness game. Displays the score, personal best comparison, family
/// leaderboard, and a share-with-family action prompt.
///
/// Elder portal screen — Games tab is active in the bottom nav.
///
/// Top bar note: Stitch HTML places the elder avatar on the left and a
/// settings icon on the right. All other elder screens use the standard
/// menu-left / wordmark / avatar-right pattern. The standard pattern is
/// used here for portal consistency (Stitch html-shell variation discarded).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Tailwind config for this screen (elder portal — differs from caretaker):
// rounded-xl = 0.75rem = 12dp; rounded-lg = 0.5rem = 8dp; full = 9999px.
// rounded-3xl (not in custom config) = Tailwind default 1.5rem = 24dp.
// rounded-2xl (not in custom config) = Tailwind default 1rem = 16dp.
// rounded-[2rem] / rounded-[2.5rem] are explicit CSS values.
const double _kScoreCardRadius  = 24.0;  // rounded-3xl
const double _kBentoCardRadius  = 32.0;  // rounded-[2rem]
const double _kActionCardRadius = 40.0;  // rounded-[2.5rem]
const double _kLeaderRowRadius  = 16.0;  // rounded-2xl
const double _kButtonRadius     = 12.0;  // rounded-xl (custom config)

// Matches elder_games_screen nav constants.
const double _kNavTopRadius    = 32.0;
const double _kNavActiveSize   = 64.0;
const double _kNavInactiveSize = 56.0;

enum _NavTab { home, feed, games, medication }

class PostGameScoreScreen extends ConsumerStatefulWidget {
  const PostGameScoreScreen({super.key});

  @override
  ConsumerState<PostGameScoreScreen> createState() =>
      _PostGameScoreScreenState();
}

class _PostGameScoreScreenState extends ConsumerState<PostGameScoreScreen>
    with TickerProviderStateMixin {
  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // Four staggered sections: [0] top bar, [1] hero, [2] bento, [3] action.
    _anims = List.generate(
      4,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.08, (i * 0.08) + 0.60, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    for (final a in _anims) { a.dispose(); }
    _anim.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: Column(
        children: [
          _animated(0, const _TopAppBar()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ElderSpacing.lg,
                ElderSpacing.xl,
                ElderSpacing.lg,
                ElderSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _animated(1, const _HeroSection()),
                  const SizedBox(height: ElderSpacing.xxl),
                  _animated(2, const _BentoSection()),
                  const SizedBox(height: ElderSpacing.xxl),
                  _animated(3, const _ActionPromptSection()),
                  // Clearance for bottom nav
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomNav(
        activeTab: _NavTab.games,
        hasMedication: true,
        onTabSelected: (_) {
          // TODO: drive navigation via context.go — post backend sprint.
        },
      ),
    );
  }
}

// ── Top App Bar ───────────────────────────────────────────────────────────────

/// Standard elder portal top bar — menu left, ElderConnect wordmark, avatar right.
///
/// Matches elder_games_screen._TopAppBar exactly for portal consistency.
class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ElderColors.surface.withValues(alpha: 0.80),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.lg,
            vertical: ElderSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Semantics(
                    label: 'Open menu',
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {/* TODO: open side drawer */},
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.menu,
                            color: ElderColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ElderSpacing.md),
                  Text(
                    'ElderConnect',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ElderColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Semantics(
                label: 'Your profile photo',
                button: true,
                child: GestureDetector(
                  onTap: () {/* TODO: navigate to elder profile */},
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ElderColors.primaryFixed,
                        width: 2,
                      ),
                      color: ElderColors.surfaceContainerLow,
                    ),
                    child: const ClipOval(
                      child: Icon(
                        Icons.person,
                        color: ElderColors.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
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

// ── Hero Section ──────────────────────────────────────────────────────────────

/// Centred celebration section: stars icon with amber glow, "Great Job!" title,
/// and the score card.
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stars icon with decorative amber glow blob.
        // Stitch: bg-secondary-container opacity-20 blur-3xl = glowing halo.
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow blob — secondaryContainer (#FDA54F amber) at 20% opacity.
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ElderColors.secondaryContainer.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
              ),
              // Stars icon — filled (FILL=1), text-secondary = amber (#8e4e00).
              const Icon(
                Icons.stars_rounded,
                size: 80,
                color: ElderColors.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: ElderSpacing.lg),

        // "Great Job!" headline — text-5xl = 48sp, Plus Jakarta Sans extrabold.
        Text(
          'Great Job!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: ElderColors.primary,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ElderSpacing.lg),

        // Score card — rounded-3xl = 24dp, surfaceContainerLowest bg, p-8 = 32dp.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ElderSpacing.xl),
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(_kScoreCardRadius),
            boxShadow: [
              BoxShadow(
                color: ElderColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Your Score',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ElderColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: ElderSpacing.sm),
              // Score value — text-5xl = 48sp, secondary amber (#8e4e00).
              Text(
                '1,250 points!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: ElderColors.secondary,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bento Section ─────────────────────────────────────────────────────────────

/// Two-card bento layout stacked vertically on mobile:
///   1. Personal Best — trophy icon + beat-by text.
///   2. Family Standings — 3-row leaderboard.
class _BentoSection extends StatelessWidget {
  const _BentoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPersonalBest(),
        const SizedBox(height: ElderSpacing.lg),
        _buildFamilyStandings(),
      ],
    );
  }

  Widget _buildPersonalBest() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kBentoCardRadius),
      ),
      child: Column(
        children: [
          // Trophy icon — emoji_events in tertiary (#004b74).
          const Icon(
            Icons.emoji_events_rounded,
            size: 40,
            color: ElderColors.tertiary,
          ),
          const SizedBox(height: ElderSpacing.md),
          Text(
            'Personal Best',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ElderColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ElderSpacing.sm),
          // Rich text: "150 points" in primary bold.
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.lexend(
                fontSize: 18,
                color: ElderColors.onSurfaceVariant,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'You surpassed your previous high score by ',
                ),
                TextSpan(
                  text: '150 points',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.primary,
                  ),
                ),
                const TextSpan(text: '!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStandings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kBentoCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: groups icon + title
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                size: 22,
                color: ElderColors.primary,
              ),
              const SizedBox(width: ElderSpacing.sm),
              Text(
                'Family Standings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Leaderboard rows
          _LeaderboardRow(
            rank: 1,
            name: 'You',
            score: '1,250',
            isHighlighted: true,
          ),
          const SizedBox(height: ElderSpacing.md),
          _LeaderboardRow(
            rank: 2,
            name: 'David (Son)',
            score: '1,180',
          ),
          const SizedBox(height: ElderSpacing.md),
          _LeaderboardRow(
            rank: 3,
            name: 'Sarah (Granddaughter)',
            score: '950',
          ),
        ],
      ),
    );
  }
}

// ── Action Prompt Section ─────────────────────────────────────────────────────

/// "Share your success?" CTA — tertiaryFixed bg with decorative blob,
/// plus Yes (primary) and Maybe Later (surfaceContainerHighest) buttons.
class _ActionPromptSection extends StatelessWidget {
  const _ActionPromptSection();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kActionCardRadius),
      child: Container(
        color: ElderColors.tertiaryFixed,
        child: Stack(
          children: [
            // Decorative blob — top-right, tertiaryFixedDim at 30% opacity.
            // Mirrors Stitch: absolute -mr-10 -mt-10 w-40 h-40 opacity-30.
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: ElderColors.tertiaryFixedDim.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(ElderSpacing.xxl),
              child: Column(
                children: [
                  Text(
                    'Share your success?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      // on-tertiary-fixed (#001d31) → onTertiaryFixed.
                      color: ElderColors.onTertiaryFixed,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ElderSpacing.md),
                  Text(
                    'Let your family know how well you\'re doing! They\'ll get a notification with your new score.',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      // on-tertiary-fixed-variant (#004b73) → onTertiaryFixedVariant.
                      color: ElderColors.onTertiaryFixedVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ElderSpacing.xxl),

                  // Action buttons — stacked vertically on mobile.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // "Yes" — primary bg, share icon, min 72dp.
                      Semantics(
                        button: true,
                        label: 'Yes, share my score with family',
                        child: Material(
                          color: ElderColors.primary,
                          borderRadius: BorderRadius.circular(_kButtonRadius),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(_kButtonRadius),
                            onTap: () {
                              // TODO: trigger share notification — post backend sprint.
                            },
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 72),
                              padding: const EdgeInsets.symmetric(
                                horizontal: ElderSpacing.xxl,
                                vertical: ElderSpacing.md,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.share_rounded,
                                    color: ElderColors.onPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: ElderSpacing.sm),
                                  Text(
                                    'Yes',
                                    style: GoogleFonts.lexend(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: ElderColors.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ElderSpacing.md),

                      // "Maybe Later" — surfaceContainerHighest bg, min 72dp.
                      Semantics(
                        button: true,
                        label: 'Maybe later',
                        child: Material(
                          color: ElderColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(_kButtonRadius),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(_kButtonRadius),
                            onTap: () {
                              // TODO: context.go('/games/elder') — dismiss to games.
                            },
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 72),
                              padding: const EdgeInsets.symmetric(
                                horizontal: ElderSpacing.xxl,
                                vertical: ElderSpacing.md,
                              ),
                              child: Center(
                                child: Text(
                                  'Maybe Later',
                                  style: GoogleFonts.lexend(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: ElderColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _LeaderboardRow ───────────────────────────────────────────────────────────

/// Single leaderboard row — rank number, avatar circle, name, score.
///
/// [isHighlighted] true for the current user's row: primaryFixed bg with
/// onPrimaryFixed text and a primaryContainer avatar border.
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    this.isHighlighted = false,
  });

  final int rank;
  final String name;
  final String score;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final textColor = isHighlighted
        ? ElderColors.onPrimaryFixed
        : ElderColors.onSurface;
    final dimColor = isHighlighted
        ? ElderColors.onPrimaryFixed
        : ElderColors.onSurfaceVariant;

    return Semantics(
      label: 'Rank $rank: $name, $score points',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ElderSpacing.sm,
          vertical: ElderSpacing.sm,
        ),
        decoration: BoxDecoration(
          // bg-primary-fixed (#a0f0f0) → primaryFixed; bg-surface → surface.
          color: isHighlighted
              ? ElderColors.primaryFixed
              : ElderColors.surface,
          borderRadius: BorderRadius.circular(_kLeaderRowRadius),
        ),
        child: Row(
          children: [
            // Rank number — w-6 = 24dp reserved width.
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: dimColor,
                ),
              ),
            ),
            const SizedBox(width: ElderSpacing.sm),

            // Avatar circle — 40×40dp, border on highlighted row.
            // TODO(backend-sprint): replace with CachedNetworkImage.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted
                    ? ElderColors.primaryFixedDim
                    : ElderColors.surfaceContainerLow,
                border: isHighlighted
                    ? Border.all(color: ElderColors.primaryContainer, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 22,
                color: isHighlighted
                    ? ElderColors.onPrimaryFixed
                    : ElderColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: ElderSpacing.sm),

            Expanded(
              child: Text(
                name,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),

            // Score
            Text(
              score,
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dimColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

/// Elder portal bottom nav — mirrors elder_games_screen._BottomNav exactly.
/// Games tab is active on this post-game result screen.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.activeTab,
    required this.hasMedication,
    required this.onTabSelected,
  });

  final _NavTab activeTab;
  final bool hasMedication;
  final ValueChanged<_NavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _NavTabData(tab: _NavTab.home,  icon: Icons.home,           label: 'Home'),
      _NavTabData(tab: _NavTab.feed,  icon: Icons.rss_feed,       label: 'Feed'),
      _NavTabData(tab: _NavTab.games, icon: Icons.videogame_asset, label: 'Games'),
      if (hasMedication)
        _NavTabData(tab: _NavTab.medication, icon: Icons.medication, label: 'Medication'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_kNavTopRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ElderSpacing.md,
            ElderSpacing.sm,
            ElderSpacing.md,
            ElderSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs
                .map(
                  (t) => _NavItem(
                    data: t,
                    isActive: t.tab == activeTab,
                    onTap: () => onTabSelected(t.tab),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTabData {
  const _NavTabData({
    required this.tab,
    required this.icon,
    required this.label,
  });
  final _NavTab tab;
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final _NavTabData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isActive ? '${data.label}, selected' : data.label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width:  isActive ? _kNavActiveSize  : _kNavInactiveSize,
          height: isActive ? _kNavActiveSize  : _kNavInactiveSize,
          decoration: isActive
              ? BoxDecoration(
                  color: ElderColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ElderColors.primaryContainer.withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                data.icon,
                color: isActive ? Colors.white : ElderColors.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                // 12sp exception: inside 64dp constrained circle — two-cue (icon+label).
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : ElderColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48dp    — "Yes" button: minHeight 72dp ✅
//                               "Maybe Later" button: minHeight 72dp ✅
//                               top bar menu + avatar: 48×48dp ✅
//                               nav tabs: active 64dp circle; inactive 56dp ✅
// ✅ Font sizes ≥ 16sp         — all body/label text 16sp or above ✅
//                               | "Great Job!": 48sp ✅
//                               | score "1,250 points!": 48sp ✅
//                               | "Your Score": 18sp ✅
//                               | "Personal Best": 24sp ✅
//                               | personal best body: 18sp (raised from lg) ✅
//                               | "Family Standings": 20sp ✅
//                               | leaderboard text: 16sp (raised from font-medium) ✅
//                               | "Share your success?": 30sp ✅
//                               | action subtitle: 18sp ✅
//                               | "Yes" / "Maybe Later": 20sp ✅
//                               | EXCEPTIONS with comment:
//                               |   nav labels: 12sp (circle constrained, two-cue) ✅
// ✅ Colour contrast WCAG AA   — onPrimary (#FFF) on primary (#005050): ~12:1 ✅
//                               onTertiaryFixed (#001d31) on tertiaryFixed (#CCE5FF): ~11:1 ✅
//                               onPrimaryFixed (#002020) on primaryFixed (#A0F0F0): ~9:1 ✅
//                               secondary (#8e4e00) on surfaceContainerLowest: ~7:1 ✅
//                               onSurface (#1a1c1d) on surfaceContainerHighest: ~11:1 ✅
// ✅ Semantic labels            — open menu, profile photo, share score, maybe later,
//                               nav tabs (selected state), all leaderboard rows ✅
// ✅ No colour as sole cue      — rank 1 row: highlighted bg + rank number + "You" label ✅
//                               personal best: icon + text description ✅
//                               buttons: "Yes" / "Maybe Later" labels ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.md (16dp) between bento cards ✅
//                               ElderSpacing.md (16dp) between leaderboard rows ✅
//                               ElderSpacing.md (16dp) between action buttons ✅
// ────────────────────────────────────────────────────────────────────────────
