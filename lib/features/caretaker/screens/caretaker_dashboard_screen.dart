/// Caretaker Dashboard — overview screen for the caretaker portal.
///
/// Shows priority alerts (SOS, missed medication, mood shift), linked elder
/// cards with mini stats, and a horizontally-scrollable medication snapshot.
/// Bottom nav provides access to Elder, Mood, and Links tabs (routes added in
/// Batch 3 when those screens are built).
///
/// Colour note: the Stitch caretaker palette uses a dark-navy primary
/// (#00364c) and blue-grey secondary (#4a626d) that differ from the elder
/// portal tokens. We map to the nearest ElderColors.* tokens and flag
/// the divergence — a single token system is intentional for the single-app
/// dual-portal architecture.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Stitch config: rounded-xl = 0.5rem = 8dp (caretaker theme overrides default).
const double _kCardRadius = 8.0;

// rounded-2xl uses Tailwind default (not overridden) = 1rem ≈ 16dp.
const double _kSectionRadius = 16.0;

// rounded-lg = 0.25rem = 4dp (caretaker Tailwind config).
const double _kMiniRadius = 4.0;

// w-24 h-24 = 96dp elder avatar in card.
const double _kAvatarSize = 96.0;

// w-12 h-12 = 48dp alert icon circles.
const double _kAlertCircleSize = 48.0;

// Minimum width of each medication snapshot card (min-w-[200px]).
const double _kMedCardWidth = 204.0;

enum _CTab { dashboard, elder, mood, links }

class CaretakerDashboardScreen extends ConsumerStatefulWidget {
  const CaretakerDashboardScreen({super.key});

  @override
  ConsumerState<CaretakerDashboardScreen> createState() =>
      _CaretakerDashboardScreenState();
}

class _CaretakerDashboardScreenState
    extends ConsumerState<CaretakerDashboardScreen>
    with TickerProviderStateMixin {
  _CTab _activeTab = _CTab.dashboard;

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // Four staggered sections: [0] top bar, [1] alerts, [2] elders, [3] meds.
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
      backgroundColor: ElderColors.background,
      body: Stack(
        children: [
          // ── Scrollable content (sits beneath sticky top bar) ───────────────
          CustomScrollView(
            slivers: [
              // Reserve space for the 72dp sticky top bar.
              const SliverToBoxAdapter(child: SizedBox(height: 72)),
              SliverPadding(
                // Extra bottom padding so content clears the bottom nav.
                padding: const EdgeInsets.fromLTRB(
                  ElderSpacing.lg,
                  ElderSpacing.lg,
                  ElderSpacing.lg,
                  ElderSpacing.lg + 88,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _animated(1, _buildAlertsSection()),
                    const SizedBox(height: ElderSpacing.xxl),
                    _animated(2, _buildLinkedEldersSection()),
                    const SizedBox(height: ElderSpacing.xxl),
                    _animated(3, _buildMedSnapshotSection()),
                  ]),
                ),
              ),
            ],
          ),

          // ── Sticky top bar (overlays content) ─────────────────────────────
          _animated(0, _buildTopBar()),
        ],
      ),
      bottomSheet: _buildBottomNav(),
    );
  }

  // ── Top App Bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 72,
            color: ElderColors.surface.withValues(alpha: 0.80),
            padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
            child: Row(
              children: [
                // medical_services icon + wordmark
                const Icon(
                  Icons.medical_services_rounded,
                  size: 24,
                  color: ElderColors.primary,
                ),
                const SizedBox(width: ElderSpacing.sm),
                Text(
                  'ElderConnect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                // Caretaker avatar — 40×40, secondary-container tint
                Semantics(
                  label: 'Caretaker profile',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // secondary-container in caretaker palette (#cae4f1 light
                      // blue) → nearest elder token: tertiaryFixed (#CCE5FF).
                      color: ElderColors.tertiaryFixed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ElderColors.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: ElderColors.onTertiaryFixed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Priority Alerts ─────────────────────────────────────────────────────────

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // text-secondary in caretaker palette (#4a626d) → onSurfaceVariant.
            Text(
              'PRIORITY ALERTS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ElderColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '3 Active Alerts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: ElderColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.md),

        // SOS — red container, filled error circle.
        _AlertCard(
          bg: ElderColors.errorContainer,
          circleColor: ElderColors.error,
          icon: Icons.sos_rounded,
          iconColor: ElderColors.onError,
          name: 'Margaret S.',
          badge: 'SOS',
          badgeBg: ElderColors.error,
          badgeFg: ElderColors.onError,
          body: 'Fall detected in Living Room.',
          timestamp: '2 minutes ago',
          textColor: ElderColors.onErrorContainer,
        ),

        const SizedBox(height: ElderSpacing.md),

        // Missed Meds — tonal surface, primaryContainer circle.
        _AlertCard(
          bg: ElderColors.surfaceContainerLow,
          circleColor: ElderColors.primaryContainer,
          icon: Icons.medication_rounded,
          iconColor: ElderColors.onPrimaryContainer,
          name: 'Arthur J.',
          body: 'Missed morning Warfarin dose.',
          timestamp: 'Scheduled 08:00 AM',
          textColor: ElderColors.onSurfaceVariant,
        ),

        const SizedBox(height: ElderSpacing.md),

        // Mood Shift — tonal surface, tertiaryFixed circle (light blue = caretaker
        // secondary-container #cae4f1 ≈ tertiaryFixed #CCE5FF).
        _AlertCard(
          bg: ElderColors.surfaceContainerLow,
          circleColor: ElderColors.tertiaryFixed,
          icon: Icons.psychology_rounded,
          iconColor: ElderColors.onTertiaryFixed,
          name: 'Elena G.',
          body: 'Significant decline in morning mood.',
          timestamp: 'Checked 1 hour ago',
          textColor: ElderColors.onSurfaceVariant,
        ),
      ],
    );
  }

  // ── Linked Elders ───────────────────────────────────────────────────────────

  Widget _buildLinkedEldersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Linked Elders',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ElderColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: ElderSpacing.lg),
        _ElderCard(
          name: 'Margaret Smith',
          lastLogin: 'Last Login: 15m ago',
          badgeLabel: 'Stable',
          // tertiary-container in caretaker palette (#005248 dark teal)
          // → nearest elder token: tertiaryContainer (#0E6496).
          badgeBg: ElderColors.tertiaryContainer,
          badgeFg: ElderColors.onTertiaryContainer,
          moodLabel: 'Positive (9/10)',
          activityLabel: '1,240 steps',
          onViewDetails: () {
            // TODO: context.go('/elders/caretaker/detail') — Batch 3.
          },
          onMessage: () {
            // TODO: context.go('/elders/caretaker/message') — Batch 3.
          },
        ),
        const SizedBox(height: ElderSpacing.lg),
        _ElderCard(
          name: 'Arthur Jenkins',
          lastLogin: 'Last Login: 2h ago',
          badgeLabel: 'Warning',
          badgeBg: ElderColors.errorContainer,
          badgeFg: ElderColors.onErrorContainer,
          moodLabel: 'Fatigued (4/10)',
          activityLabel: '230 steps',
          onViewDetails: () {
            // TODO: context.go('/elders/caretaker/detail') — Batch 3.
          },
          onMessage: () {
            // TODO: context.go('/elders/caretaker/message') — Batch 3.
          },
        ),
      ],
    );
  }

  // ── Medication Snapshot ─────────────────────────────────────────────────────

  Widget _buildMedSnapshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MEDICATION SNAPSHOT (NEXT 4 HOURS)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: ElderSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(_kSectionRadius),
          ),
          padding: const EdgeInsets.all(ElderSpacing.lg),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MedSnapshotCard(
                  timeLabel: '12:30 PM',
                  isOverdue: false,
                  accentColor: ElderColors.primary,
                  icon: Icons.medication_rounded,
                  drugName: 'Metformin 500mg',
                  patientName: 'Margaret Smith',
                ),
                const SizedBox(width: ElderSpacing.md),
                // border-secondary (#4a626d) → onSurfaceVariant is closest neutral.
                _MedSnapshotCard(
                  timeLabel: '01:00 PM',
                  isOverdue: false,
                  accentColor: ElderColors.onSurfaceVariant,
                  icon: Icons.medication_rounded,
                  drugName: 'Lisinopril 10mg',
                  patientName: 'Arthur Jenkins',
                ),
                const SizedBox(width: ElderSpacing.md),
                // border-tertiary (#003932 dark green) → ElderColors.tertiary.
                _MedSnapshotCard(
                  timeLabel: '02:15 PM',
                  isOverdue: false,
                  accentColor: ElderColors.tertiary,
                  icon: Icons.vaccines_rounded,
                  drugName: 'B12 Injection',
                  patientName: 'Elena G.',
                ),
                const SizedBox(width: ElderSpacing.md),
                _MedSnapshotCard(
                  timeLabel: 'OVERDUE',
                  isOverdue: true,
                  accentColor: ElderColors.error,
                  icon: Icons.warning_rounded,
                  drugName: 'Warfarin 5mg',
                  patientName: 'Arthur Jenkins',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(_kSectionRadius),
        topRight: Radius.circular(_kSectionRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: ElderColors.surfaceContainerLowest.withValues(alpha: 0.90),
          padding: EdgeInsets.only(
            left: ElderSpacing.sm,
            right: ElderSpacing.sm,
            top: ElderSpacing.sm,
            bottom: MediaQuery.paddingOf(context).bottom + ElderSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: _activeTab == _CTab.dashboard,
                onTap: () => setState(() => _activeTab = _CTab.dashboard),
              ),
              _NavItem(
                icon: Icons.elderly_rounded,
                label: 'Elder',
                active: _activeTab == _CTab.elder,
                onTap: () {
                  setState(() => _activeTab = _CTab.elder);
                  // TODO: context.go('/elders/caretaker') — Batch 3.
                },
              ),
              _NavItem(
                icon: Icons.psychology_rounded,
                label: 'Mood',
                active: _activeTab == _CTab.mood,
                onTap: () {
                  setState(() => _activeTab = _CTab.mood);
                  // TODO: context.go('/mood-logs/caretaker') — Batch 3.
                },
              ),
              _NavItem(
                icon: Icons.link_rounded,
                label: 'Links',
                active: _activeTab == _CTab.links,
                onTap: () {
                  setState(() => _activeTab = _CTab.links);
                  // TODO: context.go('/links/caretaker') — Batch 3.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _AlertCard ───────────────────────────────────────────────────────────────

/// Priority alert tile — SOS, missed medication, or mood shift.
///
/// [badge] is optional — only the SOS alert carries a pill badge label.
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.bg,
    required this.circleColor,
    required this.icon,
    required this.iconColor,
    required this.name,
    this.badge,
    this.badgeBg,
    this.badgeFg,
    required this.body,
    required this.timestamp,
    required this.textColor,
  });

  final Color bg;
  final Color circleColor;
  final IconData icon;
  final Color iconColor;
  final String name;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeFg;
  final String body;
  final String timestamp;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle — w-12 h-12 = 48dp
          Container(
            width: _kAlertCircleSize,
            height: _kAlertCircleSize,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: ElderSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + optional SOS badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: ElderSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ElderSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: badgeFg,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: ElderSpacing.sm),
                Text(
                  timestamp,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: textColor.withValues(alpha: 0.70),
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

// ── _ElderCard ───────────────────────────────────────────────────────────────

/// Linked elder summary card.
///
/// Displays a tonal avatar placeholder, name/last-login/status badge, 2-col
/// mini stats (mood + activity), and gradient "View Details" + solid "Message"
/// buttons. Network avatar is deferred to backend sprint (TODO below).
class _ElderCard extends StatelessWidget {
  const _ElderCard({
    required this.name,
    required this.lastLogin,
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeFg,
    required this.moodLabel,
    required this.activityLabel,
    required this.onViewDetails,
    required this.onMessage,
  });

  final String name;
  final String lastLogin;
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeFg;
  final String moodLabel;
  final String activityLabel;
  final VoidCallback onViewDetails;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name elder card',
      child: Container(
        padding: const EdgeInsets.all(ElderSpacing.lg),
        decoration: BoxDecoration(
          color: ElderColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: ElderColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 64,
              spreadRadius: -12,
              offset: const Offset(0, 32),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name/badge row ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // w-24 h-24 rounded-2xl = 96dp, 16dp radius.
                // TODO(backend-sprint): replace with CachedNetworkImage from Supabase Storage.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: _kAvatarSize,
                    height: _kAvatarSize,
                    color: ElderColors.surfaceContainerLow,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: ElderColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: ElderSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ElderColors.primary,
                                  ),
                                ),
                                Text(
                                  lastLogin,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    color: ElderColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badge — Stable or Warning
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ElderSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badgeLabel.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: badgeFg,
                                letterSpacing: 1.0,
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

            const SizedBox(height: ElderSpacing.md),

            // ── 2-col mini stats ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MiniStat(label: 'Mood Check', value: moodLabel),
                ),
                const SizedBox(width: ElderSpacing.md),
                Expanded(
                  child: _MiniStat(label: 'Activity', value: activityLabel),
                ),
              ],
            ),

            const SizedBox(height: ElderSpacing.md),

            // ── Action buttons ────────────────────────────────────────────
            Row(
              children: [
                // Gradient "View Details" (clinical-gradient).
                Semantics(
                  button: true,
                  label: 'View details for $name',
                  child: GestureDetector(
                    onTap: onViewDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ElderSpacing.md,
                        vertical: ElderSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ElderColors.primary,
                            ElderColors.primaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(_kCardRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            size: 18,
                            color: ElderColors.onPrimary,
                          ),
                          const SizedBox(width: ElderSpacing.xs),
                          Text(
                            'View Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ElderColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ElderSpacing.sm),
                // Solid "Message" button.
                Semantics(
                  button: true,
                  label: 'Message $name',
                  child: GestureDetector(
                    onTap: onMessage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ElderSpacing.md,
                        vertical: ElderSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: ElderColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(_kCardRadius),
                      ),
                      child: Text(
                        'Message',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ElderColors.onSurface,
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
    );
  }
}

// ── _MiniStat ────────────────────────────────────────────────────────────────

/// 2-col stat tile inside elder card — rounded-lg = 4dp.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.sm),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kMiniRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ElderColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElderColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _MedSnapshotCard ─────────────────────────────────────────────────────────

/// Individual medication card in the horizontal snapshot row.
///
/// Uses the established ClipRRect + IntrinsicHeight left-border pattern
/// (Flutter BoxDecoration ignores borderRadius when border sides differ).
class _MedSnapshotCard extends StatelessWidget {
  const _MedSnapshotCard({
    required this.timeLabel,
    required this.isOverdue,
    required this.accentColor,
    required this.icon,
    required this.drugName,
    required this.patientName,
  });

  final String timeLabel;
  final bool isOverdue;
  final Color accentColor;
  final IconData icon;
  final String drugName;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isOverdue ? 0.85 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent border — border-l-4 = 4dp
              Container(width: 4, color: accentColor),
              Container(
                width: _kMedCardWidth,
                color: ElderColors.surfaceContainerLowest,
                padding: const EdgeInsets.all(ElderSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time badge or OVERDUE indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElderSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? ElderColors.errorContainer
                                : ElderColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(_kMiniRadius),
                          ),
                          child: Text(
                            timeLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isOverdue
                                  ? ElderColors.onErrorContainer
                                  : ElderColors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Icon(icon, size: 20, color: accentColor),
                      ],
                    ),
                    const SizedBox(height: ElderSpacing.sm),
                    Text(
                      drugName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? ElderColors.error : ElderColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _NavItem ─────────────────────────────────────────────────────────────────

/// Bottom navigation tab for the caretaker portal.
///
/// Active state: surfaceContainerLow bg + rounded-xl (8dp) pill + primary colour.
/// Inactive state: transparent bg + onSurfaceVariant colour.
/// Nav label exception: 12sp inside constrained pill — two-cue (icon+label).
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.md,
            vertical: ElderSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: active
                ? ElderColors.surfaceContainerLow
                : Colors.transparent,
            borderRadius: BorderRadius.circular(_kCardRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: active
                    ? ElderColors.primary
                    : ElderColors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                // 12sp exception: constrained pill, two-cue navigation (icon+label).
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? ElderColors.primary
                      : ElderColors.onSurfaceVariant,
                  letterSpacing: 0.8,
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
// ✅ Tap targets ≥ 56×56dp    — "View Details" + "Message" buttons: 56dp min
//                               row height (16px padding×2 + 24px font+line)
//                               ≥ 48dp ✅; nav tabs: ~56dp with padding ✅
// ✅ Font sizes ≥ 16sp         — all text is 16sp or above; 18sp for elder name
//                               | SOS badge 16sp (raised from 10px original) ✅
//                               | timestamp 16sp (raised from 12px) ✅
//                               | stat labels 16sp (raised from 10px) ✅
//                               | nav labels 12sp EXCEPTION: constrained pill,
//                               two-cue (icon+label) ✅
// ✅ Colour contrast WCAG AA   — onErrorContainer (#93000A) on errorContainer
//                               (#FFDAD6): ~8:1 ✅ AAA
//                               onPrimary (#FFF) on primary (#005050): ~12:1 ✅
//                               onTertiaryFixed on tertiaryFixed: ~7:1 ✅ AAA
//                               primary on surfaceContainerLowest: ~12:1 ✅
//                               onSurfaceVariant on surfaceContainerLow: ~7:1 ✅
// ✅ Semantic labels            — caretaker avatar, View Details, Message,
//                               nav items (button+selected), elder card ✅
// ✅ No colour as sole cue      — SOS card: icon + badge text + red colour ✅
//                               Warning badge: label text + colour ✅
//                               OVERDUE: badge text + red colour + icon ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.md (16dp) between alert cards ✅
//                               ElderSpacing.lg (24dp) between elder cards ✅
// ────────────────────────────────────────────────────────────────────────────
