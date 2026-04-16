import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../auth/providers/user_provider.dart';
import '../../medications/providers/medications_provider.dart';

// ── Screen-level constants ────────────────────────────────────────────────────
/// rounded-xl = 1.5rem in Stitch Tailwind config → 24dp
const double _kCardRadius = 24.0;
/// rounded-t-[32px] on the bottom nav sheet
const double _kNavTopRadius = 32.0;
const double _kNavActiveSize = 64.0;
const double _kNavInactiveSize = 56.0;

enum _NavTab { home, feed, games, medication }

/// Elder Home Screen — primary dashboard for elderly users.
///
/// Stitch folder: elder_home_screen.
/// Bottom nav: 3 default tabs (Home, Feed, Games) + conditional Medication tab
/// shown only when a caretaker has added at least one medication.
class ElderHomeScreen extends ConsumerStatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  ConsumerState<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends ConsumerState<ElderHomeScreen> {
  _NavTab _activeTab = _NavTab.home;

  @override
  Widget build(BuildContext context) {
    final bool hasMedication = ref.watch(hasMedicationProvider);
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
                  const _GreetingSection(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _MedicationCard(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _MoodCard(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _ConnectCard(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _EmergencySection(),
                  // Clearance for the overlaid bottom nav sheet
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomNav(
        activeTab: _activeTab,
        hasMedication: hasMedication,
        onTabSelected: (tab) => setState(() => _activeTab = tab),
      ),
    );
  }
}

// ── Top App Bar ───────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(
          color: ElderColors.surface.withValues(alpha:0.80),
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
                                size: 28,
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
                          fontWeight: FontWeight.w800,
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
                            color: ElderColors.primaryContainer,
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
        ),
      ),
    );
  }
}

// ── Greeting Section ──────────────────────────────────────────────────────────

class _GreetingSection extends ConsumerWidget {
  const _GreetingSection();

  /// Returns 'Good morning', 'Good afternoon', or 'Good evening'
  /// based on the device's local time.
  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final firstName = userAsync.when(
      data: (user) => user?.firstName ?? '',
      loading: () => '',
      error: (_, s) => '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName.isEmpty
              ? '${_timeGreeting()}!'
              : '${_timeGreeting()}, $firstName',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: ElderColors.primary,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: ElderSpacing.sm),
        Text(
          "It's a beautiful sunny Tuesday.",
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: ElderColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Medication Reminder Card ──────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  const _MedicationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ElderColors.primaryContainer,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.primaryContainer.withValues(alpha:0.40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow circle — clipped at card boundary per Stitch overflow-hidden
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF), // white 10%
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(ElderSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication, color: Colors.white, size: 36),
                    const SizedBox(width: ElderSpacing.md),
                    Text(
                      'COMING UP SOON',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ElderSpacing.md),
                Text(
                  // TODO: replace with next scheduled medication from provider
                  'Lisinopril 10mg',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: ElderSpacing.xs),
                Text(
                  'Scheduled for 8:00 AM',
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: ElderColors.onPrimaryContainer.withValues(alpha:0.90),
                  ),
                ),
                const SizedBox(height: ElderSpacing.xl),
                // "Yes, I took it" — primary action
                Semantics(
                  label: 'Yes, I took my medication',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {/* TODO: log medication as taken */},
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text('Yes, I took it'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ElderColors.primaryContainer,
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: ElderSpacing.md + ElderSpacing.xs,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ElderSpacing.md),
                // "Not yet" — secondary / snooze action
                Semantics(
                  label: 'Not yet — remind me later',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {/* TODO: snooze medication reminder */},
                      style: TextButton.styleFrom(
                        backgroundColor: ElderColors.primary.withValues(alpha:0.20),
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: ElderSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Not yet'),
                    ),
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

// ── Mood Check Card ───────────────────────────────────────────────────────────

class _MoodCard extends StatelessWidget {
  const _MoodCard();

  static const _moods = [
    ('😊', 'Great'),
    ('🙂', 'Good'),
    ('😐', 'Okay'),
    ('😴', 'Tired'),
    ('😔', 'Sad'),
    ('🤒', 'Unwell'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling right now?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: ElderColors.onSurface,
            ),
          ),
          const SizedBox(height: ElderSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: ElderSpacing.md,
              mainAxisSpacing: ElderSpacing.md,
              childAspectRatio: 1.0,
            ),
            itemCount: _moods.length,
            itemBuilder: (context, i) {
              final (emoji, label) = _moods[i];
              return _MoodButton(emoji: emoji, label: label);
            },
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatefulWidget {
  const _MoodButton({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.88),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          // TODO: record mood selection → trigger AI mood log if consent given
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: ElderSpacing.md,
              horizontal: ElderSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: ElderSpacing.xs),
                Text(
                  widget.label,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ElderColors.onSurface,
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

// ── Connect with Family Card ──────────────────────────────────────────────────

class _ConnectCard extends StatelessWidget {
  const _ConnectCard();

  @override
  Widget build(BuildContext context) {
    // ClipRRect + Row approach for left border + rounded corners
    // (Flutter BoxDecoration ignores borderRadius when Border sides differ)
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent border — border-l-8 border-secondary-container
            Container(
              width: 8,
              color: ElderColors.secondaryContainer,
            ),
            Expanded(
              child: Container(
                color: ElderColors.surfaceContainerLow,
                padding: const EdgeInsets.all(ElderSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect with Family',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ElderColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: ElderSpacing.sm),
                    Text(
                      'Share a photo or thought with your family today',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: ElderColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: ElderSpacing.lg),
                    Semantics(
                      label: 'Share a photo or thought with family',
                      button: true,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {/* TODO: navigate to post creation */},
                          icon: const Icon(Icons.add_a_photo, size: 22),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ElderColors.secondaryContainer,
                            foregroundColor: ElderColors.onSecondaryContainer,
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: ElderSpacing.md + ElderSpacing.xs,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Emergency Section ─────────────────────────────────────────────────────────

class _EmergencySection extends StatelessWidget {
  const _EmergencySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: ElderColors.error, size: 22),
            const SizedBox(width: ElderSpacing.sm),
            Text(
              'QUICK HELP',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ElderColors.error,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.md),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Emergency Dial — call for help',
                button: true,
                // Emergency Dial → secondaryContainer (amber) per CLAUDE.md Emergency Colour rule
                child: _EmergencyButton(
                  icon: Icons.phone_forwarded,
                  label: 'Emergency\nDial',
                  backgroundColor: ElderColors.secondaryContainer,
                  foregroundColor: ElderColors.onSecondaryContainer,
                  iconSize: 36,
                  fontSize: 20,
                  onTap: () {/* TODO: initiate emergency call */},
                ),
              ),
            ),
            const SizedBox(width: ElderSpacing.md),
            Expanded(
              child: Semantics(
                label: 'SOS — send emergency alert',
                button: true,
                // SOS → ElderColors.error only (reserved hard emergency)
                child: _EmergencyButton(
                  icon: Icons.emergency,
                  label: 'SOS',
                  backgroundColor: ElderColors.error,
                  foregroundColor: ElderColors.onError,
                  iconSize: 44,
                  fontSize: 24,
                  onTap: () {/* TODO: send SOS alert to caretaker */},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final double iconSize;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: backgroundColor.withValues(alpha:0.40),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: ElderSpacing.lg,
            horizontal: ElderSpacing.md,
          ),
          child: Column(
            children: [
              Icon(icon, color: foregroundColor, size: iconSize),
              const SizedBox(height: ElderSpacing.sm),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
            color: ElderColors.onSurface.withValues(alpha:0.05),
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
            children: tabs.map((t) => _NavItem(
              data: t,
              isActive: t.tab == activeTab,
              onTap: () => onTabSelected(t.tab),
            )).toList(),
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
          width: isActive ? _kNavActiveSize : _kNavInactiveSize,
          height: isActive ? _kNavActiveSize : _kNavInactiveSize,
          decoration: isActive
              ? BoxDecoration(
                  color: ElderColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ElderColors.primaryContainer.withValues(alpha:0.40),
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
                // 12sp exception: inside 64dp constrained pill — two-cue identification
                // (icon + label) satisfies accessibility. See feedback_workflow.md.
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
// ✅ Tap targets ≥ 48×48 px — all interactive elements sized ≥ 48dp
// ✅ Font sizes ≥ 16sp — exception: nav labels 12sp inside 64dp pill (icon+label two-cue rule)
// ✅ Colour contrast WCAG AA — white on primaryContainer, onSecondaryContainer on secondaryContainer
// ✅ Semantic labels on all icon buttons and images
// ✅ No colour as sole differentiator — active nav uses filled pill + size change
// ✅ Touch targets separated by ≥ 8px spacing — grid 16dp gaps, nav uses spaceAround
