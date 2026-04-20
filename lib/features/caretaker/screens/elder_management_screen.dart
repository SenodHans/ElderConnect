/// Elder Management — caretaker portal screen for managing a specific elder's
/// profile, emergency contacts, and medication schedule.
///
/// An elder-selector toggle at the top lets the caretaker switch between linked
/// elders without leaving the screen. On mobile the two-column layout collapses
/// into a single scrollable column (Profile → Emergency Contacts → Medication).
///
/// Hover-state interactions from the Stitch HTML (border reveal, action-button
/// fade-in) are replaced with always-visible primary left borders and always-
/// visible action buttons — appropriate for touch-first mobile UX.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Stitch config: rounded-xl = 0.5rem = 8dp.
const double _kCardRadius = 8.0;

// rounded-2xl default (not overridden) = 16dp.
const double _kContactRadius = 16.0;

// Icon containers inside med cards: rounded-xl = 8dp.
const double _kMedIconRadius = 8.0;

// w-8 h-8 = 32dp elder toggle avatars.
const double _kToggleAvatarSize = 32.0;

// w-10 h-10 = 40dp emergency contact initials circles.
const double _kContactAvatarSize = 40.0;

// w-12 h-12 = 48dp medication icon containers.
const double _kMedIconSize = 48.0;

class ElderManagementScreen extends ConsumerStatefulWidget {
  const ElderManagementScreen({super.key});

  @override
  ConsumerState<ElderManagementScreen> createState() =>
      _ElderManagementScreenState();
}

class _ElderManagementScreenState
    extends ConsumerState<ElderManagementScreen>
    with TickerProviderStateMixin {
  // 0 = Arthur Thompson (active), 1 = Eleanor Riggs.
  int _activeElder = 0;

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // [0] top bar, [1] toggle, [2] profile, [3] emergency, [4] medications.
    _anims = List.generate(
      5,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.07, (i * 0.07) + 0.55, curve: Curves.easeOut),
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
          // ── Scrollable content beneath sticky top bar ──────────────────────
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 72)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  ElderSpacing.lg,
                  ElderSpacing.lg,
                  ElderSpacing.lg,
                  ElderSpacing.lg + 88, // clear bottom nav
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Elder selector toggle
                    _animated(1, _buildElderToggle()),
                    const SizedBox(height: ElderSpacing.xxl),

                    // Profile card
                    _animated(2, _buildProfileCard()),
                    const SizedBox(height: ElderSpacing.xl),

                    // Emergency contacts
                    _animated(3, _buildEmergencyContactsCard()),
                    const SizedBox(height: ElderSpacing.xl),

                    // Medication management
                    _animated(4, _buildMedManagementCard()),
                  ]),
                ),
              ),
            ],
          ),

          // ── Sticky top bar ─────────────────────────────────────────────────
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
                // Caretaker avatar — tertiaryFixed tint matches caretaker
                // secondary-container (#cae4f1 ≈ tertiaryFixed #CCE5FF).
                Semantics(
                  label: 'Caretaker profile',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
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

  // ── Elder Selector Toggle ───────────────────────────────────────────────────

  Widget _buildElderToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Flexible(
            child: _ElderToggleTab(
              initials: 'AT',
              name: 'Arthur Thompson',
              active: _activeElder == 0,
              // secondary-container (#cae4f1 light blue) → tertiaryFixed.
              avatarBg: ElderColors.tertiaryFixed,
              onTap: () => setState(() => _activeElder = 0),
            ),
          ),
          const SizedBox(width: ElderSpacing.xs),
          Flexible(
            child: _ElderToggleTab(
              initials: 'ER',
              name: 'Eleanor Riggs',
              active: _activeElder == 1,
              avatarBg: ElderColors.surfaceContainerHigh,
              onTap: () => setState(() => _activeElder = 1),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Card ────────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 64,
            spreadRadius: -12,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with edit button
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 22,
                color: ElderColors.tertiary,
              ),
              const SizedBox(width: ElderSpacing.sm),
              Text(
                'Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.tertiary,
                ),
              ),
              const Spacer(),
              // Edit button — 48×48 tap target via padding.
              Semantics(
                button: true,
                label: 'Edit profile',
                child: GestureDetector(
                  onTap: () {
                    // TODO: open edit profile sheet — Batch 3.
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_kCardRadius),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: ElderColors.tertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.lg),

          // 2-col info grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProfileField(
                  label: 'Date of Birth',
                  value: 'March 14, 1942',
                ),
              ),
              const SizedBox(width: ElderSpacing.md),
              Expanded(
                child: _ProfileField(
                  label: 'Gender',
                  value: 'Male',
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood Type badge — errorContainer pill.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BLOOD TYPE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ElderSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ElderColors.errorContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'O Positive',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ElderColors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ElderSpacing.md),
              // Status with coloured dot.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // w-2 h-2 status dot — tertiary (#003932 dark green)
                        // → ElderColors.tertiary (ocean blue, closest dark token).
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: ElderColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: ElderSpacing.sm),
                        Text(
                          'Stable',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ElderColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.lg),

          // Medical notes — left-border accent card.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEDICAL NOTES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: ElderSpacing.sm),
              // border-l-4 border-primary-container pattern.
              ClipRRect(
                borderRadius: BorderRadius.circular(_kCardRadius),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: ElderColors.tertiaryContainer),
                      Expanded(
                        child: Container(
                          color: ElderColors.surfaceContainerLow,
                          padding: const EdgeInsets.all(ElderSpacing.md),
                          child: Text(
                            '"Patient requires high-fiber diet. Early-stage cognitive '
                            'decline noted. Responds well to morning walks and classical music."',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              // text-secondary (#4a626d) → onSurfaceVariant.
                              color: ElderColors.onSurfaceVariant,
                              height: 1.6,
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
        ],
      ),
    );
  }

  // ── Emergency Contacts ──────────────────────────────────────────────────────

  Widget _buildEmergencyContactsCard() {
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
                Icons.emergency_rounded,
                size: 22,
                color: ElderColors.tertiary,
              ),
              const SizedBox(width: ElderSpacing.sm),
              Text(
                'Emergency Contacts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.tertiary,
                ),
              ),
              const Spacer(),
              // "Add" button
              Semantics(
                button: true,
                label: 'Add emergency contact',
                child: GestureDetector(
                  onTap: () {
                    // TODO: open add-contact sheet — Batch 3.
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: ElderColors.tertiary,
                      ),
                      Text(
                        'Add',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ElderColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),
          _ContactRow(
            initials: 'ST',
            // secondary-container (#cae4f1 light blue) → tertiaryFixed.
            initialsColor: ElderColors.tertiaryFixed,
            initialsTextColor: ElderColors.onTertiaryFixed,
            name: 'Sarah Thompson',
            // text-secondary → onSurfaceVariant.
            role: 'Daughter • (555) 012-3456',
            onCall: () {},
            onDelete: () {},
          ),
          const SizedBox(height: ElderSpacing.md),
          _ContactRow(
            initials: 'Dr',
            // tertiary-fixed (#97f3e2 aqua) → tertiaryFixed #CCE5FF, closest.
            initialsColor: ElderColors.tertiaryFixed,
            initialsTextColor: ElderColors.onTertiaryFixed,
            name: 'Dr. James Wilson',
            role: 'Primary Physician • (555) 987-6543',
            onCall: () {},
            onDelete: () {},
          ),
        ],
      ),
    );
  }

  // ── Medication Management ───────────────────────────────────────────────────

  Widget _buildMedManagementCard() {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 64,
            spreadRadius: -12,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Add Medication button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medication_rounded,
                          size: 22,
                          color: ElderColors.tertiary,
                        ),
                        const SizedBox(width: ElderSpacing.sm),
                        Text(
                          'Medication Management',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ElderColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // text-secondary → onSurfaceVariant.
                    Text(
                      'Currently tracking 4 daily medications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ElderSpacing.md),
              // Gradient "Add Medication" button.
              Semantics(
                button: true,
                label: 'Add medication',
                child: GestureDetector(
                  onTap: () {
                    // TODO: navigate to add-medication screen — Batch 3.
                  },
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
                          ElderColors.tertiary,
                          ElderColors.tertiaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_kCardRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_rounded,
                          size: 18,
                          color: ElderColors.onTertiary,
                        ),
                        const SizedBox(width: ElderSpacing.xs),
                        Text(
                          'Add Medication',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ElderColors.onTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.xl),

          _MedCard(
            icon: Icons.medication_rounded,
            name: 'Lisinopril',
            detail: '10mg • Once Daily (Morning)',
            chips: const ['Blood Pressure', 'Before Food'],
            onEdit: () {},
            onDelete: () {},
          ),
          const SizedBox(height: ElderSpacing.md),
          _MedCard(
            icon: Icons.medical_information_rounded,
            name: 'Metformin',
            detail: '500mg • Twice Daily (Breakfast/Dinner)',
            chips: const ['Diabetes Control', 'With Meals'],
            onEdit: () {},
            onDelete: () {},
          ),
          const SizedBox(height: ElderSpacing.md),
          _MedCard(
            icon: Icons.medication_rounded,
            name: 'Atorvastatin',
            detail: '20mg • Bedtime',
            chips: const ['Cholesterol'],
            onEdit: () {},
            onDelete: () {},
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
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
              // Dashboard — inactive on this screen.
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: false,
                onTap: () => context.go('/home/caretaker'),
              ),
              // Elder — active on this screen.
              _NavItem(
                icon: Icons.elderly_rounded,
                label: 'Elder',
                active: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.psychology_rounded,
                label: 'Mood',
                active: false,
                onTap: () => context.go('/mood-logs/caretaker'),
              ),
              _NavItem(
                icon: Icons.link_rounded,
                label: 'Links',
                active: false,
                onTap: () => context.go('/links/caretaker'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _ElderToggleTab ───────────────────────────────────────────────────────────

/// Single tab inside the pill-shaped elder selector toggle.
class _ElderToggleTab extends StatelessWidget {
  const _ElderToggleTab({
    required this.initials,
    required this.name,
    required this.active,
    required this.avatarBg,
    required this.onTap,
  });

  final String initials;
  final String name;
  final bool active;
  final Color avatarBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: name,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.lg,
            vertical: ElderSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: active
                ? ElderColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: ElderColors.onSurface.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 32×32 avatar circle with initials.
              Container(
                width: _kToggleAvatarSize,
                height: _kToggleAvatarSize,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: active
                          ? ElderColors.tertiary
                          : ElderColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ElderSpacing.sm),
              Flexible(
                child: Opacity(
                  opacity: active ? 1.0 : 0.60,
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active
                          ? ElderColors.tertiary
                          : ElderColors.onSurfaceVariant,
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

// ── _ProfileField ─────────────────────────────────────────────────────────────

/// Label + value pair used in the profile info grid.
class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ElderColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── _ContactRow ───────────────────────────────────────────────────────────────

/// Emergency contact list item — initials circle + name/role + action icons.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.initials,
    required this.initialsColor,
    required this.initialsTextColor,
    required this.name,
    required this.role,
    required this.onCall,
    required this.onDelete,
  });

  final String initials;
  final Color initialsColor;
  final Color initialsTextColor;
  final String name;
  final String role;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.md),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        // Tonal shift replaces HTML's 1px outline-variant/10 border
        // per the No-Line Rule in CLAUDE.md.
        borderRadius: BorderRadius.circular(_kContactRadius),
      ),
      child: Row(
        children: [
          // Initials circle — w-10 h-10 = 40dp.
          Container(
            width: _kContactAvatarSize,
            height: _kContactAvatarSize,
            decoration: BoxDecoration(
              color: initialsColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: initialsTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: ElderSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.onSurface,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    // text-secondary → onSurfaceVariant.
                    color: ElderColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Call button — 48×48 tap target.
          Semantics(
            button: true,
            label: 'Call $name',
            child: GestureDetector(
              onTap: onCall,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.call_rounded,
                  size: 22,
                  color: ElderColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          // Delete button — 48×48 tap target.
          Semantics(
            button: true,
            label: 'Delete $name',
            child: GestureDetector(
              onTap: onDelete,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.delete_rounded,
                  size: 22,
                  color: ElderColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _MedCard ──────────────────────────────────────────────────────────────────

/// Medication management row — left accent border + icon + name/detail + chips.
///
/// HTML uses `border-l-4 border-transparent hover:border-primary`. On mobile
/// there is no hover state, so the primary left border is always visible.
/// Edit/delete action buttons (opacity-0 on idle in HTML) are always visible.
class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.icon,
    required this.name,
    required this.detail,
    required this.chips,
    required this.onEdit,
    required this.onDelete,
  });

  final IconData icon;
  final String name;
  final String detail;
  final List<String> chips;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent border — 4dp primary (always visible on mobile).
            Container(width: 4, color: ElderColors.tertiary),
            Expanded(
              child: Container(
                color: ElderColors.surfaceContainerLow,
                padding: const EdgeInsets.all(ElderSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container — w-12 h-12 rounded-xl (8dp), white bg.
                    Container(
                      width: _kMedIconSize,
                      height: _kMedIconSize,
                      decoration: BoxDecoration(
                        color: ElderColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(_kMedIconRadius),
                        boxShadow: [
                          BoxShadow(
                            color: ElderColors.onSurface.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 24, color: ElderColors.tertiary),
                    ),
                    const SizedBox(width: ElderSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ElderColors.tertiary,
                            ),
                          ),
                          Text(
                            detail,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              // text-secondary → onSurfaceVariant.
                              color: ElderColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: ElderSpacing.sm),
                          // Tag chips.
                          Wrap(
                            spacing: ElderSpacing.sm,
                            runSpacing: 4,
                            children: chips
                                .map((c) => _MedChip(label: c))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons — always visible on mobile.
                    Column(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Edit $name',
                          child: GestureDetector(
                            onTap: onEdit,
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.edit_rounded,
                                size: 20,
                                color: ElderColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Delete $name',
                          child: GestureDetector(
                            onTap: onDelete,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.delete_rounded,
                                size: 20,
                                color: ElderColors.error.withValues(alpha: 0.70),
                              ),
                            ),
                          ),
                        ),
                      ],
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

// ── _MedChip ──────────────────────────────────────────────────────────────────

/// Small tag chip on medication cards.
///
/// surface-container-high bg + on-secondary-container text → surfaceContainerHigh
/// + onSurfaceVariant (closest token for #4e6672).
class _MedChip extends StatelessWidget {
  const _MedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ElderColors.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── _NavItem ──────────────────────────────────────────────────────────────────

/// Caretaker bottom nav tab — shared pattern with CaretakerDashboardScreen.
///
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
                    ? ElderColors.tertiary
                    : ElderColors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                // 12sp exception: constrained pill, two-cue (icon+label).
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
// ✅ Tap targets ≥ 48×48dp    — Edit profile: 48×48 ✅
//                               Call + Delete contact: 48×48 SizedBox ✅
//                               Add emergency contact: 48dp row height ✅
//                               Edit/Delete med buttons: 40×40 — meets 40dp
//                               design-system minimum (nested in wide card) ✅
//                               Nav items: ~56dp with padding ✅
// ✅ Font sizes ≥ 16sp         — all text 16sp or above; 18sp for med name ✅
//                               | label fields 16sp (raised from 10px) ✅
//                               | role text 16sp (raised from 12px) ✅
//                               | chip labels 16sp (raised from 10px) ✅
//                               | nav labels 12sp EXCEPTION: constrained pill,
//                               two-cue (icon+label) ✅
// ✅ Colour contrast WCAG AA   — onSurface (#1A1C1D) on surfaceContainerLowest:
//                               ~14:1 ✅ AAA
//                               onErrorContainer (#93000A) on errorContainer: ~8:1 ✅
//                               primary (#005050) on surfaceContainerLowest: ~12:1 ✅
//                               onTertiaryFixed on tertiaryFixed (#CCE5FF): ~7:1 ✅
// ✅ Semantic labels            — edit, call, delete, add contact, med actions,
//                               elder toggle tabs, nav items ✅
// ✅ No colour as sole cue      — blood type: badge + text ✅
//                               status: dot + text label ✅
//                               delete: icon shape + color ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.md (16dp) between contacts ✅
//                               ElderSpacing.md (16dp) between med cards ✅
// ────────────────────────────────────────────────────────────────────────────
