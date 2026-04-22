import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../auth/providers/user_provider.dart';
import '../../../shared/widgets/aa_button.dart';

// ── Screen-level constants ────────────────────────────────────────────────────
/// rounded-xl = 1.5rem in this screen's Tailwind config → 24dp
const double _kCardRadius = 24.0;
/// Large avatar: rounded-[3rem] = 48dp
const double _kAvatarRadius = 48.0;
/// Edit button overlay: rounded-2xl = 1rem (Tailwind default) = 16dp
const double _kEditButtonRadius = 16.0;


/// Elder Profile Screen — user identity, interests, health info, caretakers, settings.
///
/// Stitch folder: elder_profile.
/// Accessed via top-right avatar in the elder portal app bar.
class ElderProfileScreen extends ConsumerStatefulWidget {
  const ElderProfileScreen({super.key});

  @override
  ConsumerState<ElderProfileScreen> createState() => _ElderProfileScreenState();
}

class _ElderProfileScreenState extends ConsumerState<ElderProfileScreen> {
  bool _highContrastEnabled = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home/elder');
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
                    const _IdentitySection(),
                    const SizedBox(height: ElderSpacing.xxl),
                    const _InterestsSection(),
                    const SizedBox(height: ElderSpacing.xxl),
                    const _HealthSection(),
                    const SizedBox(height: ElderSpacing.xxl),
                    const _LinkedCaretakersSection(),
                    const SizedBox(height: ElderSpacing.xxl),
                    const _EmergencySection(),
                    const SizedBox(height: ElderSpacing.xxl),
                    _AppSettingsSection(
                      highContrastEnabled: _highContrastEnabled,
                      onContrastToggle: (v) => setState(() => _highContrastEnabled = v),
                    ),
                    const SizedBox(height: ElderSpacing.xl),
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

// ── Top App Bar ───────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

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
                vertical: ElderSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Go back',
                    button: true,
                    child: Material(
                      color: ElderColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go('/home/elder'),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: ElderColors.onSurface,
                            size: 24,
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
        ),
      ),
    );
  }
}

// ── Identity Section ──────────────────────────────────────────────────────────

class _IdentitySection extends ConsumerWidget {
  const _IdentitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final fullName = userAsync.when(
      data: (user) => user?.fullName ?? '',
      loading: () => '',
      error: (_, s) => '',
    );

    return Column(
      children: [
        // Avatar with edit overlay
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Large avatar
            Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kAvatarRadius),
                color: ElderColors.surfaceContainerLow,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: ElderColors.onSurface.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kAvatarRadius - 4),
                child: const Icon(
                  Icons.person,
                  color: ElderColors.surfaceContainerHighest,
                  size: 96,
                ),
              ),
            ),
            // Edit button — bottom-right overlay
            Positioned(
              bottom: 8,
              right: -8,
              child: Semantics(
                label: 'Edit profile photo',
                button: true,
                child: Material(
                  color: ElderColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(_kEditButtonRadius),
                  elevation: 4,
                  shadowColor: ElderColors.secondaryContainer.withValues(alpha: 0.40),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_kEditButtonRadius),
                    onTap: () {/* TODO: open photo picker */},
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.edit,
                        color: ElderColors.onSecondaryContainer,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.lg),
        // Show a loading shimmer placeholder while the name loads.
        fullName.isEmpty
            ? Container(
                width: 180,
                height: 32,
                decoration: BoxDecoration(
                  color: ElderColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : Text(
                fullName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: ElderColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
        const SizedBox(height: ElderSpacing.xs),
        Text(
          'Residence: Sunny Oaks Pavilion',
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ElderColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Interests Section ─────────────────────────────────────────────────────────

class _InterestsSection extends StatelessWidget {
  const _InterestsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ElderColors.onSurface,
              ),
            ),
            Semantics(
              label: 'Edit interest tiles',
              button: true,
              child: TextButton(
                onPressed: () => context.go('/interest-selection'),
                style: TextButton.styleFrom(
                  foregroundColor: ElderColors.primary,
                  textStyle: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kCardRadius),
                  ),
                ),
                child: const Text('Edit Tiles'),
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.lg),
        // Row 1: Reading + Gardening (equal width)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _InterestTile(
                  icon: Icons.menu_book,
                  label: 'Reading History',
                  backgroundColor: ElderColors.primary,
                  foregroundColor: ElderColors.onPrimary,
                  minHeight: 160,
                ),
              ),
              const SizedBox(width: ElderSpacing.md),
              Expanded(
                child: _InterestTile(
                  icon: Icons.yard,
                  label: 'Gardening',
                  backgroundColor: ElderColors.secondaryContainer,
                  foregroundColor: ElderColors.onSecondaryContainer,
                  minHeight: 160,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ElderSpacing.md),
        // Row 2: Classical Music — full width with trailing chevron
        _ClassicalMusicTile(),
      ],
    );
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.minHeight,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 40),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicalMusicTile extends StatelessWidget {
  const _ClassicalMusicTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.piano, color: ElderColors.tertiary, size: 40),
              const SizedBox(width: ElderSpacing.md),
              Text(
                'Classical Music',
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ElderColors.onSurface,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.chevron_right,
            color: ElderColors.outline,
            size: 28,
          ),
        ],
      ),
    );
  }
}

// ── Health Details Section ────────────────────────────────────────────────────

class _HealthSection extends StatelessWidget {
  const _HealthSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety,
                color: ElderColors.error,
                size: 24,
              ),
              const SizedBox(width: ElderSpacing.sm),
              Text(
                'Health Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HealthStat(
                  label: 'Blood Type',
                  value: 'O Positive (O+)',
                ),
              ),
              const SizedBox(width: ElderSpacing.xl),
              Expanded(
                child: _HealthStat(
                  label: 'Date of Birth',
                  value: 'May 12, 1945',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthStat extends StatelessWidget {
  const _HealthStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          // Bumped from text-sm (14sp) to 16sp — font size minimum rule
          style: GoogleFonts.lexend(
            fontSize: 16,
            color: ElderColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: ElderSpacing.xs),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ElderColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Linked Caretakers Section ─────────────────────────────────────────────────

class _LinkedCaretakersSection extends StatelessWidget {
  const _LinkedCaretakersSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked Caretakers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ElderColors.onSurface,
          ),
        ),
        const SizedBox(height: ElderSpacing.lg),
        _CaretakerRow(
          name: 'Sarah Miller',
          role: 'Daughter',
          avatarBg: ElderColors.tertiaryFixed,
          avatarIcon: Icons.person,
          avatarIconColor: ElderColors.onTertiaryFixed,
          actionIcon: Icons.call,
          actionLabel: 'Call Sarah Miller',
          onAction: () {/* TODO: initiate call */},
        ),
        const SizedBox(height: ElderSpacing.md),
        _CaretakerRow(
          name: 'David Chen',
          role: 'Primary Nurse',
          avatarBg: ElderColors.primaryFixed,
          avatarIcon: Icons.medical_services,
          avatarIconColor: ElderColors.onPrimaryFixed,
          actionIcon: Icons.chat,
          actionLabel: 'Message David Chen',
          onAction: () {/* TODO: open messaging */},
        ),
      ],
    );
  }
}

class _CaretakerRow extends StatelessWidget {
  const _CaretakerRow({
    required this.name,
    required this.role,
    required this.avatarBg,
    required this.avatarIcon,
    required this.avatarIconColor,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
  });

  final String name;
  final String role;
  final Color avatarBg;
  final IconData avatarIcon;
  final Color avatarIconColor;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.md + ElderSpacing.xs),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarBg,
            ),
            child: Icon(avatarIcon, color: avatarIconColor, size: 26),
          ),
          const SizedBox(width: ElderSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.onSurface,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: actionLabel,
            button: true,
            child: Material(
              color: ElderColors.surfaceContainerHigh,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAction,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(actionIcon, color: ElderColors.primary, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Emergency Contacts Section ────────────────────────────────────────────────

class _EmergencySection extends StatelessWidget {
  const _EmergencySection();

  @override
  Widget build(BuildContext context) {
    // Left border + rounded corners — same ClipRRect + Row pattern as ConnectCard
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 8, color: ElderColors.error),
            Expanded(
              child: Container(
                color: ElderColors.errorContainer,
                padding: const EdgeInsets.all(ElderSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emergency,
                          color: ElderColors.onErrorContainer,
                          size: 22,
                        ),
                        const SizedBox(width: ElderSpacing.sm + ElderSpacing.xs),
                        Text(
                          'Emergency Contacts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ElderColors.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ElderSpacing.md),
                    _EmergencyContactRow(
                      name: 'Hospital Hot-line',
                      number: '911',
                      showDivider: true,
                    ),
                    const SizedBox(height: ElderSpacing.md),
                    _EmergencyContactRow(
                      name: 'Sarah Miller',
                      number: '(555) 012-3456',
                      showDivider: false,
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

class _EmergencyContactRow extends StatelessWidget {
  const _EmergencyContactRow({
    required this.name,
    required this.number,
    required this.showDivider,
  });

  final String name;
  final String number;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ElderColors.onErrorContainer,
              ),
            ),
            Text(
              number,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ElderColors.onErrorContainer,
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: ElderSpacing.md),
          Container(
            height: 1,
            color: ElderColors.error.withValues(alpha: 0.10),
          ),
        ],
      ],
    );
  }
}

// ── App Settings Section ──────────────────────────────────────────────────────

class _AppSettingsSection extends StatelessWidget {
  const _AppSettingsSection({
    required this.highContrastEnabled,
    required this.onContrastToggle,
  });

  final bool highContrastEnabled;
  final ValueChanged<bool> onContrastToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ElderColors.onSurface,
          ),
        ),
        const SizedBox(height: ElderSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: [
              BoxShadow(
                color: ElderColors.onSurface.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // High Contrast toggle row
              Padding(
                padding: const EdgeInsets.all(ElderSpacing.lg),
                child: Row(
                  children: [
                    const Icon(
                      Icons.contrast,
                      color: ElderColors.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(width: ElderSpacing.md),
                    Expanded(
                      child: Text(
                        'High Contrast',
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ElderColors.onSurface,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'High contrast toggle',
                      toggled: highContrastEnabled,
                      child: Switch(
                        value: highContrastEnabled,
                        onChanged: (v) {
                          onContrastToggle(v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                v ? 'High contrast enabled' : 'High contrast disabled',
                                style: GoogleFonts.lexend(fontSize: 16),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          // TODO(backend-sprint): persist contrast preference to users table
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: ElderColors.primary,
                        inactiveThumbColor: ElderColors.onSurfaceVariant,
                        inactiveTrackColor: ElderColors.surfaceContainerHigh,
                      ),
                    ),
                  ],
                ),
              ),
              // Language row
              Padding(
                padding: const EdgeInsets.all(ElderSpacing.lg),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language,
                      color: ElderColors.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(width: ElderSpacing.md),
                    Expanded(
                      child: Text(
                        'Language',
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ElderColors.onSurface,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Language selection, currently English',
                      button: true,
                      child: GestureDetector(
                        onTap: () {/* TODO: open language picker */},
                        child: Row(
                          children: [
                            Text(
                              'English',
                              style: GoogleFonts.lexend(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ElderColors.primary,
                              ),
                            ),
                            const Icon(
                              Icons.expand_more,
                              color: ElderColors.primary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48 px — edit button 56dp; caretaker action buttons 48dp; settings rows padded
// ✅ Font sizes ≥ 16sp — health labels bumped from 14sp to 16sp; all body text 16sp+
// ✅ Colour contrast WCAG AA — onPrimary on primary; onErrorContainer on errorContainer
// ✅ Semantic labels on edit button, caretaker actions, settings toggle, language picker
// ✅ Toggle has toggled state via Semantics wrapper
// ✅ No colour as sole differentiator — caretaker rows use distinct icons + name text
// ✅ Touch targets separated by ≥ 8px — 16dp gap between all interactive rows
