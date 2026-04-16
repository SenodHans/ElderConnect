import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../providers/medications_provider.dart';

// ── Screen-level constants ────────────────────────────────────────────────────
/// Cards use rounded-[24px] explicit override — 24dp
const double _kCardRadius = 24.0;
/// Pill image: rounded-2xl = 1rem = 16dp (Tailwind default, not overridden)
const double _kImageRadius = 16.0;
/// Action button: rounded-[20px]
const double _kButtonRadius = 20.0;
const double _kNavTopRadius = 32.0;
const double _kNavActiveSize = 64.0;
const double _kNavInactiveSize = 56.0;

enum _NavTab { home, feed, games, medication }

/// Elder Medication List Screen — shows the next upcoming medication and history.
///
/// Stitch folder: elder_medication_screen_1.
/// Single "Confirm Taken" gradient action (initial/simplified view).
class ElderMedicationListScreen extends ConsumerWidget {
  const ElderMedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: Column(
        children: [
          const _StickyHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ElderSpacing.lg,
                ElderSpacing.sm,
                ElderSpacing.lg,
                ElderSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(label: 'Up Next'),
                  const SizedBox(height: ElderSpacing.lg),
                  const _UpNextCard(showDetailButtons: false),
                  const SizedBox(height: ElderSpacing.xxl),
                  _SectionTitle(label: 'History'),
                  const SizedBox(height: ElderSpacing.lg),
                  const _HistorySection(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomNav(
        activeTab: _NavTab.medication,
        // TODO: drive from provider
        hasMedication: true,
        onTabSelected: (_) {/* TODO: navigate via context.go */},
      ),
    );
  }
}

// ── Sticky Header ─────────────────────────────────────────────────────────────

class _StickyHeader extends StatelessWidget {
  const _StickyHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(
          color: ElderColors.surface.withValues(alpha: 0.80),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ElderSpacing.lg,
                vertical: ElderSpacing.lg,
              ),
              child: Text(
                'Medications',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ElderColors.onSurface,
      ),
    );
  }
}

// ── Up Next Card ──────────────────────────────────────────────────────────────

class _UpNextCard extends ConsumerWidget {
  const _UpNextCard({required this.showDetailButtons});
  final bool showDetailButtons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextAsync = ref.watch(nextMedicationProvider);

    return nextAsync.when(
      loading: () => _cardShimmer(),
      error: (_, s) => const SizedBox.shrink(),
      data: (log) {
        if (log == null) {
          return Container(
            padding: const EdgeInsets.all(ElderSpacing.xl),
            decoration: BoxDecoration(
              color: ElderColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(_kCardRadius),
            ),
            child: Center(
              child: Text(
                'No upcoming medications.',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  color: ElderColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: [
              BoxShadow(
                color: ElderColors.onSurface.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(ElderSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill image — tonal placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(_kImageRadius),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: ElderColors.surfaceContainerLow,
                    child: const Icon(
                      Icons.medication,
                      color: ElderColors.surfaceContainerHighest,
                      size: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ElderSpacing.lg),
              Text(
                log.pillName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: ElderSpacing.sm + ElderSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: ElderColors.secondary,
                    size: 26,
                  ),
                  const SizedBox(width: ElderSpacing.sm + ElderSpacing.xs),
                  Text(
                    '${log.dosage} • ${log.timestampFormatted}',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: ElderColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ElderSpacing.lg),
              Semantics(
                label: 'Confirm I have taken my medication',
                button: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ElderColors.primary, ElderColors.primaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(_kButtonRadius),
                    boxShadow: [
                      BoxShadow(
                        color: ElderColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(_kButtonRadius),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_kButtonRadius),
                      onTap: () {/* TODO: log medication as taken */},
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 64),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ElderSpacing.xl,
                          vertical: ElderSpacing.md,
                        ),
                        child: Text(
                          'Confirm Taken',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: ElderColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardShimmer() => Container(
        height: 320,
        decoration: BoxDecoration(
          color: ElderColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
      );
}

// ── History Section ───────────────────────────────────────────────────────────

class _HistorySection extends ConsumerWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(medicationHistoryProvider);

    return historyAsync.when(
      loading: () => Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: ElderSpacing.md),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: ElderColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(_kCardRadius),
              ),
            ),
          ),
        ),
      ),
      error: (_, s) => Text(
        'Could not load history.',
        style: GoogleFonts.lexend(
          fontSize: 18,
          color: ElderColors.onSurfaceVariant,
        ),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Text(
            'No medication history yet.',
            style: GoogleFonts.lexend(
              fontSize: 18,
              color: ElderColors.onSurfaceVariant,
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < logs.length; i++) ...[
              _HistoryItem(
                timestamp: logs[i].timestampFormatted,
                status: logs[i].isMissed ? _MedStatus.missed : _MedStatus.taken,
              ),
              if (i < logs.length - 1)
                const SizedBox(height: ElderSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

enum _MedStatus { taken, missed }

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.timestamp, required this.status});
  final String timestamp;
  final _MedStatus status;

  bool get _isMissed => status == _MedStatus.missed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(ElderSpacing.md + ElderSpacing.xs),
      decoration: BoxDecoration(
        color: _isMissed ? ElderColors.errorContainer : ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Row(
        children: [
          // Status icon circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isMissed ? ElderColors.error : ElderColors.primaryFixed,
              boxShadow: [
                BoxShadow(
                  color: (_isMissed ? ElderColors.error : ElderColors.primary)
                      .withValues(alpha: _isMissed ? 0.30 : 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isMissed ? Icons.cancel : Icons.check_circle,
              color: _isMissed ? ElderColors.onError : ElderColors.onPrimaryFixed,
              size: 30,
            ),
          ),
          const SizedBox(width: ElderSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timestamp,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isMissed ? ElderColors.onErrorContainer : ElderColors.onSurface,
                ),
              ),
              const SizedBox(height: ElderSpacing.xs),
              Text(
                _isMissed ? 'Missed' : 'Taken',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: _isMissed ? FontWeight.w500 : FontWeight.w400,
                  color: _isMissed
                      ? ElderColors.onErrorContainer
                      : ElderColors.onSurfaceVariant,
                ),
              ),
            ],
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
// ✅ Tap targets ≥ 48×48 px — "Confirm Taken" min-height 64dp; history items 88dp min-height
// ✅ Font sizes ≥ 16sp — all body text 16sp+; section titles 20sp; drug name 30sp
// ✅ Colour contrast WCAG AA — onPrimary on primary; onErrorContainer on errorContainer
// ✅ Semantic label on "Confirm Taken" button
// ✅ No colour as sole differentiator — missed items use both errorContainer bg + cancel icon
// ✅ Touch targets separated by ≥ 8px — 16dp gap between history items
