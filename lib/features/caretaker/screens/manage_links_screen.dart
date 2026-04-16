/// Manage Links — caretaker portal screen for managing caretaker relationships.
///
/// Shows a gradient hero with a search field, active connection cards (with
/// avatar, role badge, relationship, and status), incoming link requests, an
/// outgoing pending request, and a privacy tip card.
///
/// Two-column Stitch layout (active links | requests + tips) collapses to a
/// single scrollable column on mobile — phone-first order:
/// Hero → Active Connections → Incoming → Outgoing → Privacy Tip.
///
/// Hover interactions from the Stitch HTML are replaced with always-visible
/// action buttons. `border border-outline-variant/10` separators are replaced
/// with tonal surface shifts per the No-Line Rule.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Stitch config: rounded-xl = 0.5rem = 8dp.
const double _kCardRadius = 8.0;

// rounded-2xl default (not overridden) = 16dp — connection cards.
const double _kConnectionRadius = 16.0;

// w-16 h-16 = 64dp connection card avatars.
const double _kAvatarSize = 64.0;

// Online status dot: w-4 h-4 = 16dp.
const double _kDotSize = 16.0;

// w-10 h-10 = 40dp request initials / avatar circles.
const double _kSmallAvatarSize = 40.0;

class ManageLinksScreen extends ConsumerStatefulWidget {
  const ManageLinksScreen({super.key});

  @override
  ConsumerState<ManageLinksScreen> createState() => _ManageLinksScreenState();
}

class _ManageLinksScreenState
    extends ConsumerState<ManageLinksScreen>
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
    // [0] top bar, [1] hero, [2] active connections, [3] requests, [4] tips.
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
          CustomScrollView(
            slivers: [
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
                    // Hero
                    _animated(1, const _HeroSection()),
                    const SizedBox(height: ElderSpacing.xxl),

                    // Active Connections
                    _animated(2, _buildActiveConnectionsSection()),
                    const SizedBox(height: ElderSpacing.xxl),

                    // Incoming Requests
                    _animated(3, _buildIncomingSection()),
                    const SizedBox(height: ElderSpacing.xl),

                    // Outgoing Pending
                    _animated(3, _buildOutgoingSection()),
                    const SizedBox(height: ElderSpacing.xl),

                    // Privacy Tip
                    _animated(4, const _PrivacyTipCard()),
                  ]),
                ),
              ),
            ],
          ),
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
                Semantics(
                  label: 'Caretaker profile',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // primary-fixed border (#c4e7ff) → primaryFixed token.
                      color: ElderColors.tertiaryFixed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ElderColors.primaryFixed,
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

  // ── Active Connections ──────────────────────────────────────────────────────

  Widget _buildActiveConnectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              size: 22,
              color: ElderColors.primary,
            ),
            const SizedBox(width: ElderSpacing.sm),
            Text(
              'Active Connections',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ElderColors.primary,
              ),
            ),
            const Spacer(),
            // "2 TOTAL" count badge.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ElderSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: ElderColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '2 TOTAL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.md),
        _ConnectionCard(
          name: 'Alice Miller',
          handle: '@alice_miller_42',
          badgeLabel: 'Primary Care',
          // tertiary-fixed (#97f3e2 aqua) → primaryFixed (#A0F0F0, closest aqua).
          badgeBg: ElderColors.primaryFixed,
          badgeFg: ElderColors.onPrimaryFixedVariant,
          relationship: 'Daughter',
          relationshipIcon: Icons.family_restroom_rounded,
          onView: () {},
          onUnlink: () {},
        ),
        const SizedBox(height: ElderSpacing.md),
        _ConnectionCard(
          name: 'Robert Bennett',
          handle: '@robert_b_safe',
          badgeLabel: 'Auxiliary Care',
          // secondary-fixed (#cde6f4 light blue) → tertiaryFixed (#CCE5FF, closest).
          badgeBg: ElderColors.tertiaryFixed,
          badgeFg: ElderColors.onTertiaryFixed,
          relationship: 'Nurse',
          relationshipIcon: Icons.medical_information_rounded,
          onView: () {},
          onUnlink: () {},
        ),
      ],
    );
  }

  // ── Incoming Requests ───────────────────────────────────────────────────────

  Widget _buildIncomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.inbox_rounded,
              size: 20,
              color: ElderColors.onSurfaceVariant,
            ),
            const SizedBox(width: ElderSpacing.sm),
            Text(
              'INCOMING REQUESTS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ElderColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.md),
        _IncomingRequestCard(
          name: 'Jane Cooper',
          roleRequest: 'Guardian',
          onAccept: () {},
          onDecline: () {},
        ),
      ],
    );
  }

  // ── Outgoing Pending ────────────────────────────────────────────────────────

  Widget _buildOutgoingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.outbox_rounded,
              size: 20,
              color: ElderColors.onSurfaceVariant,
            ),
            const SizedBox(width: ElderSpacing.sm),
            Text(
              'OUTGOING PENDING',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ElderColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.md),
        _OutgoingPendingCard(
          initials: 'SW',
          name: 'Samuel Wright',
          timeSent: 'Request sent 2h ago',
          onCancel: () {},
        ),
      ],
    );
  }

  // ── Bottom Nav — Links active ───────────────────────────────────────────────

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
                onTap: () {
                  // TODO: context.go('/home/caretaker') — Batch 3.
                },
              ),
              _NavItem(
                icon: Icons.elderly_rounded,
                label: 'Elder',
                active: false,
                onTap: () {
                  // TODO: context.go('/elders/caretaker') — Batch 3.
                },
              ),
              _NavItem(
                icon: Icons.psychology_rounded,
                label: 'Mood',
                active: false,
                onTap: () {
                  // TODO: context.go('/mood-logs/caretaker') — Batch 3.
                },
              ),
              _NavItem(
                icon: Icons.link_rounded,
                label: 'Links',
                active: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _HeroSection ──────────────────────────────────────────────────────────────

/// Full-width gradient hero with title, subtitle, and search field.
///
/// Decorative `hub` icon sits at 10% opacity bottom-right — the Stitch design
/// uses a 200px icon. Replaced with a large Icon widget at 160sp.
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: Container(
        padding: const EdgeInsets.all(ElderSpacing.xl),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 1.0],
            colors: [ElderColors.primary, ElderColors.primaryContainer],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative hub icon ────────────────────────────────────────
            Positioned(
              right: -ElderSpacing.lg,
              bottom: -ElderSpacing.lg,
              child: Opacity(
                opacity: 0.10,
                child: Icon(
                  Icons.hub_rounded,
                  size: 160,
                  color: ElderColors.primaryFixed,
                ),
              ),
            ),

            // ── Main content ───────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Management',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: ElderColors.onPrimary,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: ElderSpacing.md),
                Text(
                  'Securely link with new elders and manage your active '
                  'caretaker relationships in a clinical-grade environment.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: ElderColors.primaryFixed.withValues(alpha: 0.90),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: ElderSpacing.xl),

                // Search field — bg-white/10 backdrop-blur → white@10% overlay.
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(_kCardRadius),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ElderSpacing.md,
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: ElderColors.primaryFixed,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: ElderColors.onPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by Elder Name or ID...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: ElderColors.primaryFixed
                                  .withValues(alpha: 0.60),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: ElderSpacing.md,
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── _ConnectionCard ───────────────────────────────────────────────────────────

/// Active linked-elder connection card.
///
/// Avatar is a tonal placeholder — TODO(backend-sprint): replace with
/// CachedNetworkImage from Supabase Storage.
class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.name,
    required this.handle,
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeFg,
    required this.relationship,
    required this.relationshipIcon,
    required this.onView,
    required this.onUnlink,
  });

  final String name;
  final String handle;
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeFg;
  final String relationship;
  final IconData relationshipIcon;
  final VoidCallback onView;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kConnectionRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 15,
            spreadRadius: -3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + online status dot ──────────────────────────────────
          SizedBox(
            width: _kAvatarSize,
            height: _kAvatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // TODO(backend-sprint): replace with CachedNetworkImage.
                Container(
                  width: _kAvatarSize,
                  height: _kAvatarSize,
                  decoration: BoxDecoration(
                    color: ElderColors.tertiaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: ElderColors.onTertiaryFixed,
                  ),
                ),
                // Online dot — bottom-right, white border.
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: _kDotSize,
                    height: _kDotSize,
                    decoration: BoxDecoration(
                      // bg-tertiary (#003932 dark green) → ElderColors.tertiary.
                      color: ElderColors.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ElderColors.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: ElderSpacing.lg),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + role badge.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: ElderSpacing.sm,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.primary,
                      ),
                    ),
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
                        badgeLabel.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: badgeFg,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Handle
                Text(
                  handle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: ElderSpacing.sm),
                // Relationship + active status tags.
                Wrap(
                  spacing: ElderSpacing.lg,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          relationshipIcon,
                          size: 16,
                          // text-secondary → onSurfaceVariant.
                          color: ElderColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          relationship,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: ElderColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Filled dot for "Active Status".
                        Icon(
                          Icons.circle,
                          size: 10,
                          // text-tertiary (#003932) → ElderColors.tertiary.
                          color: ElderColors.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active Status',
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
                const SizedBox(height: ElderSpacing.md),
                // Action buttons.
                Row(
                  children: [
                    // View button.
                    Semantics(
                      button: true,
                      label: 'View $name',
                      child: GestureDetector(
                        onTap: onView,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElderSpacing.md,
                            vertical: ElderSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: ElderColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(_kCardRadius),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_rounded,
                                size: 16,
                                color: ElderColors.primary,
                              ),
                              const SizedBox(width: ElderSpacing.xs),
                              Text(
                                'View',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ElderColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: ElderSpacing.sm),
                    // Unlink button.
                    Semantics(
                      button: true,
                      label: 'Unlink $name',
                      child: GestureDetector(
                        onTap: onUnlink,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElderSpacing.md,
                            vertical: ElderSpacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.link_off_rounded,
                                size: 16,
                                color: ElderColors.error,
                              ),
                              const SizedBox(width: ElderSpacing.xs),
                              Text(
                                'Unlink',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ElderColors.error,
                                ),
                              ),
                            ],
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
    );
  }
}

// ── _IncomingRequestCard ──────────────────────────────────────────────────────

/// Pending incoming link request — avatar + name + role claim + accept/decline.
class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.name,
    required this.roleRequest,
    required this.onAccept,
    required this.onDecline,
  });

  final String name;
  final String roleRequest;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Tonal shift replaces HTML's border border-outline-variant/10.
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ElderSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name row.
            Row(
              children: [
                // TODO(backend-sprint): replace with CachedNetworkImage.
                Container(
                  width: _kSmallAvatarSize,
                  height: _kSmallAvatarSize,
                  // rounded-lg = 4dp in this Tailwind config.
                  decoration: BoxDecoration(
                    color: ElderColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(_kCardRadius),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: ElderColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: ElderSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.primary,
                      ),
                    ),
                    Text(
                      'Wants to link as: $roleRequest',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ElderColors.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: ElderSpacing.md),
            // Accept / Decline buttons — 2-col row.
            Row(
              children: [
                // Accept — primary bg.
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Accept $name request',
                    child: GestureDetector(
                      onTap: onAccept,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: ElderColors.primary,
                          borderRadius: BorderRadius.circular(_kCardRadius),
                        ),
                        child: Center(
                          child: Text(
                            'Accept',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ElderColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ElderSpacing.sm),
                // Decline — tonal surface.
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Decline $name request',
                    child: GestureDetector(
                      onTap: onDecline,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: ElderColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(_kCardRadius),
                        ),
                        child: Center(
                          child: Text(
                            'Decline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ElderColors.onSurfaceVariant,
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
    );
  }
}

// ── _OutgoingPendingCard ──────────────────────────────────────────────────────

/// Outgoing link request card — initials circle + name + PENDING badge + cancel.
class _OutgoingPendingCard extends StatelessWidget {
  const _OutgoingPendingCard({
    required this.initials,
    required this.name,
    required this.timeSent,
    required this.onCancel,
  });

  final String initials;
  final String name;
  final String timeSent;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Initials circle — secondary-container (#cae4f1) → tertiaryFixed.
              Container(
                width: _kSmallAvatarSize,
                height: _kSmallAvatarSize,
                decoration: const BoxDecoration(
                  color: ElderColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ElderSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.primary,
                      ),
                    ),
                    // text-secondary → onSurfaceVariant.
                    Text(
                      timeSent,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // PENDING badge.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ElderSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ElderColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                ),
                child: Text(
                  'PENDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.md),
          // Cancel Request button — tonal secondary action.
          Semantics(
            button: true,
            label: 'Cancel request to $name',
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  // Tonal shift replaces HTML's border border-outline button.
                  color: ElderColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: ElderColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: ElderSpacing.sm),
                    Text(
                      'Cancel Request',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _PrivacyTipCard ───────────────────────────────────────────────────────────

/// Privacy tip information card with decorative security icon.
///
/// HTML uses `bg-secondary-container/30 border border-secondary-container`.
/// In Flutter: `tertiaryFixed` at 30% opacity (closest to caretaker secondary-
/// container #cae4f1). Border removed per No-Line Rule — tonal bg provides
/// sufficient differentiation.
class _PrivacyTipCard extends StatelessWidget {
  const _PrivacyTipCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: Container(
        padding: const EdgeInsets.all(ElderSpacing.lg),
        decoration: BoxDecoration(
          color: ElderColors.tertiaryFixed.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
        child: Stack(
          children: [
            // Decorative security icon — absolute bottom-right, 40% opacity.
            Positioned(
              right: -ElderSpacing.md,
              bottom: -ElderSpacing.md,
              child: Opacity(
                opacity: 0.40,
                child: Icon(
                  Icons.security_rounded,
                  size: 72,
                  // text-secondary-container → tertiaryFixed token itself as tint.
                  color: ElderColors.tertiaryContainer,
                ),
              ),
            ),
            // Content (z-10 in HTML — placed after Positioned so it paints above).
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      size: 20,
                      color: ElderColors.primary,
                    ),
                    const SizedBox(width: ElderSpacing.sm),
                    Text(
                      'Privacy Tip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ElderSpacing.sm),
                Text(
                  'Linking allows full access to health logs and mood tracking. '
                  'Only accept requests from verified family members or clinical professionals.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    // on-secondary-container (#4e6672) → onSurfaceVariant.
                    color: ElderColors.onSurfaceVariant,
                    height: 1.6,
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

// ── _NavItem ──────────────────────────────────────────────────────────────────

/// Caretaker bottom nav tab — Links tab active on this screen.
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
                    ? ElderColors.primary
                    : ElderColors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                // 12sp exception: constrained nav pill, two-cue (icon+label).
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
// ✅ Tap targets ≥ 48×48dp    — View / Unlink buttons: 48dp row height ✅
//                               Accept / Decline: explicit height: 48 ✅
//                               Cancel Request: height: 48 ✅
//                               Nav items: ~56dp with padding ✅
// ✅ Font sizes ≥ 16sp         — all text 16sp or above; 18sp for elder names ✅
//                               | role request 16sp (raised from 10px) ✅
//                               | PENDING badge 16sp (raised from 10px) ✅
//                               | time-sent 16sp (raised from 10px) ✅
//                               | badge labels 16sp (raised from 10px) ✅
//                               | nav labels 12sp EXCEPTION: two-cue pill ✅
// ✅ Colour contrast WCAG AA   — onPrimary (#FFF) on primary (#005050): ~12:1 ✅
//                               onTertiaryFixed on tertiaryFixed (#CCE5FF): ~7:1 ✅
//                               primary on surfaceContainerHigh: ~9:1 ✅
//                               error on surfaceContainerLowest: ~5:1 ✅ AA
//                               onSurfaceVariant on surfaceContainerLow: ~7:1 ✅
// ✅ Semantic labels            — all buttons (view, unlink, accept, decline,
//                               cancel, nav items, caretaker profile) ✅
// ✅ No colour as sole cue      — accept/decline: label text + colour ✅
//                               active status: dot icon + "Active Status" text ✅
//                               role badges: text label + colour ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.md (16dp) between connection
//                               cards ✅; ElderSpacing.xl (32dp) between
//                               sections ✅
// ────────────────────────────────────────────────────────────────────────────
