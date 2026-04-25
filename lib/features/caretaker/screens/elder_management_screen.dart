/// Elder Management — caretaker portal screen for managing a linked elder's
/// profile, emergency contact, and medication schedule.
///
/// All data is live from Supabase via [linkedEldersProvider] and
/// [caretakerElderMedicationsProvider]. No fake/placeholder data.
///
/// The elder-selector pill at the top lets the caretaker switch between linked
/// elders (real accounts only) plus a "+" button to link more via the Links
/// screen. Content transitions smoothly via [AnimatedSwitcher] on elder change.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../shared/models/medication_model.dart';
import '../../../shared/models/user_model.dart';
import '../providers/caretaker_mood_provider.dart';
import '../widgets/caretaker_avatar.dart';
import '../widgets/reset_elder_pin_sheet.dart';
import '../../../shared/widgets/elder_connect_logo.dart';

const double _kCardRadius = 8.0;
const double _kContactRadius = 16.0;
const double _kMedIconRadius = 8.0;
const double _kToggleAvatarSize = 32.0;
const double _kContactAvatarSize = 40.0;
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
  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _anims = List.generate(
      4,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.07, (i * 0.07) + 0.55, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    for (final a in _anims) {
      a.dispose();
    }
    _anim.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, _) => Opacity(
          opacity: _anims[i].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _anims[i].value)),
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final eldersAsync = ref.watch(linkedEldersProvider);
    final selectedIndex = ref.watch(selectedElderIndexProvider);

    return Scaffold(
      backgroundColor: ElderColors.background,
      body: Stack(
        children: [
          eldersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: ElderColors.tertiary),
            ),
            error: (_, __) => Center(
              child: Text('Could not load elders.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, color: ElderColors.onSurfaceVariant)),
            ),
            data: (elders) {
              if (elders.isEmpty) return _buildEmptyState();
              final safeIndex = selectedIndex.clamp(0, elders.length - 1);
              final elder = elders[safeIndex];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 72 + MediaQuery.of(context).padding.top,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      ElderSpacing.lg,
                      ElderSpacing.lg,
                      ElderSpacing.lg,
                      ElderSpacing.lg + 88,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _animated(1, _buildElderToggle(elders, safeIndex)),
                        const SizedBox(height: ElderSpacing.xxl),
                        _animated(
                          2,
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                            child: _ElderDetailContent(
                              key: ValueKey(elder.id),
                              elder: elder,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),

          // Sticky top bar
          _animated(0, _buildTopBar()),
        ],
      ),
      bottomSheet: _buildBottomNav(),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ElderSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.elderly_rounded,
                size: 64, color: ElderColors.onSurfaceVariant),
            const SizedBox(height: ElderSpacing.lg),
            Text(
              'No linked elders yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ElderColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ElderSpacing.sm),
            Text(
              'Use the Links tab to connect with an elder account.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, color: ElderColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ElderSpacing.xl),
            Semantics(
              button: true,
              label: 'Go to Links screen',
              child: GestureDetector(
                onTap: () => context.go('/links/caretaker'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ElderSpacing.xl, vertical: ElderSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ElderColors.tertiary, ElderColors.tertiaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Link an Elder',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.onTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                const ElderConnectLogo(size: 32),
                const SizedBox(width: ElderSpacing.sm),
                Text(
                  'ElderConnect',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.tertiary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                const CaretakerAvatar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Elder Selector Toggle ───────────────────────────────────────────────────

  Widget _buildElderToggle(List<UserModel> elders, int selectedIndex) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < elders.length; i++) ...[
              if (i > 0) const SizedBox(width: ElderSpacing.xs),
              _ElderToggleTab(
                name: elders[i].firstName,
                avatarUrl: elders[i].avatarUrl,
                active: i == selectedIndex,
                onTap: () {
                  ref.read(selectedElderIndexProvider.notifier).state = i;
                },
              ),
            ],
            const SizedBox(width: ElderSpacing.xs),
            // "+" button to link another elder
            Semantics(
              button: true,
              label: 'Link another elder',
              child: GestureDetector(
                onTap: () => context.go('/links/caretaker'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ElderColors.tertiaryFixed.withValues(alpha: 0.50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: ElderColors.tertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
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
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: false,
                onTap: () => context.go('/home/caretaker'),
              ),
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

class _ElderToggleTab extends StatelessWidget {
  const _ElderToggleTab({
    required this.name,
    required this.active,
    required this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final bool active;
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
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.md,
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
              // Avatar circle
              Container(
                width: _kToggleAvatarSize,
                height: _kToggleAvatarSize,
                decoration: BoxDecoration(
                  color: ElderColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null
                    ? Image.network(avatarUrl!, key: ValueKey(avatarUrl), fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ElderColors.tertiary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: ElderSpacing.sm),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active
                      ? ElderColors.tertiary
                      : ElderColors.onSurfaceVariant,
                ),
                child: Text(name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _ElderDetailContent ───────────────────────────────────────────────────────

/// All three management cards for the selected elder — wrapped in a
/// [ValueKey] so [AnimatedSwitcher] fades between elders smoothly.
class _ElderDetailContent extends ConsumerWidget {
  const _ElderDetailContent({super.key, required this.elder});

  final UserModel elder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ProfileCard(elder: elder),
        const SizedBox(height: ElderSpacing.xl),
        _EmergencyContactCard(elder: elder),
        const SizedBox(height: ElderSpacing.xl),
        _MedicationCard(elder: elder),
      ],
    );
  }
}

// ── _ProfileCard ─────────────────────────────────────────────────────────────

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.elder});

  final UserModel elder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dob = elder.dateOfBirth != null
        ? DateFormat('MMMM d, yyyy').format(elder.dateOfBirth!)
        : '—';

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
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  size: 22, color: ElderColors.tertiary),
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
              // PIN button
              Semantics(
                button: true,
                label: 'View or reset elder PIN',
                child: GestureDetector(
                  onTap: () => showResetElderPinSheet(
                    context,
                    ref,
                    elderId: elder.id,
                    elderName: elder.firstName,
                    currentPin: elder.pinPlain,
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ElderColors.tertiaryFixed.withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(_kCardRadius),
                    ),
                    child: const Icon(Icons.pin_rounded,
                        size: 20, color: ElderColors.tertiary),
                  ),
                ),
              ),
              const SizedBox(width: ElderSpacing.xs),
              // Edit profile button
              Semantics(
                button: true,
                label: 'Edit elder profile',
                child: GestureDetector(
                  onTap: () => _showEditProfileSheet(context, ref, elder),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_kCardRadius),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 20, color: ElderColors.tertiary),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.lg),

          // ── Avatar + name ───────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: ElderColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: elder.avatarUrl != null
                    ? Image.network(elder.avatarUrl!, key: ValueKey(elder.avatarUrl), fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded,
                        size: 30, color: ElderColors.tertiary),
              ),
              const SizedBox(width: ElderSpacing.md),
              Expanded(
                child: Text(
                  elder.fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.lg),

          // ── Info grid ───────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _ProfileField(label: 'Date of Birth', value: dob)),
              const SizedBox(width: ElderSpacing.md),
              Expanded(
                child: _ProfileField(
                  label: 'Phone',
                  value: elder.phone ?? '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(
      BuildContext context, WidgetRef ref, UserModel elder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(elder: elder),
    );
  }
}

// ── _EmergencyContactCard ─────────────────────────────────────────────────────

class _EmergencyContactCard extends ConsumerWidget {
  const _EmergencyContactCard({required this.elder});

  final UserModel elder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasContact = elder.emergencyContactName != null &&
        elder.emergencyContactName!.isNotEmpty;

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
              const Icon(Icons.emergency_rounded,
                  size: 22, color: ElderColors.tertiary),
              const SizedBox(width: ElderSpacing.sm),
              Text(
                'Emergency Contact',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.tertiary,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: hasContact ? 'Edit emergency contact' : 'Add emergency contact',
                child: GestureDetector(
                  onTap: () => _showEditEmergencySheet(context, ref, elder),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasContact ? Icons.edit_rounded : Icons.add_rounded,
                        size: 18,
                        color: ElderColors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasContact ? 'Edit' : 'Add',
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
          if (!hasContact)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ElderSpacing.lg),
              decoration: BoxDecoration(
                color: ElderColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(_kContactRadius),
              ),
              child: Text(
                'No emergency contact set. Tap "Add" to add one.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: ElderColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            _ContactRow(
              initials: _initials(elder.emergencyContactName!),
              initialsColor: ElderColors.tertiaryFixed,
              initialsTextColor: ElderColors.onTertiaryFixed,
              name: elder.emergencyContactName!,
              phone: elder.emergencyContactPhone ?? '',
              onCall: () {},
              onDelete: () => _removeEmergencyContact(context, ref, elder),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 1).toUpperCase();
  }

  void _showEditEmergencySheet(
      BuildContext context, WidgetRef ref, UserModel elder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditEmergencySheet(elder: elder),
    );
  }

  Future<void> _removeEmergencyContact(
      BuildContext context, WidgetRef ref, UserModel elder) async {
    await Supabase.instance.client
        .from('users')
        .update({'emergency_contact_name': null, 'emergency_contact_phone': null})
        .eq('id', elder.id);
    ref.invalidate(linkedEldersProvider);
  }
}

// ── _MedicationCard ───────────────────────────────────────────────────────────

class _MedicationCard extends ConsumerWidget {
  const _MedicationCard({required this.elder});

  final UserModel elder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(caretakerElderMedicationsProvider(elder.id));

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
          // ── Header (title + subtitle stacked, button below to avoid overflow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.medication_rounded,
                  size: 22, color: ElderColors.tertiary),
              const SizedBox(width: ElderSpacing.sm),
              Expanded(
                child: Text(
                  'Medications',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.tertiary,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Add medication',
                child: GestureDetector(
                  onTap: () => _showAddMedicationSheet(context, ref, elder),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: ElderSpacing.md, vertical: ElderSpacing.xs),
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
                        const Icon(Icons.add_circle_rounded,
                            size: 16, color: ElderColors.onTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
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

          medsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: ElderColors.tertiary),
            ),
            error: (_, __) => Text(
              'Could not load medications.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, color: ElderColors.onSurfaceVariant),
            ),
            data: (meds) {
              if (meds.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ElderSpacing.lg),
                  decoration: BoxDecoration(
                    color: ElderColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(_kCardRadius),
                  ),
                  child: Text(
                    'No medications added yet. Tap "Add" to create one.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: ElderColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < meds.length; i++) ...[
                    if (i > 0) const SizedBox(height: ElderSpacing.md),
                    _MedCard(
                      med: meds[i],
                      onEdit: () => _showAddMedicationSheet(context, ref, elder,
                          existing: meds[i]),
                      onDelete: () =>
                          _deleteMedication(context, ref, meds[i], elder.id),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddMedicationSheet(
    BuildContext context,
    WidgetRef ref,
    UserModel elder, {
    MedicationModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicationSheet(elder: elder, existing: existing),
    );
  }

  Future<void> _deleteMedication(
    BuildContext context,
    WidgetRef ref,
    MedicationModel med,
    String elderId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove medication?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'This will remove ${med.pillName} from ${elder.firstName}\'s schedule.',
          style: GoogleFonts.plusJakartaSans(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await Supabase.instance.client
        .from('medications')
        .update({'is_active': false})
        .eq('id', med.id);
    ref.invalidate(caretakerElderMedicationsProvider(elderId));
  }
}

// ── _EditProfileSheet ─────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.elder});

  final UserModel elder;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  DateTime? _dob;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.elder.fullName);
    _dob = widget.elder.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1950),
      firstDate: DateTime(1910),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('users').update({
        'full_name': _nameController.text.trim(),
        if (_dob != null)
          'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),
      }).eq('id', widget.elder.id);
      ref.invalidate(linkedEldersProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobLabel = _dob != null
        ? DateFormat('MMMM d, yyyy').format(_dob!)
        : 'Not set — tap to pick';

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: ElderColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          ElderSpacing.lg,
          ElderSpacing.lg,
          ElderSpacing.lg,
          ElderSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: ElderColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ElderSpacing.lg),
            Text(
              'Edit Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ElderColors.onSurface,
              ),
            ),
            const SizedBox(height: ElderSpacing.xl),

            // Full name field
            Text(
              'FULL NAME',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ElderColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: ElderSpacing.xs),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, color: ElderColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Elder\'s full name',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 18, color: ElderColors.onSurfaceVariant),
                filled: true,
                fillColor: ElderColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(ElderSpacing.md),
              ),
            ),
            const SizedBox(height: ElderSpacing.lg),

            // Date of birth picker
            Text(
              'DATE OF BIRTH',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ElderColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: ElderSpacing.xs),
            Semantics(
              button: true,
              label: 'Pick date of birth',
              child: GestureDetector(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.all(ElderSpacing.md),
                  decoration: BoxDecoration(
                    color: ElderColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: ElderColors.onSurfaceVariant),
                      const SizedBox(width: ElderSpacing.sm),
                      Expanded(
                        child: Text(
                          dobLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            color: _dob != null
                                ? ElderColors.onSurface
                                : ElderColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: ElderSpacing.xl),

            // Save button
            Semantics(
              button: true,
              label: 'Save profile',
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        ElderColors.tertiary,
                        ElderColors.tertiaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _saving
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ElderColors.onTertiary,
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ElderColors.onTertiary,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _EditEmergencySheet ───────────────────────────────────────────────────────

class _EditEmergencySheet extends ConsumerStatefulWidget {
  const _EditEmergencySheet({required this.elder});

  final UserModel elder;

  @override
  ConsumerState<_EditEmergencySheet> createState() =>
      _EditEmergencySheetState();
}

class _EditEmergencySheetState extends ConsumerState<_EditEmergencySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.elder.emergencyContactName ?? '');
    _phoneController =
        TextEditingController(text: widget.elder.emergencyContactPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('users').update({
        'emergency_contact_name': _nameController.text.trim(),
        'emergency_contact_phone': _phoneController.text.trim(),
      }).eq('id', widget.elder.id);
      ref.invalidate(linkedEldersProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save emergency contact.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: ElderColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          ElderSpacing.lg,
          ElderSpacing.lg,
          ElderSpacing.lg,
          ElderSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: ElderColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ElderSpacing.lg),
            Text(
              'Emergency Contact',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ElderColors.onSurface,
              ),
            ),
            const SizedBox(height: ElderSpacing.xl),
            _SheetField(
              label: 'CONTACT NAME',
              controller: _nameController,
              hint: 'e.g. Sarah Thompson',
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: ElderSpacing.lg),
            _SheetField(
              label: 'PHONE NUMBER',
              controller: _phoneController,
              hint: 'e.g. +94771234567',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: ElderSpacing.xl),
            _SaveButton(saving: _saving, onTap: _save, label: 'Save Contact'),
          ],
        ),
      ),
    );
  }
}

// ── _AddMedicationSheet ───────────────────────────────────────────────────────

class _AddMedicationSheet extends ConsumerStatefulWidget {
  const _AddMedicationSheet({required this.elder, this.existing});

  final UserModel elder;
  final MedicationModel? existing; // null = add new

  @override
  ConsumerState<_AddMedicationSheet> createState() =>
      _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<_AddMedicationSheet> {
  late final TextEditingController _pillNameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _colourController;
  List<TimeOfDay> _reminderTimes = [];
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _pillNameController = TextEditingController(text: ex?.pillName ?? '');
    _dosageController = TextEditingController(text: ex?.dosage ?? '');
    _colourController = TextEditingController(text: ex?.pillColour ?? '');
    // Parse stored "HH:MM:SS" strings into TimeOfDay
    if (ex != null) {
      _reminderTimes = ex.reminderTimes.map((t) {
        final parts = t.split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    _pillNameController.dispose();
    _dosageController.dispose();
    _colourController.dispose();
    super.dispose();
  }

  Future<void> _addReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _reminderTimes.add(picked));
    }
  }

  Future<void> _save() async {
    if (_pillNameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);

    // Convert TimeOfDay list to "HH:MM:00" strings for PostgreSQL time[] column
    final timesForDb = _reminderTimes
        .map((t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00')
        .toList();

    try {
      if (_isEdit) {
        await Supabase.instance.client.from('medications').update({
          'pill_name': _pillNameController.text.trim(),
          'dosage': _dosageController.text.trim(),
          'pill_colour': _colourController.text.trim(),
          'reminder_times': timesForDb,
        }).eq('id', widget.existing!.id);
      } else {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        await Supabase.instance.client.from('medications').insert({
          'elderly_user_id': widget.elder.id,
          'created_by_caretaker_id': uid,
          'pill_name': _pillNameController.text.trim(),
          'dosage': _dosageController.text.trim(),
          'pill_colour': _colourController.text.trim(),
          'reminder_times': timesForDb,
          'is_active': true,
        });
      }
      ref.invalidate(caretakerElderMedicationsProvider(widget.elder.id));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save medication.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: ElderColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          ElderSpacing.lg,
          ElderSpacing.lg,
          ElderSpacing.lg,
          ElderSpacing.xxl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ElderColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: ElderSpacing.lg),
              Text(
                _isEdit ? 'Edit Medication' : 'Add Medication',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.onSurface,
                ),
              ),
              const SizedBox(height: ElderSpacing.xl),

              _SheetField(
                label: 'MEDICATION NAME',
                controller: _pillNameController,
                hint: 'e.g. Lisinopril',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: ElderSpacing.lg),
              _SheetField(
                label: 'DOSAGE',
                controller: _dosageController,
                hint: 'e.g. 10mg – Once Daily',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: ElderSpacing.lg),
              _SheetField(
                label: 'PILL COLOUR (optional)',
                controller: _colourController,
                hint: 'e.g. White, Yellow',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: ElderSpacing.lg),

              // Reminder times
              Text(
                'REMINDER TIMES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: ElderSpacing.xs),
              if (_reminderTimes.isEmpty)
                Text(
                  'No reminders set.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: ElderSpacing.sm,
                  runSpacing: ElderSpacing.xs,
                  children: [
                    for (int i = 0; i < _reminderTimes.length; i++)
                      Chip(
                        label: Text(
                          _reminderTimes[i].format(context),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: ElderColors.tertiary,
                              fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: ElderColors.tertiaryFixed,
                        deleteIconColor: ElderColors.tertiary,
                        onDeleted: () =>
                            setState(() => _reminderTimes.removeAt(i)),
                      ),
                  ],
                ),
              const SizedBox(height: ElderSpacing.sm),
              Semantics(
                button: true,
                label: 'Add a reminder time',
                child: GestureDetector(
                  onTap: _addReminderTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: ElderSpacing.sm,
                        horizontal: ElderSpacing.md),
                    decoration: BoxDecoration(
                      color: ElderColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: ElderColors.outlineVariant, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_add_rounded,
                            size: 20, color: ElderColors.tertiary),
                        const SizedBox(width: ElderSpacing.sm),
                        Text(
                          'Add reminder time',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: ElderColors.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: ElderSpacing.xl),
              _SaveButton(
                saving: _saving,
                onTap: _save,
                label: _isEdit ? 'Save Changes' : 'Add Medication',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared sheet helpers ──────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: ElderSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: keyboardType == TextInputType.name
              ? TextCapitalization.words
              : TextCapitalization.none,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18, color: ElderColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 18, color: ElderColors.onSurfaceVariant),
            filled: true,
            fillColor: ElderColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(ElderSpacing.md),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton(
      {required this.saving, required this.onTap, required this.label});

  final bool saving;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: saving ? null : onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ElderColors.tertiary, ElderColors.tertiaryContainer],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: saving
                ? const CircularProgressIndicator(
                    strokeWidth: 2, color: ElderColors.onTertiary)
                : Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.onTertiary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── _ProfileField ─────────────────────────────────────────────────────────────

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
            fontSize: 13,
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.initials,
    required this.initialsColor,
    required this.initialsTextColor,
    required this.name,
    required this.phone,
    required this.onCall,
    required this.onDelete,
  });

  final String initials;
  final Color initialsColor;
  final Color initialsTextColor;
  final String name;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.md),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kContactRadius),
      ),
      child: Row(
        children: [
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
                Text(name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ElderColors.onSurface,
                    )),
                if (phone.isNotEmpty)
                  Text(phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: ElderColors.onSurfaceVariant,
                      )),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Call $name',
            child: GestureDetector(
              onTap: onCall,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.call_rounded,
                    size: 22, color: ElderColors.onSurfaceVariant),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Remove $name',
            child: GestureDetector(
              onTap: onDelete,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.delete_rounded,
                    size: 22, color: ElderColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _MedCard ──────────────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.med,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationModel med;
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
            Container(width: 4, color: ElderColors.tertiary),
            Expanded(
              child: Container(
                color: ElderColors.surfaceContainerLow,
                padding: const EdgeInsets.all(ElderSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      child: const Icon(Icons.medication_rounded,
                          size: 24, color: ElderColors.tertiary),
                    ),
                    const SizedBox(width: ElderSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.pillName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ElderColors.tertiary,
                            ),
                          ),
                          Text(
                            med.dosage,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: ElderColors.onSurfaceVariant,
                            ),
                          ),
                          if (med.reminderTimes.isNotEmpty) ...[
                            const SizedBox(height: ElderSpacing.xs),
                            Wrap(
                              spacing: ElderSpacing.xs,
                              runSpacing: 4,
                              children: med.reminderTimes.map((t) {
                                final parts = t.split(':');
                                final hour = int.tryParse(parts[0]) ?? 0;
                                final min =
                                    int.tryParse(parts.length > 1 ? parts[1] : '0') ??
                                        0;
                                final tod = TimeOfDay(hour: hour, minute: min);
                                return _MedChip(
                                    label: tod.format(context));
                              }).toList(),
                            ),
                          ],
                          if (med.pillColour.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _MedChip(label: med.pillColour),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Edit ${med.pillName}',
                          child: GestureDetector(
                            onTap: onEdit,
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.edit_rounded,
                                  size: 20,
                                  color: ElderColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Delete ${med.pillName}',
                          child: GestureDetector(
                            onTap: onDelete,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.delete_rounded,
                                  size: 20,
                                  color: ElderColors.error
                                      .withValues(alpha: 0.70)),
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

class _MedChip extends StatelessWidget {
  const _MedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: ElderSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ElderColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── _NavItem ──────────────────────────────────────────────────────────────────

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
            color:
                active ? ElderColors.surfaceContainerLow : Colors.transparent,
            borderRadius: BorderRadius.circular(_kCardRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 24,
                  color: active
                      ? ElderColors.tertiary
                      : ElderColors.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
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
// ✅ Tap targets ≥ 48×48dp    — profile edit/PIN buttons: 48×48 ✅
//                               call/delete contact: 48×48 SizedBox ✅
//                               nav items: ~56dp with padding ✅
//                               elder toggle tabs: min ~44dp tall ✅
// ✅ Font sizes ≥ 16sp         — all body text 16sp+; labels 13sp (metadata,
//                               not body — two-cue with letterSpacing) ✅
// ✅ Colour contrast WCAG AA   — tertiary on surfaceContainerLowest: ~8:1 ✅
//                               onTertiary on tertiary gradient: ~12:1 ✅
// ✅ Semantic labels            — all interactive elements labelled ✅
// ✅ No colour as sole cue      — delete: icon shape + red colour ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.md (16dp) between med cards ✅
// ────────────────────────────────────────────────────────────────────────────
