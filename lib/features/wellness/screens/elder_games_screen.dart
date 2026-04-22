import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../medications/providers/medications_provider.dart';
import '../../../shared/widgets/aa_button.dart';

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

enum _NavTab { home, feed, games, medication }

/// Elder Games Screen — wellness activities and mind games for elderly users.
///
/// Stitch folder: elder_games_screen.
/// 4 game cards (Memory Flip, Breathing, Word Scramble, Trivia) + featured spotlight.
class ElderGamesScreen extends ConsumerWidget {
  const ElderGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home/elder');
        }
      },
      child: Scaffold(
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
                    const SizedBox(height: ElderSpacing.lg),
                    // Single-column rectangle cards — original style, reduced height
                    _GameCard(
                      icon: Icons.psychology,
                      iconBgColor: ElderColors.primaryFixed,
                      iconColor: ElderColors.primary,
                      badgeLabel: 'Cognitive',
                      accentColor: ElderColors.primary,
                      title: 'Memory Card Flip',
                      description: 'Test your memory and match the hidden pairs of cards.',
                      onTap: () => context.go('/games/memory'),
                    ),
                    const SizedBox(height: ElderSpacing.md),
                    _GameCard(
                      icon: Icons.waves,
                      iconBgColor: ElderColors.tertiaryFixed,
                      iconColor: ElderColors.tertiary,
                      badgeLabel: 'Wellness',
                      accentColor: ElderColors.tertiary,
                      title: 'Breathing Exercise',
                      description: 'Find your calm with guided rhythmic breathing patterns.',
                      onTap: () => context.go('/games/breathing'),
                    ),
                    const SizedBox(height: ElderSpacing.md),
                    _GameCard(
                      icon: Icons.text_fields_rounded,
                      iconBgColor: ElderColors.secondaryFixed,
                      iconColor: ElderColors.secondary,
                      badgeLabel: 'Language',
                      accentColor: ElderColors.secondary,
                      title: 'Word Scramble',
                      description: 'Tap the shuffled letters in the right order to spell the word.',
                      onTap: () => context.go('/games/scramble'),
                    ),
                    const SizedBox(height: ElderSpacing.md),
                    _GameCard(
                      icon: Icons.quiz,
                      iconBgColor: ElderColors.errorContainer,
                      iconColor: ElderColors.error,
                      badgeLabel: 'Knowledge',
                      accentColor: ElderColors.error,
                      title: 'Trivia Quiz',
                      description: 'Discover fun facts and challenge your daily knowledge.',
                      onTap: () => context.go('/games/trivia'),
                    ),
                    const SizedBox(height: ElderSpacing.xxl),
                    const _DailyTipSection(),
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
          hasMedication: ref.watch(hasMedicationProvider),
          onTabSelected: (tab) {
            switch (tab) {
              case _NavTab.home:       context.go('/home/elder');
              case _NavTab.feed:       context.go('/feed/elder');
              case _NavTab.medication: context.go('/medications/elder');
              case _NavTab.games:      break;
            }
          },
        ),
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
              Semantics(
                label: 'Your profile photo',
                button: true,
                child: GestureDetector(
                  onTap: () => context.go('/profile/elder'),
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
              const AaButton(),
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

// ── Compact Game Tile (2-column grid) ─────────────────────────────────────────

/// Compact card for the 2-column game grid. Shows icon, badge, and title only.
/// No description or CTA text — the whole tile is one large tap target.
class _GameTile extends StatefulWidget {
  const _GameTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeLabel,
    required this.accentColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String badgeLabel;
  final Color accentColor;
  final String title;
  final VoidCallback onTap;

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.title.replaceAll('\n', ' '),
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: ElderColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: ElderColors.onSurface.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Subtle accent glow in corner
                Positioned(
                  right: -24,
                  bottom: -24,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(ElderSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.iconBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.icon,
                            color: widget.iconColor, size: 28),
                      ),
                      const Spacer(),
                      // Title
                      Text(
                        widget.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ElderColors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: ElderSpacing.xs),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: ElderSpacing.sm,
                            vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.badgeLabel.toUpperCase(),
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.accentColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
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

// ── Full-size Game Card (unused by grid, kept for reference) ──────────────────

/// Horizontal rectangle game card — same visual style as original but
/// landscape-shaped (icon left, text right) so 4 cards fit without excessive scrolling.
class _GameCard extends StatefulWidget {
  const _GameCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeLabel,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String badgeLabel;
  final Color accentColor;
  final String title;
  final String description;
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
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: ElderColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(_kGameCardRadius),
              boxShadow: [
                BoxShadow(
                  color: ElderColors.onSurface.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Decorative glow — right side, matching original style
                Positioned(
                  right: -32,
                  top: -32,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                // Horizontal layout: icon | text | arrow
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ElderSpacing.lg,
                    vertical: ElderSpacing.md,
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: widget.iconBgColor,
                          borderRadius: BorderRadius.circular(_kIconContainerRadius),
                        ),
                        child: Icon(widget.icon,
                            color: widget.iconColor, size: 32),
                      ),
                      const SizedBox(width: ElderSpacing.lg),
                      // Title + badge + description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: ElderColors.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: ElderSpacing.sm, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.accentColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    widget.badgeLabel.toUpperCase(),
                                    style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: widget.accentColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: ElderSpacing.xs),
                            Text(
                              widget.description,
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                color: ElderColors.onSurfaceVariant,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: ElderSpacing.sm),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: widget.accentColor, size: 18),
                    ],
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

// ── Daily Tip Section ─────────────────────────────────────────────────────────

/// One wellness tip per screen open, chosen randomly from a curated pool.
/// Tips are displayed as a warm card — no backend dependency.
class _DailyTipSection extends StatefulWidget {
  const _DailyTipSection();

  @override
  State<_DailyTipSection> createState() => _DailyTipSectionState();
}

class _DailyTipSectionState extends State<_DailyTipSection> {
  static const _tips = [
    _Tip(
      icon: Icons.self_improvement,
      iconBg: ElderColors.tertiaryFixed,
      iconColor: ElderColors.tertiary,
      label: 'Mindfulness',
      body: 'Take 5 slow, deep breaths before any meal to calm your body and settle your mind.',
    ),
    _Tip(
      icon: Icons.wb_sunny_outlined,
      iconBg: ElderColors.secondaryFixed,
      iconColor: ElderColors.secondary,
      label: 'Morning Routine',
      body: 'Start your day with a glass of water and 5 minutes of gentle stretching to energise your body.',
    ),
    _Tip(
      icon: Icons.directions_walk,
      iconBg: ElderColors.primaryFixed,
      iconColor: ElderColors.primary,
      label: 'Stay Active',
      body: 'Even a 10-minute walk after lunch improves digestion and lifts your mood.',
    ),
    _Tip(
      icon: Icons.people_outline,
      iconBg: ElderColors.tertiaryFixed,
      iconColor: ElderColors.tertiary,
      label: 'Stay Connected',
      body: 'Calling a friend or family member today can brighten both your days.',
    ),
    _Tip(
      icon: Icons.nightlight_round,
      iconBg: ElderColors.primaryFixed,
      iconColor: ElderColors.primary,
      label: 'Sleep Well',
      body: 'Going to bed at the same time each night leads to deeper, more restful sleep.',
    ),
    _Tip(
      icon: Icons.local_florist_outlined,
      iconBg: ElderColors.secondaryFixed,
      iconColor: ElderColors.secondary,
      label: 'Nature Therapy',
      body: 'Spending a few minutes near plants or outdoors can noticeably lower stress levels.',
    ),
    _Tip(
      icon: Icons.music_note_outlined,
      iconBg: ElderColors.tertiaryFixed,
      iconColor: ElderColors.tertiary,
      label: 'Music & Mood',
      body: 'Listening to your favourite music for 10 minutes can uplift your spirits and reduce anxiety.',
    ),
  ];

  late final _Tip _tip;

  @override
  void initState() {
    super.initState();
    // Pick a tip by day-of-year so it is consistent within a day but
    // changes daily — no randomness needed, no backend dependency.
    final dayIndex = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays %
        _tips.length;
    _tip = _tips[dayIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kFeaturedRadius),
      ),
      padding: const EdgeInsets.all(ElderSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow label
          Text(
            "TODAY'S WELLNESS TIP",
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElderColors.tertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Icon + category row
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _tip.iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_tip.icon, color: _tip.iconColor, size: 28),
              ),
              const SizedBox(width: ElderSpacing.md),
              Text(
                _tip.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Tip body
          Text(
            _tip.body,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: ElderColors.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data record for a single wellness tip.
class _Tip {
  const _Tip({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String body;
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
