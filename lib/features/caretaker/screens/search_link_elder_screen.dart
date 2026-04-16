/// Search / Link Elder — caretaker portal screen for sending a link request.
///
/// The caretaker enters an elder's username, selects their relationship type,
/// and sends a link request. Once accepted, they gain access to that elder's
/// health logs and activity alerts.
///
/// Two-column Stitch layout (form | info cards) collapses on mobile to:
/// Editorial Header → Form Card → Privacy & Access info → Accent card →
/// Recently Connected.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Stitch config: rounded-xl = 0.5rem = 8dp.
const double _kCardRadius = 8.0;

// Accent image card height: h-48 = 192dp.
const double _kAccentCardHeight = 192.0;

// Overlapping avatar stack — 32dp each, 16dp overlap per subsequent item.
const double _kStackAvatarSize = 32.0;
const double _kStackAvatarOverlap = 16.0;

const List<String> _kRelationshipOptions = [
  'Son',
  'Daughter',
  'Spouse',
  'Friend',
  'Professional Carer',
  'Other',
];

class SearchLinkElderScreen extends ConsumerStatefulWidget {
  const SearchLinkElderScreen({super.key});

  @override
  ConsumerState<SearchLinkElderScreen> createState() =>
      _SearchLinkElderScreenState();
}

class _SearchLinkElderScreenState
    extends ConsumerState<SearchLinkElderScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  String? _selectedRelationship;

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    // [0] top bar, [1] editorial header, [2] form, [3] side cards.
    _anims = List.generate(
      4,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.09, (i * 0.09) + 0.55, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    for (final a in _anims) { a.dispose(); }
    _anim.dispose();
    _usernameController.dispose();
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
                  ElderSpacing.xl,
                  ElderSpacing.lg,
                  ElderSpacing.lg + 88,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Editorial header
                    _animated(1, _buildEditorialHeader()),
                    const SizedBox(height: ElderSpacing.xxl),

                    // Main form card
                    _animated(2, _buildFormCard()),
                    const SizedBox(height: ElderSpacing.xl),

                    // Side cards stacked on mobile
                    _animated(3, _buildPrivacyInfoCard()),
                    const SizedBox(height: ElderSpacing.lg),
                    _animated(3, _buildAccentCard()),
                    const SizedBox(height: ElderSpacing.lg),
                    _animated(3, _buildRecentlyConnectedCard()),
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
                      color: ElderColors.tertiaryFixed,
                      shape: BoxShape.circle,
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

  // ── Editorial Header ────────────────────────────────────────────────────────

  Widget _buildEditorialHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "CONNECTION PORTAL" eyebrow label — text-secondary → onSurfaceVariant.
        Text(
          'CONNECTION PORTAL',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: ElderSpacing.sm),
        Text(
          'Link with an Elder',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: ElderColors.primary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: ElderSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'Enter the username of the person you wish to care for. Once they '
            'accept your request, you will gain access to their health logs '
            'and activity alerts.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: ElderColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ── Main Form Card ──────────────────────────────────────────────────────────

  Widget _buildFormCard() {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Username field ───────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  "ELDER'S USERNAME",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: ElderSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: ElderColors.surfaceContainerLow,
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
                        color: ElderColors.outline,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          color: ElderColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. robert_chen_45',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            color: ElderColors.outline
                                .withValues(alpha: 0.50),
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
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Tip: Usernames are case-sensitive.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    // text-secondary/60 → onSurfaceVariant at 60% opacity.
                    color: ElderColors.onSurfaceVariant
                        .withValues(alpha: 0.60),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.xl),

          // ── Relationship dropdown ─────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'YOUR RELATIONSHIP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: ElderSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: ElderColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: ElderSpacing.md,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRelationship,
                    hint: Text(
                      'Select relationship...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        color: ElderColors.outline.withValues(alpha: 0.50),
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      color: ElderColors.onSurface,
                    ),
                    dropdownColor: ElderColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(_kCardRadius),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: ElderColors.outline,
                    ),
                    onChanged: (v) => setState(() => _selectedRelationship = v),
                    items: _kRelationshipOptions
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                color: ElderColors.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.xl),

          // ── Send Request button — gradient ────────────────────────────────
          Semantics(
            button: true,
            label: 'Send link request',
            child: GestureDetector(
              onTap: () {
                // TODO: dispatch link request to Supabase — backend sprint.
              },
              child: Container(
                height: 56,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Send Request',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: ElderSpacing.sm),
                    const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: ElderColors.onPrimary,
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

  // ── Privacy & Access info card ──────────────────────────────────────────────

  Widget _buildPrivacyInfoCard() {
    // border-l-4 border-primary → established ClipRRect + IntrinsicHeight pattern.
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: ElderColors.primary),
            Expanded(
              child: Container(
                color: ElderColors.surfaceContainerLow,
                padding: const EdgeInsets.all(ElderSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          size: 18,
                          color: ElderColors.primary,
                        ),
                        const SizedBox(width: ElderSpacing.sm),
                        Text(
                          'Privacy & Access',
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
                      'Linking allows you to view medication schedules, mood '
                      'tracking, and emergency alerts. Both parties must agree '
                      'before data is shared.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: ElderColors.onSurfaceVariant,
                        height: 1.6,
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

  // ── Visual Accent Card ──────────────────────────────────────────────────────

  Widget _buildAccentCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: SizedBox(
        height: _kAccentCardHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // TODO(backend-sprint): replace with CachedNetworkImage.
            Container(color: ElderColors.surfaceContainerLow),

            // Gradient overlay — from-primary/80 to-transparent (bottom up).
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      ElderColors.primary.withValues(alpha: 0.80),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Text overlay — bottom of card.
            Positioned(
              left: ElderSpacing.lg,
              right: ElderSpacing.lg,
              bottom: ElderSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRUSTED CARE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      // text-primary-fixed → primaryFixed.
                      color: ElderColors.primaryFixed,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Helping you stay connected to those who matter most.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ElderColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recently Connected Card ─────────────────────────────────────────────────

  Widget _buildRecentlyConnectedCard() {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        // bg-surface-container-high/30.
        color: ElderColors.surfaceContainerHigh.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENTLY CONNECTED',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ElderColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: ElderSpacing.md),
          // Overlapping avatar stack — 3 circles, 16dp overlap each.
          // Total width = 32 + (32-16) + (32-16) = 64dp.
          SizedBox(
            width: 64,
            height: _kStackAvatarSize,
            child: Stack(
              children: [
                // Avatar 1 — tertiary-fixed (#97f3e2 aqua) → primaryFixed.
                _StackAvatar(
                  left: 0,
                  bg: ElderColors.primaryFixed,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: ElderColors.onPrimaryFixed,
                  ),
                ),
                // Avatar 2 — secondary-fixed (#cde6f4 light blue) → tertiaryFixed.
                _StackAvatar(
                  left: _kStackAvatarSize - _kStackAvatarOverlap,
                  bg: ElderColors.tertiaryFixed,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: ElderColors.onTertiaryFixed,
                  ),
                ),
                // "+2" overflow count — primary-fixed bg.
                _StackAvatar(
                  left: (_kStackAvatarSize - _kStackAvatarOverlap) * 2,
                  bg: ElderColors.primaryFixed,
                  child: Text(
                    '+2',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.primary,
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

  // ── Bottom Nav — Elder active ───────────────────────────────────────────────

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
              // Elder tab is active — this screen is under the Elder flow.
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
                onTap: () {
                  // TODO: context.go('/mood-logs/caretaker') — Batch 3.
                },
              ),
              _NavItem(
                icon: Icons.link_rounded,
                label: 'Links',
                active: false,
                onTap: () {
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

// ── _StackAvatar ──────────────────────────────────────────────────────────────

/// A single circle in the overlapping avatar stack.
///
/// [left] is the horizontal offset from the start of the Stack container.
/// White border matches the HTML's `border-2 border-white` on each avatar.
class _StackAvatar extends StatelessWidget {
  const _StackAvatar({
    required this.left,
    required this.bg,
    required this.child,
  });

  final double left;
  final Color bg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: Container(
        width: _kStackAvatarSize,
        height: _kStackAvatarSize,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: ElderColors.surfaceContainerLowest,
            width: 2,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── _NavItem ──────────────────────────────────────────────────────────────────

/// Caretaker bottom nav tab — Elder tab active on this screen.
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
            borderRadius: BorderRadius.circular(8),
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
// ✅ Tap targets ≥ 48×48dp    — Send Request button: height 56 ✅
//                               Caretaker profile: 40×40 (non-interactive icon) ✅
//                               Nav items: ~56dp with padding ✅
//                               DropdownButton: 56dp+ with content padding ✅
// ✅ Font sizes ≥ 16sp         — all text 16sp or above; 18sp for input text ✅
//                               | "CONNECTION PORTAL" 16sp (raised from xs) ✅
//                               | input/dropdown labels 16sp (raised from xs) ✅
//                               | tip text 16sp (raised from 10px) ✅
//                               | info card body 16sp (raised from xs) ✅
//                               | "TRUSTED CARE" 16sp (raised from 10px) ✅
//                               | overlay text 16sp (raised from sm/14px) ✅
//                               | nav labels 12sp EXCEPTION: two-cue pill ✅
// ✅ Colour contrast WCAG AA   — onPrimary (#FFF) on primary (#005050): ~12:1 ✅
//                               primaryFixed (#A0F0F0) on primary overlay@80%:
//                               sufficient at ≥3:1 for large bold text ✅
//                               onSurfaceVariant on surfaceContainerLow: ~7:1 ✅
//                               onTertiaryFixed on tertiaryFixed (#CCE5FF): ~7:1 ✅
//                               primary on primaryFixed (#A0F0F0): ~6:1 ✅ AA
// ✅ Semantic labels            — Send Request button, caretaker profile,
//                               nav items ✅
// ✅ No colour as sole cue      — username field: label + search icon ✅
//                               relationship: label + expand icon ✅
//                               send: "Send Request" text + send icon ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.xl (32dp) between form sections ✅
//                               ElderSpacing.lg (24dp) between side cards ✅
// ────────────────────────────────────────────────────────────────────────────
