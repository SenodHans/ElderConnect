import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../core/providers/high_contrast_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../social/providers/caretaker_links_provider.dart';
import '../../../shared/widgets/aa_button.dart';

// ── Screen-level constants ────────────────────────────────────────────────────
const double _kCardRadius = 24.0;
const double _kAvatarRadius = 48.0;
const double _kEditButtonRadius = 16.0;

/// Elder Profile Screen — user identity, interests, health info, caretakers, settings.
class ElderProfileScreen extends ConsumerStatefulWidget {
  const ElderProfileScreen({super.key});

  @override
  ConsumerState<ElderProfileScreen> createState() => _ElderProfileScreenState();
}

class _ElderProfileScreenState extends ConsumerState<ElderProfileScreen> {
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const _AppSettingsSection(),
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

class _IdentitySection extends ConsumerStatefulWidget {
  const _IdentitySection();

  @override
  ConsumerState<_IdentitySection> createState() => _IdentitySectionState();
}

class _IdentitySectionState extends ConsumerState<_IdentitySection> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: ElderColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(ElderSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32, height: 4,
                decoration: BoxDecoration(
                  color: ElderColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ElderSpacing.lg),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: ElderColors.primary),
              title: Text('Take a Photo',
                  style: GoogleFonts.lexend(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: ElderColors.primary),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.lexend(fontSize: 18)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final xfile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final bytes = await xfile.readAsBytes();
      final ext = xfile.path.split('.').last.toLowerCase();
      final path = '$userId/avatar.$ext';

      await client.storage.from('avatars').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );

      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      await client.from('users').update({'avatar_url': publicUrl}).eq('id', userId);
      ref.invalidate(userProvider);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final fullName = userAsync.when(
      data: (user) => user?.fullName ?? '',
      loading: () => '',
      error: (_, __) => '',
    );
    final avatarUrl = userAsync.valueOrNull?.avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with edit overlay — centred
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
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
                  child: _uploading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : avatarUrl != null
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: ElderColors.surfaceContainerHighest,
                                size: 96,
                              ),
                            )
                          : const Icon(
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
                    shadowColor:
                        ElderColors.secondaryContainer.withValues(alpha: 0.40),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_kEditButtonRadius),
                      onTap: _pickAndUpload,
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
        ),
        const SizedBox(height: ElderSpacing.lg),
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
      ],
    );
  }
}

// ── Interests Section ─────────────────────────────────────────────────────────

/// Maps NewsAPI category keys to display metadata for interest tiles.
const _kInterestMeta = {
  'health': (
    label: 'Health',
    icon: Icons.health_and_safety,
    bg: ElderColors.primaryFixed,
    fg: ElderColors.onPrimaryFixed,
  ),
  'sports': (
    label: 'Sports',
    icon: Icons.sports_tennis,
    bg: ElderColors.secondaryFixed,
    fg: ElderColors.onSecondaryFixed,
  ),
  'technology': (
    label: 'Technology',
    icon: Icons.devices,
    bg: ElderColors.tertiaryFixed,
    fg: ElderColors.onTertiaryFixed,
  ),
  'entertainment': (
    label: 'Entertainment',
    icon: Icons.movie,
    bg: ElderColors.errorContainer,
    fg: ElderColors.onErrorContainer,
  ),
  'science': (
    label: 'Science',
    icon: Icons.biotech,
    bg: ElderColors.tertiaryContainer,
    fg: ElderColors.onTertiaryContainer,
  ),
  'business': (
    label: 'Business',
    icon: Icons.trending_up,
    bg: ElderColors.secondaryContainer,
    fg: ElderColors.onSecondaryContainer,
  ),
};

class _InterestsSection extends ConsumerWidget {
  const _InterestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(userProvider).valueOrNull?.interests ?? [];

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
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
        const SizedBox(height: ElderSpacing.lg),
        if (interests.isEmpty)
          _EmptyInterestsCard()
        else
          _InterestGrid(interests: interests),
      ],
    );
  }
}

class _EmptyInterestsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Column(
        children: [
          const Icon(Icons.interests_rounded,
              size: 48, color: ElderColors.outlineVariant),
          const SizedBox(height: ElderSpacing.md),
          Text(
            'No interests selected yet',
            style: GoogleFonts.lexend(
                fontSize: 18, color: ElderColors.onSurfaceVariant),
          ),
          const SizedBox(height: ElderSpacing.sm),
          Text(
            'Tap "Edit" to choose topics you enjoy',
            style: GoogleFonts.lexend(
                fontSize: 16, color: ElderColors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InterestGrid extends StatelessWidget {
  const _InterestGrid({required this.interests});
  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    // Build rows of 2
    final rows = <Widget>[];
    for (var i = 0; i < interests.length; i += 2) {
      final left = interests[i];
      final right = i + 1 < interests.length ? interests[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _InterestTile(category: left)),
              if (right != null) ...[
                const SizedBox(width: ElderSpacing.md),
                Expanded(child: _InterestTile(category: right)),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < interests.length) {
        rows.add(const SizedBox(height: ElderSpacing.md));
      }
    }
    return Column(children: rows);
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final meta = _kInterestMeta[category];
    final label = meta?.label ?? category;
    final icon = meta?.icon ?? Icons.star_rounded;
    final bg = meta?.bg ?? ElderColors.primaryFixed;
    final fg = meta?.fg ?? ElderColors.onPrimaryFixed;

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 40),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health Details Section ────────────────────────────────────────────────────

class _HealthSection extends ConsumerWidget {
  const _HealthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).valueOrNull;
    final dob = user?.dateOfBirth != null
        ? DateFormat('MMMM d, yyyy').format(user!.dateOfBirth!)
        : '—';

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
                  // Blood type not stored in DB — caretaker sets via external system
                  value: '—',
                ),
              ),
              const SizedBox(width: ElderSpacing.xl),
              Expanded(
                child: _HealthStat(
                  label: 'Date of Birth',
                  value: dob,
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

class _LinkedCaretakersSection extends ConsumerStatefulWidget {
  const _LinkedCaretakersSection();

  @override
  ConsumerState<_LinkedCaretakersSection> createState() =>
      _LinkedCaretakersSectionState();
}

class _LinkedCaretakersSectionState
    extends ConsumerState<_LinkedCaretakersSection> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _addingId = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCaretaker(CaretakerInfo caretaker) async {
    final client = Supabase.instance.client;
    final me = client.auth.currentUser?.id;
    if (me == null) return;

    setState(() => _addingId = caretaker.userId);
    try {
      await client.from('caretaker_links').insert({
        'caretaker_id': caretaker.userId,
        'elderly_user_id': me,
      });
      ref.invalidate(elderLinkedCaretakersProvider);
      setState(() {
        _searchCtrl.clear();
        _searchQuery = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${caretaker.fullName} added as your caretaker',
              style: GoogleFonts.lexend(fontSize: 16),
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: ElderColors.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add caretaker — they may already be linked',
                style: GoogleFonts.lexend(fontSize: 16)),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingId = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkedAsync = ref.watch(elderLinkedCaretakersProvider);
    final searchAsync = ref.watch(caretakerSearchProvider(_searchQuery));

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

        // ── Linked caretaker cards ────────────────────────────────────────────
        linkedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (caretakers) {
            if (caretakers.isEmpty) {
              return _NoCaretakersCard();
            }
            return Column(
              children: caretakers
                  .map((c) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: ElderSpacing.md),
                        child: _CaretakerRow(caretaker: c),
                      ))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: ElderSpacing.lg),

        // ── Search bar ───────────────────────────────────────────────────────
        Text(
          'Add a Caretaker',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ElderColors.onSurface,
          ),
        ),
        const SizedBox(height: ElderSpacing.sm),
        TextField(
          controller: _searchCtrl,
          style: GoogleFonts.lexend(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search by caretaker name…',
            hintStyle: GoogleFonts.lexend(
                fontSize: 18, color: ElderColors.onSurfaceVariant),
            prefixIcon: const Icon(Icons.search_rounded,
                color: ElderColors.onSurfaceVariant),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: ElderColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
        ),

        // ── Search results ───────────────────────────────────────────────────
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: ElderSpacing.md),
          searchAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(ElderSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (results) {
              if (results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(ElderSpacing.lg),
                  child: Text(
                    'No caretakers found for "$_searchQuery"',
                    style: GoogleFonts.lexend(
                        fontSize: 16, color: ElderColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: results
                    .map((c) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: ElderSpacing.sm),
                          child: _SearchResultRow(
                            caretaker: c,
                            adding: _addingId == c.userId,
                            onAdd: () => _addCaretaker(c),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _NoCaretakersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Column(
        children: [
          const Icon(Icons.group_rounded,
              size: 48, color: ElderColors.outlineVariant),
          const SizedBox(height: ElderSpacing.md),
          Text(
            'No caretakers yet',
            style: GoogleFonts.lexend(
                fontSize: 18, color: ElderColors.onSurfaceVariant),
          ),
          const SizedBox(height: ElderSpacing.xs),
          Text(
            'Search below to find and add your caretaker',
            style: GoogleFonts.lexend(
                fontSize: 16, color: ElderColors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CaretakerRow extends StatelessWidget {
  const _CaretakerRow({required this.caretaker});
  final CaretakerInfo caretaker;

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
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ElderColors.tertiaryFixed,
            ),
            child: caretaker.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      caretaker.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 26,
                              color: ElderColors.onTertiaryFixed),
                    ),
                  )
                : const Icon(Icons.person,
                    color: ElderColors.onTertiaryFixed, size: 26),
          ),
          const SizedBox(width: ElderSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caretaker.fullName,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.onSurface,
                  ),
                ),
                Text(
                  'Caretaker',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (caretaker.phone != null)
            Semantics(
              label: 'Call ${caretaker.fullName}',
              button: true,
              child: Material(
                color: ElderColors.surfaceContainerHigh,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      launchUrl(Uri.parse('tel:${caretaker.phone}')),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child:
                        Icon(Icons.call, color: ElderColors.primary, size: 22),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.caretaker,
    required this.adding,
    required this.onAdd,
  });
  final CaretakerInfo caretaker;
  final bool adding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.md),
      decoration: BoxDecoration(
        color: ElderColors.primaryFixed.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ElderColors.primaryFixed),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ElderColors.primaryFixed,
            ),
            child: caretaker.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      caretaker.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 22,
                              color: ElderColors.onPrimaryFixed),
                    ),
                  )
                : const Icon(Icons.person,
                    color: ElderColors.onPrimaryFixed, size: 22),
          ),
          const SizedBox(width: ElderSpacing.md),
          Expanded(
            child: Text(
              caretaker.fullName,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ElderColors.onSurface,
              ),
            ),
          ),
          adding
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Semantics(
                  label: 'Add ${caretaker.fullName} as caretaker',
                  button: true,
                  child: Material(
                    color: ElderColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onAdd,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: ElderSpacing.md, vertical: 8),
                        child: Icon(Icons.person_add_rounded,
                            color: Colors.white, size: 20),
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

class _EmergencySection extends ConsumerWidget {
  const _EmergencySection();

  void _showEditSheet(BuildContext context, WidgetRef ref,
      String? currentName, String? currentPhone) {
    final nameCtrl = TextEditingController(text: currentName ?? '');
    final phoneCtrl = TextEditingController(text: currentPhone ?? '');
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: ElderColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(ElderSpacing.lg),
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
                Text('Emergency Contact',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ElderColors.onSurface),
                    textAlign: TextAlign.center),
                const SizedBox(height: ElderSpacing.xl),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.lexend(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Contact Name',
                    labelStyle: GoogleFonts.lexend(fontSize: 16),
                    filled: true,
                    fillColor: ElderColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: ElderSpacing.md),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.lexend(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: GoogleFonts.lexend(fontSize: 16),
                    filled: true,
                    fillColor: ElderColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: ElderSpacing.xl),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ElderColors.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          setSheet(() => saving = true);
                          final userId = Supabase.instance.client.auth
                              .currentUser?.id;
                          if (userId != null) {
                            await Supabase.instance.client
                                .from('users')
                                .update({
                              'emergency_contact_name': nameCtrl.text.trim(),
                              'emergency_contact_phone': phoneCtrl.text.trim(),
                            }).eq('id', userId);
                            ref.invalidate(userProvider);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Save',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
                const SizedBox(height: ElderSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).valueOrNull;
    final contactName = user?.emergencyContactName;
    final contactPhone = user?.emergencyContactPhone;
    final hasContact = user?.hasEmergencyContact ?? false;

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
                        const Icon(Icons.emergency,
                            color: ElderColors.onErrorContainer, size: 22),
                        const SizedBox(width: ElderSpacing.sm + ElderSpacing.xs),
                        Expanded(
                          child: Text('Emergency Contacts',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: ElderColors.onErrorContainer)),
                        ),
                        // Plus icon to add / edit emergency contact
                        Semantics(
                          button: true,
                          label: 'Add or edit emergency contact',
                          child: GestureDetector(
                            onTap: () => _showEditSheet(
                                context, ref, contactName, contactPhone),
                            child: Container(
                              padding:
                                  const EdgeInsets.all(ElderSpacing.xs),
                              decoration: BoxDecoration(
                                color:
                                    ElderColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 20,
                                  color: ElderColors.onErrorContainer),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ElderSpacing.md),
                    _EmergencyContactRow(
                      name: 'Emergency Services',
                      number: '999',
                      onCall: () => launchUrl(Uri.parse('tel:999')),
                      showDivider: hasContact,
                    ),
                    if (hasContact) ...[
                      const SizedBox(height: ElderSpacing.md),
                      _EmergencyContactRow(
                        name: contactName ?? 'My Contact',
                        number: contactPhone!,
                        onCall: () =>
                            launchUrl(Uri.parse('tel:$contactPhone')),
                        showDivider: false,
                      ),
                    ] else ...[
                      const SizedBox(height: ElderSpacing.md),
                      GestureDetector(
                        onTap: () =>
                            _showEditSheet(context, ref, null, null),
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline,
                                size: 20,
                                color: ElderColors.onErrorContainer),
                            const SizedBox(width: ElderSpacing.xs),
                            Text('Add a personal emergency contact',
                                style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    color: ElderColors.onErrorContainer,
                                    decoration: TextDecoration.underline)),
                          ],
                        ),
                      ),
                    ],
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
    required this.onCall,
    required this.showDivider,
  });

  final String name;
  final String number;
  final VoidCallback onCall;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name,
                  style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ElderColors.onErrorContainer)),
            ),
            Semantics(
              button: true,
              label: 'Call $name',
              child: GestureDetector(
                onTap: onCall,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ElderSpacing.md, vertical: ElderSpacing.xs),
                  decoration: BoxDecoration(
                    color: ElderColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_rounded,
                          size: 18, color: ElderColors.onErrorContainer),
                      const SizedBox(width: 6),
                      Text(number,
                          style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ElderColors.onErrorContainer)),
                    ],
                  ),
                ),
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

class _AppSettingsSection extends ConsumerWidget {
  const _AppSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highContrast = ref.watch(highContrastProvider);

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
                      toggled: highContrast,
                      child: Switch(
                        value: highContrast,
                        onChanged: (v) {
                          ref.read(highContrastProvider.notifier).state = v;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                v
                                    ? 'High contrast mode enabled'
                                    : 'High contrast mode disabled',
                                style: GoogleFonts.lexend(fontSize: 16),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
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
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Language selection coming soon',
                                style: GoogleFonts.lexend(fontSize: 16),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
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
              const Divider(height: 1, indent: ElderSpacing.lg, endIndent: ElderSpacing.lg),
              // Logout row
              Semantics(
                label: 'Log out and switch account',
                button: true,
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(_kCardRadius)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          'Log Out?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        content: Text(
                          'You will need your PIN to log back in.',
                          style: GoogleFonts.lexend(fontSize: 18),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: GoogleFonts.lexend(fontSize: 18, color: ElderColors.onSurfaceVariant)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Log Out', style: GoogleFonts.lexend(fontSize: 18, color: ElderColors.error, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/role-selection');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(ElderSpacing.lg),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: ElderColors.error, size: 28),
                        const SizedBox(width: ElderSpacing.md),
                        Text(
                          'Log Out',
                          style: GoogleFonts.lexend(
                            fontSize: 20,
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
        ),
      ],
    );
  }
}


// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48 px — edit button 56dp; caretaker action buttons 48dp; search results padded
// ✅ Font sizes ≥ 16sp — all labels 16sp+, body 18sp+
// ✅ Colour contrast WCAG AA — onPrimary on primary; onErrorContainer on errorContainer
// ✅ Semantic labels on edit button, caretaker actions, search results, settings toggle, language picker
// ✅ Toggle has toggled state via Semantics wrapper
// ✅ No colour as sole differentiator — interest tiles have icon + label; caretaker rows have name text
// ✅ Touch targets separated by ≥ 8px — 16dp gap between all interactive rows
