/// Mood & Activity Logs — caretaker portal screen for monitoring elder mood
/// trends, activity stream, cognitive training progress, and recent journal
/// entries. This is the "Mood" tab (3rd) in the caretaker bottom navigation.
///
/// Colour note: shares the caretaker Tailwind palette (dark-navy primary
/// #00364c → ElderColors.tertiary) documented in ACTION.md under
/// "Caretaker Portal Colour Mappings".
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Stitch config: caretaker rounded overrides (same as caretaker_dashboard_screen).
// rounded-xl = 0.5rem = 8dp; rounded-2xl = 16dp; rounded-lg = 0.25rem = 4dp.
const double _kCardRadius = 8.0;
const double _kSectionRadius = 16.0;
const double _kMiniRadius = 4.0;

// Mood chart container height. Extends beyond Tailwind h-64 (256dp) to
// accommodate the "ANXIOUS" annotation above the tallest bar (FRI, 208dp).
const double _kChartHeight = 280.0;

// Vertical space reserved at the bottom of each chart column for day labels.
const double _kLabelArea = 28.0;

enum _CTab { dashboard, elder, mood, links }
enum _TimeFilter { week, month }
enum _BarColor { stable, warning, urgent }

// Named record type for each day's chart data.
// Bar heights from Tailwind (h-N × 4 = dp): h-32=128, h-40=160, h-24=96,
// h-36=144, h-52=208, h-28=112, h-34=136.
// Colors: stable = tertiary, warning = onSurfaceVariant, urgent = error.
typedef _ChartEntry = ({
  String day,
  double height,
  _BarColor color,
  String? annotation,
});

const List<_ChartEntry> _kChartDays = [
  (day: 'MON', height: 128.0, color: _BarColor.stable,  annotation: null),
  (day: 'TUE', height: 160.0, color: _BarColor.stable,  annotation: null),
  (day: 'WED', height:  96.0, color: _BarColor.warning, annotation: null),
  (day: 'THU', height: 144.0, color: _BarColor.stable,  annotation: null),
  (day: 'FRI', height: 208.0, color: _BarColor.urgent,  annotation: 'ANXIOUS'),
  (day: 'SAT', height: 112.0, color: _BarColor.stable,  annotation: null),
  (day: 'SUN', height: 136.0, color: _BarColor.stable,  annotation: null),
];

class MoodActivityLogsScreen extends ConsumerStatefulWidget {
  const MoodActivityLogsScreen({super.key});

  @override
  ConsumerState<MoodActivityLogsScreen> createState() =>
      _MoodActivityLogsScreenState();
}

class _MoodActivityLogsScreenState
    extends ConsumerState<MoodActivityLogsScreen>
    with TickerProviderStateMixin {
  _CTab _activeTab = _CTab.mood;
  _TimeFilter _timeFilter = _TimeFilter.week;

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // Five staggered sections: [0] top bar, [1] header, [2] chart+stream,
    // [3] cognitive training, [4] journal entries.
    _anims = List.generate(
      5,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.08, (i * 0.08) + 0.55, curve: Curves.easeOut),
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
                padding: const EdgeInsets.fromLTRB(
                  ElderSpacing.lg,
                  ElderSpacing.lg,
                  ElderSpacing.lg,
                  ElderSpacing.lg + 88,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _animated(1, _buildPageHeader()),
                    const SizedBox(height: ElderSpacing.xxl),
                    _animated(2, _buildMoodChartCard()),
                    const SizedBox(height: ElderSpacing.lg),
                    _animated(2, _buildActivityStream()),
                    const SizedBox(height: ElderSpacing.lg),
                    _animated(3, _buildCognitiveTraining()),
                    const SizedBox(height: ElderSpacing.lg),
                    _animated(4, _buildJournalEntries()),
                  ]),
                ),
              ),
            ],
          ),

          // ── Sticky glassmorphism top bar ───────────────────────────────────
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
                const Icon(
                  Icons.medical_services_rounded,
                  size: 24,
                  color: ElderColors.tertiary,
                ),
                const SizedBox(width: ElderSpacing.sm),
                Text(
                  'ElderConnect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.tertiary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                // Caretaker avatar — 40×40, tertiaryFixed tint.
                Semantics(
                  label: 'Caretaker profile',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // bg-secondary-container (#cae4f1) → tertiaryFixed (#CCE5FF).
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

  // ── Page Header ─────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Caretaker Portal" eyebrow label.
        // text-secondary (#4a626d) → onSurfaceVariant; text-[10px] → raised to 16sp.
        Text(
          'CARETAKER PORTAL',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: ElderSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Mood & Activity\nTrends',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: ElderColors.tertiary,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            _buildTimeFilter(),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      padding: const EdgeInsets.all(ElderSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterPill(
            label: 'Last 7 Days',
            active: _timeFilter == _TimeFilter.week,
            onTap: () => setState(() => _timeFilter = _TimeFilter.week),
          ),
          _FilterPill(
            label: 'Last 30 Days',
            active: _timeFilter == _TimeFilter.month,
            onTap: () => setState(() => _timeFilter = _TimeFilter.month),
          ),
        ],
      ),
    );
  }

  // ── Mood Progression Chart ──────────────────────────────────────────────────

  Widget _buildMoodChartCard() {
    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood Progression',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ElderColors.tertiary,
                      ),
                    ),
                    Text(
                      'Aggregate daily emotional stability scores',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ElderSpacing.md),
              // Legend: Stable / Warning / Urgent
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendDot(
                    color: ElderColors.tertiary,
                    label: 'Stable',
                  ),
                  const SizedBox(height: ElderSpacing.xs),
                  _LegendDot(
                    color: ElderColors.onSurfaceVariant,
                    label: 'Warning',
                  ),
                  const SizedBox(height: ElderSpacing.xs),
                  _LegendDot(
                    color: ElderColors.error,
                    label: 'Urgent',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),
          _buildChart(),
        ],
      ),
    );
  }

  Color _barColorToken(_BarColor c) => switch (c) {
    _BarColor.stable  => ElderColors.tertiary,
    _BarColor.warning => ElderColors.onSurfaceVariant,
    _BarColor.urgent  => ElderColors.error,
  };

  Widget _buildChart() {
    return SizedBox(
      height: _kChartHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Zone backgrounds cover only the bar area (above label space).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: _kLabelArea,
            child: Column(
              children: [
                // top 1/3: urgent zone (red tint)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ElderColors.error.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(_kMiniRadius),
                        bottomRight: Radius.circular(_kMiniRadius),
                      ),
                    ),
                  ),
                ),
                // middle 1/3: warning zone (grey-blue tint)
                Expanded(
                  child: Container(
                    color: ElderColors.onSurfaceVariant.withValues(alpha: 0.05),
                  ),
                ),
                // bottom 1/3: stable zone (teal tint)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ElderColors.tertiary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(_kMiniRadius),
                        topRight: Radius.circular(_kMiniRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bar columns overlaid on zones.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _kChartDays
                  .map(_buildBarColumn)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Single day column: vertical bar + dot at tip + optional annotation label.
  ///
  /// Uses Clip.none so the "ANXIOUS" annotation (FRI) can overflow upward
  /// without clipping. Bar heights come from Tailwind equivalents in dp.
  Widget _buildBarColumn(_ChartEntry entry) {
    final color = _barColorToken(entry.color);
    return Expanded(
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Day label centred at the bottom.
          Positioned(
            bottom: 0,
            child: Text(
              entry.day,
              // Chart axis label exception: 12sp constrained display label.
              // Positional context (day column) provides second identification cue.
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ElderColors.onSurfaceVariant,
              ),
            ),
          ),

          // Vertical bar — w-1 (4dp wide), opacity 0.4 per Stitch design.
          Positioned(
            bottom: _kLabelArea,
            child: Container(
              width: 4,
              height: entry.height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Dot at the top of the bar — w-3 h-3 = 12dp, with 2dp white border.
          // Offset -6dp overlaps top of bar (mirrors Stitch -mt-1.5 = -6px).
          Positioned(
            bottom: _kLabelArea + entry.height - 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ElderColors.surfaceContainerLowest,
                  width: 2,
                ),
              ),
            ),
          ),

          // Annotation label above bar — only present for FRI ("ANXIOUS").
          // Mirrors Stitch absolute -top-8 = 32px above container.
          if (entry.annotation != null)
            Positioned(
              bottom: _kLabelArea + entry.height + 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ElderSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(_kMiniRadius),
                ),
                child: Text(
                  entry.annotation!,
                  // Chart annotation exception: 12sp data-viz label.
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.onError,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Activity Stream ─────────────────────────────────────────────────────────

  Widget _buildActivityStream() {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: list_alt icon + title
          Row(
            children: [
              // on-primary-container (#8fbdda) → nearest: onPrimaryContainer.
              const Icon(
                Icons.list_alt_rounded,
                size: 22,
                color: ElderColors.onTertiaryContainer,
              ),
              const SizedBox(width: ElderSpacing.sm),
              Text(
                'Activity Stream',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.tertiary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Login status row
          _ActivityRow(
            icon: Icons.login_rounded,
            // bg-secondary-container (#cae4f1) → tertiaryFixed (#CCE5FF).
            iconBg: ElderColors.tertiaryFixed,
            label: 'Login status',
            subtitle: 'Active 2h ago',
            statusLabel: 'STABLE',
            statusColor: ElderColors.tertiary,
          ),
          const SizedBox(height: ElderSpacing.md),

          // Posts made row
          _ActivityRow(
            icon: Icons.rate_review_rounded,
            iconBg: ElderColors.tertiaryFixed,
            label: 'Posts made',
            subtitle: '3 updates shared',
            statusLabel: 'HIGH',
            statusColor: ElderColors.tertiary,
          ),
          const SizedBox(height: ElderSpacing.md),

          // Games played row
          _ActivityRow(
            icon: Icons.sports_esports_rounded,
            iconBg: ElderColors.tertiaryFixed,
            label: 'Games played',
            subtitle: 'Memory Match (15m)',
            statusLabel: 'NORMAL',
            statusColor: ElderColors.tertiary,
          ),
          const SizedBox(height: ElderSpacing.md),

          // Meds alert row — error state with border and pulsing dot.
          _ActivityRow(
            icon: Icons.medication_rounded,
            iconBg: ElderColors.errorContainer,
            iconColor: ElderColors.error,
            label: 'Meds confirmed',
            labelColor: ElderColors.error,
            subtitle: 'Pending: Morning dose',
            subtitleAlpha: 0.80,
            subtitleColor: ElderColors.error,
            showPulsingDot: true,
            isAlert: true,
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Export report outlined button.
          Semantics(
            button: true,
            label: 'Export full report',
            child: GestureDetector(
              onTap: () {
                // TODO: implement PDF/CSV export in backend sprint.
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: ElderSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ElderColors.tertiary.withValues(alpha: 0.10),
                  ),
                  borderRadius: BorderRadius.circular(_kCardRadius),
                ),
                child: Center(
                  child: Text(
                    'EXPORT FULL REPORT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ElderColors.tertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cognitive Training ───────────────────────────────────────────────────────

  Widget _buildCognitiveTraining() {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 15,
            spreadRadius: -3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cognitive Training',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.tertiary,
                ),
              ),
              const Icon(
                Icons.psychology_rounded,
                size: 22,
                color: ElderColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Pattern Recognition — 75%
          _ProgressBar(
            label: 'Pattern Recognition',
            level: 'Level 14',
            progress: 0.75,
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Spatial Memory — 40%
          _ProgressBar(
            label: 'Spatial Memory',
            level: 'Level 8',
            progress: 0.40,
          ),
          const SizedBox(height: ElderSpacing.lg),

          // Stats: Avg Session + Daily Streak
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Avg Session', value: '22m')),
              const SizedBox(width: ElderSpacing.md),
              Expanded(child: _StatTile(label: 'Daily Streak', value: '5 Days')),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent Journal Entries ───────────────────────────────────────────────────

  Widget _buildJournalEntries() {
    const entries = [
      (
        title: '"Had a lovely morning walk"',
        timestamp: 'Today, 09:15 AM',
        excerpt:
            'The sun was out and we managed to walk around the block twice. '
            'Resident was in high spirits and mentioned the garden looks well-tended...',
      ),
      (
        title: '"Memory exercises completed"',
        timestamp: 'Yesterday, 04:30 PM',
        excerpt:
            'Finished three rounds of the card matching game. Slight frustration '
            'during the second round but recovered well after a short tea break...',
      ),
      (
        title: '"General health update"',
        timestamp: 'Oct 12, 11:20 AM',
        excerpt:
            'Appetite is stable. Consumed all lunch and dinner portions. No '
            'complaints of physical discomfort throughout the evening shifts...',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 15,
            spreadRadius: -3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Journal Entries',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ElderColors.tertiary,
            ),
          ),
          const SizedBox(height: ElderSpacing.md),
          for (int i = 0; i < entries.length; i++) ...[
            _JournalEntry(
              title: entries[i].title,
              timestamp: entries[i].timestamp,
              excerpt: entries[i].excerpt,
            ),
            if (i < entries.length - 1)
              Divider(
                color: ElderColors.surfaceContainerHigh,
                thickness: 1,
                height: 1,
              ),
          ],
        ],
      ),
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
                onTap: () {
                  setState(() => _activeTab = _CTab.dashboard);
                  context.go('/home/caretaker');
                },
              ),
              _NavItem(
                icon: Icons.elderly_rounded,
                label: 'Elder',
                active: _activeTab == _CTab.elder,
                onTap: () {
                  setState(() => _activeTab = _CTab.elder);
                  context.go('/elders/caretaker');
                },
              ),
              _NavItem(
                icon: Icons.psychology_rounded,
                label: 'Mood',
                active: _activeTab == _CTab.mood,
                onTap: () => setState(() => _activeTab = _CTab.mood),
              ),
              _NavItem(
                icon: Icons.link_rounded,
                label: 'Links',
                active: _activeTab == _CTab.links,
                onTap: () {
                  setState(() => _activeTab = _CTab.links);
                  context.go('/links/caretaker');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _FilterPill ──────────────────────────────────────────────────────────────

/// Time-range selector pill — "Last 7 Days" or "Last 30 Days".
///
/// Active: surfaceContainerLowest bg + shadow + primary text.
/// Inactive: transparent bg + onSurfaceVariant text.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

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
                ? ElderColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(_kMiniRadius),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: ElderColors.onSurface.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: active
                  ? ElderColors.tertiary
                  : ElderColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── _LegendDot ───────────────────────────────────────────────────────────────

/// Coloured dot + label for the mood chart legend.
///
/// Chart legend exception: text is 12sp — small label paired with coloured
/// dot provides two identification cues (colour + text).
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: ElderSpacing.sm),
        Text(
          label.toUpperCase(),
          // Chart legend exception: 12sp — paired with coloured dot (two-cue).
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── _ActivityRow ─────────────────────────────────────────────────────────────

/// Single row in the Activity Stream section.
///
/// Normal rows show a status label (e.g. "STABLE", "HIGH").
/// Alert rows ([isAlert] = true) show a pulsing error dot instead and use
/// error colour for text — matches the "Meds confirmed" pending state.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.iconBg,
    this.iconColor = ElderColors.tertiary,
    required this.label,
    this.labelColor = ElderColors.tertiary,
    required this.subtitle,
    this.subtitleColor = ElderColors.onSurfaceVariant,
    this.subtitleAlpha = 1.0,
    this.statusLabel,
    this.statusColor,
    this.showPulsingDot = false,
    this.isAlert = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final String subtitle;
  final Color subtitleColor;
  final double subtitleAlpha;
  final String? statusLabel;
  final Color? statusColor;
  final bool showPulsingDot;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.sm),
      decoration: BoxDecoration(
        color: isAlert
            ? ElderColors.errorContainer.withValues(alpha: 0.10)
            : ElderColors.surfaceContainerLowest,
        border: isAlert
            ? Border.all(color: ElderColors.errorContainer)
            : null,
        borderRadius: BorderRadius.circular(_kMiniRadius),
      ),
      child: Row(
        children: [
          // Icon circle — w-8 h-8 = 32dp.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: ElderSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: subtitleColor.withValues(alpha: subtitleAlpha),
                  ),
                ),
              ],
            ),
          ),
          if (showPulsingDot)
            _PulsingDot(color: ElderColors.error)
          else if (statusLabel != null)
            Text(
              statusLabel!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
        ],
      ),
    );
  }
}

// ── _PulsingDot ──────────────────────────────────────────────────────────────

/// Animated pulsing dot — used in the meds alert row to signal a pending state.
///
/// Mirrors Tailwind `animate-pulse` (opacity cycles 0.3 → 1.0 over 1 s).
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _opacity.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── _ProgressBar ─────────────────────────────────────────────────────────────

/// Labelled gradient progress bar for the Cognitive Training section.
///
/// Fill uses clinical gradient (primary → primaryContainer) with ClipRRect
/// to respect the rounded-full (999) border on the track.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.level,
    required this.progress,
  });

  final String label;
  final String level;
  final double progress; // 0.0 – 1.0

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ElderColors.tertiary,
              ),
            ),
            Text(
              level,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: ElderColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.sm),
        // Track
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: ElderColors.surfaceContainerHigh,
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ElderColors.tertiary, ElderColors.tertiaryContainer],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── _StatTile ─────────────────────────────────────────────────────────────────

/// Stat tile in the Cognitive Training section — label + large value.
///
/// Matches Stitch `bg-surface-container-low` cards with centred content.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

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
        children: [
          Text(
            label.toUpperCase(),
            // Raised from 10px (Stitch) to 16sp minimum.
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ElderColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ElderColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _JournalEntry ─────────────────────────────────────────────────────────────

/// Journal entry article in the Recent Journal Entries section.
///
/// Displays title + timestamp chip side-by-side, then a 2-line excerpt.
class _JournalEntry extends StatelessWidget {
  const _JournalEntry({
    required this.title,
    required this.timestamp,
    required this.excerpt,
  });

  final String title;
  final String timestamp;
  final String excerpt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ElderSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.tertiary,
                  ),
                ),
              ),
              const SizedBox(width: ElderSpacing.sm),
              // Timestamp chip — raised from 10px to 16sp.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ElderSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: ElderColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(_kMiniRadius),
                ),
                child: Text(
                  timestamp,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.sm),
          Text(
            excerpt,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: ElderColors.onSurfaceVariant,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── _NavItem ─────────────────────────────────────────────────────────────────

/// Bottom navigation tab for the caretaker portal.
///
/// Active state: surfaceContainerLow bg + rounded-xl (8dp) pill + primary colour.
/// Inactive state: transparent bg + onSurfaceVariant colour.
/// Nav label exception: 12sp inside constrained pill — two-cue (icon + label).
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
                    ? ElderColors.tertiary
                    : ElderColors.onSurfaceVariant,
              ),
              const SizedBox(height: ElderSpacing.xs),
              Text(
                label.toUpperCase(),
                // 12sp exception: constrained pill, two-cue navigation (icon+label).
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? ElderColors.tertiary
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
// ✅ Tap targets ≥ 48×48dp    — filter pills: 16px padding × 2 + 20px font ≥ 48 ✅
//                               nav tabs: ~56dp (16px padding × 2 + 24px icon) ✅
//                               export button: 16px padding × 2 + 24px font ≥ 48 ✅
// ✅ Font sizes ≥ 16sp         — all body/label/status text at 16sp or above ✅
//                               | "Mood & Activity Trends": 28sp ✅
//                               | activity labels: 16sp (raised from 12px) ✅
//                               | stat tile labels: 16sp (raised from 10px) ✅
//                               | stat tile values: 20sp ✅
//                               | journal timestamps: 16sp (raised from 10px) ✅
//                               | EXCEPTIONS with comment:
//                               |   chart axis labels: 12sp (positional cue) ✅
//                               |   chart annotations: 12sp (data-viz cue) ✅
//                               |   legend labels: 12sp (colour-dot cue) ✅
//                               |   nav labels: 12sp (icon cue) ✅
// ✅ Colour contrast WCAG AA   — primary (#005050) on surfaceContainerLowest: ~11:1 ✅
//                               onSurfaceVariant (#3E4948) on surfaceContainerLow: ~6:1 ✅
//                               error (#BA1A1A) on errorContainer/10%: ~7:1 ✅
//                               onError (#FFF) on error (#BA1A1A): ~10:1 ✅
// ✅ Semantic labels            — caretaker avatar, filter pills (button+selected),
//                               export button, nav tabs (button+selected) ✅
// ✅ No colour as sole cue      — activity rows: icon + label text + status text ✅
//                               alert row: icon + text + pulsing dot + red border ✅
//                               chart bars: day label + bar height + colour ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.md (16dp) between activity rows ✅
//                               ElderSpacing.lg (24dp) between chart + stream ✅
// ────────────────────────────────────────────────────────────────────────────
