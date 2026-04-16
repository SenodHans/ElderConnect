import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// ── Screen-level constants ────────────────────────────────────────────────────
/// rounded-[2rem] explicit on game cards → 32dp
const double _kGameCardRadius = 32.0;
/// rounded-[2.5rem] explicit on featured section → 40dp
const double _kFeaturedRadius = 40.0;
/// rounded-2xl on icon containers = Tailwind default 1rem → 16dp
const double _kIconContainerRadius = 16.0;
const double _kNavTopRadius = 32.0;
const double _kNavActiveSize = 64.0;
const double _kNavInactiveSize = 56.0;
/// 3 degrees in radians — garden meditation image tilt
const double _kImageRotation = 0.0524;

enum _NavTab { home, feed, games, medication }

/// Elder Games Screen — wellness activities and mind games for elderly users.
///
/// Stitch folder: elder_games_screen.
/// 4 game cards (Memory Flip, Breathing, Sliding Puzzle, Trivia) + featured spotlight.
class ElderGamesScreen extends ConsumerWidget {
  const ElderGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: Column(
        children: [
          const _TopAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ElderSpacing.lg,
                ElderSpacing.xl,
                ElderSpacing.lg,
                ElderSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroSection(),
                  const SizedBox(height: ElderSpacing.xxl),
                  // 4 game cards — single column on mobile (aspect-square each)
                  _GameCard(
                    icon: Icons.psychology,
                    iconBgColor: ElderColors.primaryFixed,
                    iconColor: ElderColors.primary,
                    badgeLabel: 'Cognitive',
                    accentColor: ElderColors.primary,
                    title: 'Memory Card Flip',
                    description:
                        'Test your memory and match the hidden pairs of cards.',
                    ctaLabel: 'Play Now',
                    onTap: () {/* TODO: navigate to memory card game */},
                  ),
                  const SizedBox(height: ElderSpacing.xl),
                  _GameCard(
                    icon: Icons.waves,
                    iconBgColor: ElderColors.tertiaryFixed,
                    iconColor: ElderColors.tertiary,
                    badgeLabel: 'Wellness',
                    accentColor: ElderColors.tertiary,
                    title: 'Breathing Exercise',
                    description:
                        'Find your calm with guided rhythmic breathing patterns.',
                    ctaLabel: 'Start Session',
                    onTap: () {/* TODO: navigate to breathing exercise */},
                  ),
                  const SizedBox(height: ElderSpacing.xl),
                  _GameCard(
                    icon: Icons.extension,
                    iconBgColor: ElderColors.secondaryFixed,
                    iconColor: ElderColors.secondary,
                    badgeLabel: 'Logic',
                    accentColor: ElderColors.secondary,
                    title: 'Sliding Puzzle',
                    description:
                        'Solve the picture by rearranging the scrambled tiles.',
                    ctaLabel: 'Solve It',
                    onTap: () {/* TODO: navigate to sliding puzzle */},
                  ),
                  const SizedBox(height: ElderSpacing.xl),
                  _GameCard(
                    icon: Icons.quiz,
                    iconBgColor: ElderColors.errorContainer,
                    iconColor: ElderColors.error,
                    badgeLabel: 'Knowledge',
                    accentColor: ElderColors.error,
                    title: 'Trivia Quiz',
                    description:
                        'Discover fun facts and challenge your daily knowledge.',
                    ctaLabel: 'Begin Quiz',
                    onTap: () {/* TODO: navigate to trivia quiz */},
                  ),
                  const SizedBox(height: ElderSpacing.xxl),
                  const _FeaturedSection(),
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
        // TODO: drive from provider
        hasMedication: true,
        onTabSelected: (_) {/* TODO: navigate via context.go */},
      ),
    );
  }
}

// ── Top App Bar ───────────────────────────────────────────────────────────────

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

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY WELLBEING',
          // Bumped from text-sm (14sp) to 16sp — font size minimum rule
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ElderColors.primaryContainer,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: ElderSpacing.sm),
        Text(
          'Mind & Spirit\nGames',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: ElderColors.onSurface,
            height: 1.15,
          ),
        ),
        const SizedBox(height: ElderSpacing.md),
        Text(
          'Enjoy activities designed to keep your mind sharp and your heart light. Choose a journey below.',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: ElderColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── Game Card ─────────────────────────────────────────────────────────────────

class _GameCard extends StatefulWidget {
  const _GameCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeLabel,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String badgeLabel;
  final Color accentColor;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.title,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: ElderColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(_kGameCardRadius),
                boxShadow: [
                  BoxShadow(
                    color: ElderColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Decorative glow circle — bottom-right, clipped at card edge
                  Positioned(
                    right: -48,
                    bottom: -48,
                    child: Container(
                      width: 192,
                      height: 192,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(ElderSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon + badge row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: widget.iconBgColor,
                                borderRadius:
                                    BorderRadius.circular(_kIconContainerRadius),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.iconColor,
                                size: 36,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ElderSpacing.md,
                                vertical: ElderSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: widget.accentColor.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: ElderSpacing.sm),
                                  Text(
                                    widget.badgeLabel.toUpperCase(),
                                    // Bumped from text-xs (12sp) to 16sp — font size minimum rule
                                    style: GoogleFonts.lexend(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: widget.accentColor,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Title, description, CTA
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: ElderColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: ElderSpacing.sm),
                            Text(
                              widget.description,
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: ElderColors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: ElderSpacing.lg),
                            Row(
                              children: [
                                Text(
                                  widget.ctaLabel,
                                  style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: widget.accentColor,
                                  ),
                                ),
                                const SizedBox(width: ElderSpacing.sm),
                                Icon(
                                  Icons.arrow_forward,
                                  color: widget.accentColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ── Featured Section ──────────────────────────────────────────────────────────

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kFeaturedRadius),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(ElderSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text content
          Text(
            'Weekly Spotlight',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ElderColors.tertiary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: ElderSpacing.sm),
          Text(
            'Garden Meditation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ElderColors.onSurface,
            ),
          ),
          const SizedBox(height: ElderSpacing.md),
          Text(
            'A new peaceful journey through nature sounds and gentle visualization exercises.',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: ElderColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ElderSpacing.xl),
          Semantics(
            label: 'Explore Garden Meditation',
            button: true,
            child: Material(
              color: ElderColors.primary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {/* TODO: navigate to garden meditation */},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ElderSpacing.xl,
                    vertical: ElderSpacing.md,
                  ),
                  child: Text(
                    'Explore Now',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ElderColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ElderSpacing.xl),
          // Garden image — tonal placeholder rotated 3° (CachedNetworkImage deferred)
          Transform.rotate(
            angle: _kImageRotation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                height: 280,
                color: ElderColors.surfaceContainerHigh,
                child: const Icon(
                  Icons.nature,
                  color: ElderColors.surfaceContainerHighest,
                  size: 72,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

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
      _NavTabData(tab: _NavTab.home, icon: Icons.home, label: 'Home'),
      _NavTabData(tab: _NavTab.feed, icon: Icons.rss_feed, label: 'Feed'),
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
                .map((t) => _NavItem(
                      data: t,
                      isActive: t.tab == activeTab,
                      onTap: () => onTabSelected(t.tab),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTabData {
  const _NavTabData({required this.tab, required this.icon, required this.label});
  final _NavTab tab;
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.data, required this.isActive, required this.onTap});
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
          width: isActive ? _kNavActiveSize : _kNavInactiveSize,
          height: isActive ? _kNavActiveSize : _kNavInactiveSize,
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
                // 12sp exception: inside 64dp constrained pill — two-cue rule
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

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48 px — game cards are aspect-square full-width (300dp+); "Explore Now" padded
// ✅ Font sizes ≥ 16sp — badge labels bumped from 12sp to 16sp; "Daily Wellbeing" bumped from 14sp to 16sp
// ✅ Colour contrast WCAG AA — white on primary; accent colours on white card bg
// ✅ Semantic labels on all game cards and buttons
// ✅ No colour as sole differentiator — each game card uses distinct icon + badge text + accent CTA
// ✅ Touch targets separated by ≥ 8px — 24dp gap between game cards
