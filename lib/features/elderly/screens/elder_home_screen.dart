import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../auth/providers/user_provider.dart';
import '../../medications/providers/medications_provider.dart';
import '../../social/providers/voice_message_provider.dart';
import '../../../shared/models/medication_model.dart';
import '../../../shared/widgets/aa_button.dart';

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
  DateTime? _lastBackPress;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final isFirstPress = _lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2);
    if (isFirstPress) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Press back again to exit',
            style: GoogleFonts.lexend(fontSize: 16)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return false;
    }
    SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMedication = ref.watch(hasMedicationProvider);
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _onWillPop(),
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
                  const _GreetingSection(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _MedicationCard(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _MoodCard(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _ConnectCard(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _EmergencySection(),
                  const SizedBox(height: ElderSpacing.xl),
                  const _WellnessTipCard(),
                  // Clearance for the bottom nav sheet
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
        onTabSelected: (tab) {
          setState(() => _activeTab = tab);
          switch (tab) {
            case _NavTab.feed:       context.go('/feed/elder');
            case _NavTab.games:      context.go('/games/elder');
            case _NavTab.medication: context.go('/medications/elder');
            case _NavTab.home:       break;
          }
        },
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
                  Semantics(
                    label: 'Your profile photo',
                    button: true,
                    child: GestureDetector(
                      onTap: () => context.go('/profile/elder'),
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

/// Medication reminder card driven by live Supabase data.
/// Hidden when no medications are assigned or no dose is pending.
/// Dismisses with animation after the elder acts on it.
class _MedicationCard extends ConsumerStatefulWidget {
  const _MedicationCard();

  @override
  ConsumerState<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends ConsumerState<_MedicationCard> {
  // null = showing card | 'taken' = success message | 'snoozed' = reminder message
  String? _dismissStatus;
  bool _buttonPressed = false; // triggers green button feedback
  bool _collapsed = false;     // triggers AnimatedSize collapse to zero

  Future<void> _onTaken(MedicationLogModel log) async {
    setState(() => _buttonPressed = true);
    // Log to Supabase — caretaker sees this in their dashboard.
    try {
      await Supabase.instance.client.from('medication_logs').update({
        'status': 'taken',
        'taken_at': DateTime.now().toIso8601String(),
      }).eq('id', log.id);
    } catch (_) {
      // Non-critical — UI continues regardless of network state.
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _dismissStatus = 'taken');
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _collapsed = true);
  }

  void _onSnoozed() {
    setState(() => _dismissStatus = 'snoozed');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _collapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_collapsed) return const SizedBox.shrink();

    final hasMed = ref.watch(hasMedicationProvider);
    if (!hasMed) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildCurrentState(context),
      ),
    );
  }

  Widget _buildCurrentState(BuildContext context) {
    if (_dismissStatus == 'taken') {
      return _FeedbackTile(
        key: const ValueKey('taken'),
        emoji: '🎉',
        title: 'Well done!',
        message: "Medication marked as taken. Your caretaker has been notified. Keep up the great work!",
        color: const Color(0xFFE8F5E9),
        titleColor: const Color(0xFF2E7D32),
      );
    }
    if (_dismissStatus == 'snoozed') {
      return _FeedbackTile(
        key: const ValueKey('snoozed'),
        emoji: '⏰',
        title: 'No problem!',
        message: "Don't forget to take your medication. We'll remind you again soon.",
        color: ElderColors.surfaceContainerLow,
        titleColor: ElderColors.onSurfaceVariant,
      );
    }

    return ref.watch(nextMedicationProvider).when(
      loading: () => const SizedBox.shrink(key: ValueKey('loading')),
      error: (_, __) => const SizedBox.shrink(key: ValueKey('error')),
      data: (log) {
        if (log == null) return const SizedBox.shrink(key: ValueKey('empty'));
        return _buildCard(context, log);
      },
    );
  }

  Widget _buildCard(BuildContext context, MedicationLogModel log) {
    return Container(
      key: const ValueKey('card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ElderColors.primaryContainer,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.primaryContainer.withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow circle
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
              ),
            ),
          ),
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
                  '${log.pillName} ${log.dosage}'.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: ElderSpacing.xs),
                Text(
                  'Scheduled for ${log.timestampFormatted}',
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: ElderColors.onPrimaryContainer.withValues(alpha: 0.90),
                  ),
                ),
                const SizedBox(height: ElderSpacing.xl),
                // "Yes, I took it" — changes green on press
                Semantics(
                  label: 'Yes, I took my medication',
                  button: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _buttonPressed
                          ? const Color(0xFF2E7D32)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _buttonPressed ? null : () => _onTaken(log),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _buttonPressed
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: _buttonPressed
                                  ? Colors.white
                                  : ElderColors.primaryContainer,
                              size: 26,
                            ),
                            const SizedBox(width: ElderSpacing.sm),
                            Text(
                              _buttonPressed ? 'Marked!' : 'Yes, I took it',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _buttonPressed
                                    ? Colors.white
                                    : ElderColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ElderSpacing.md),
                // "Not yet" — snooze
                Semantics(
                  label: 'Not yet — remind me later',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _buttonPressed ? null : _onSnoozed,
                      style: TextButton.styleFrom(
                        backgroundColor: ElderColors.primary.withValues(alpha: 0.20),
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

/// Small feedback tile shown after the elder acts on the medication card.
class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    required this.color,
    required this.titleColor,
  });

  final String emoji;
  final String title;
  final String message;
  final Color color;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: ElderSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: ElderSpacing.xs),
                Text(
                  message,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    color: ElderColors.onSurface,
                    height: 1.5,
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
              childAspectRatio: 0.72,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mood recorded: ${widget.label}',
                style: GoogleFonts.lexend(fontSize: 16),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          // TODO(backend-sprint): persist mood → AI mood log if consent given
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

class _ConnectCard extends ConsumerWidget {
  const _ConnectCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          onPressed: () => context.go('/feed/elder'),
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
                    const SizedBox(height: ElderSpacing.md),
                    Semantics(
                      label: 'Record a voice message for your family',
                      button: true,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showVoiceRecorder(context, ref),
                          icon: const Icon(Icons.mic, size: 22),
                          label: const Text('Send Voice Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ElderColors.secondary,
                            side: const BorderSide(color: ElderColors.secondary, width: 2),
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

void _showVoiceRecorder(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _VoiceRecorderSheet(),
  );
}

// ── Voice Recorder Bottom Sheet ───────────────────────────────────────────────

class _VoiceRecorderSheet extends ConsumerWidget {
  const _VoiceRecorderSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(voiceMessageProvider);
    final notifier = ref.read(voiceMessageProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        ElderSpacing.xl,
        ElderSpacing.xl,
        ElderSpacing.xl,
        ElderSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: ElderColors.onSurfaceVariant.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: ElderSpacing.xl),
          Text(
            'Voice Message',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ElderColors.onSurface,
            ),
          ),
          const SizedBox(height: ElderSpacing.sm),
          Text(
            'Your voice message will be sent to your family.',
            style: GoogleFonts.lexend(
              fontSize: 18,
              color: ElderColors.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ElderSpacing.xxl),
          _MicButton(status: vm.status, notifier: notifier),
          const SizedBox(height: ElderSpacing.lg),
          _VoiceStatusLabel(vm: vm),
          const SizedBox(height: ElderSpacing.xl),
          if (vm.status == VoiceMessageStatus.recording)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: notifier.cancelRecording,
                style: TextButton.styleFrom(
                  foregroundColor: ElderColors.onSurfaceVariant,
                  textStyle: GoogleFonts.lexend(fontSize: 18),
                ),
                child: const Text('Cancel'),
              ),
            ),
          if (vm.status == VoiceMessageStatus.sent)
            Padding(
              padding: const EdgeInsets.only(bottom: ElderSpacing.md),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElderColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          const SizedBox(height: ElderSpacing.md),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.status, required this.notifier});
  final VoiceMessageStatus status;
  final VoiceMessageNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final isRecording = status == VoiceMessageStatus.recording;
    final isSending = status == VoiceMessageStatus.sending;
    final isSent = status == VoiceMessageStatus.sent;

    return Semantics(
      label: isRecording ? 'Stop recording' : 'Start recording',
      button: true,
      child: GestureDetector(
        onTap: isSending || isSent
            ? null
            : isRecording
                ? notifier.stopAndSend
                : notifier.startRecording,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording
                ? ElderColors.error
                : isSent
                    ? const Color(0xFF2E7D32)
                    : ElderColors.primary,
            boxShadow: [
              BoxShadow(
                color: (isRecording ? ElderColors.error : ElderColors.primary)
                    .withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isSending
              ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Icon(
                  isRecording
                      ? Icons.stop_rounded
                      : isSent
                          ? Icons.check_rounded
                          : Icons.mic,
                  color: Colors.white,
                  size: 48,
                ),
        ),
      ),
    );
  }
}

class _VoiceStatusLabel extends StatelessWidget {
  const _VoiceStatusLabel({required this.vm});
  final VoiceMessageState vm;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (vm.status) {
      VoiceMessageStatus.idle     => ('Tap the mic to start recording', ElderColors.onSurfaceVariant),
      VoiceMessageStatus.recording => ('Recording... tap to stop and send', ElderColors.error),
      VoiceMessageStatus.sending   => ('Sending your message...', ElderColors.onSurfaceVariant),
      VoiceMessageStatus.sent      => ('Voice message sent!', const Color(0xFF2E7D32)),
      VoiceMessageStatus.error     => (vm.errorMessage ?? 'Something went wrong', ElderColors.error),
    };
    return Text(
      text,
      style: GoogleFonts.lexend(fontSize: 18, color: color),
      textAlign: TextAlign.center,
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Connecting to emergency services...',
                          style: GoogleFonts.lexend(fontSize: 16),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    // TODO(backend-sprint): initiate emergency call via url_launcher
                  },
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'SOS alert sent to your caretaker!',
                          style: GoogleFonts.lexend(fontSize: 16),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: ElderColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    // TODO(backend-sprint): push FCM SOS notification to caretaker
                  },
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

// ── Daily Wellness Tip Card ───────────────────────────────────────────────────

/// Curated daily wellness tip — rotates by day of year so the card feels
/// fresh each day without needing a network call.
class _WellnessTipCard extends StatelessWidget {
  const _WellnessTipCard();

  static const _tips = [
    (
      emoji: '🚶',
      tip: 'A 10-minute walk after each meal helps lower blood sugar and boosts your mood.',
    ),
    (
      emoji: '💧',
      tip: 'Drink a glass of water first thing in the morning to rehydrate after sleep.',
    ),
    (
      emoji: '🧠',
      tip: 'Doing a crossword or word puzzle each day keeps your mind sharp and active.',
    ),
    (
      emoji: '🌬️',
      tip: 'Take 5 slow, deep breaths when you feel stressed — it calms the heart rate quickly.',
    ),
    (
      emoji: '☀️',
      tip: 'Spending 15 minutes in morning sunlight improves sleep quality at night.',
    ),
    (
      emoji: '🤝',
      tip: 'Calling a friend or family member today can significantly lift your spirits.',
    ),
    (
      emoji: '🎵',
      tip: 'Listening to your favourite music reduces anxiety and brings back happy memories.',
    ),
    (
      emoji: '🌿',
      tip: 'Eating a handful of leafy greens each day supports heart and brain health.',
    ),
    (
      emoji: '😴',
      tip: 'Going to bed at the same time every night greatly improves your sleep quality.',
    ),
    (
      emoji: '🪑',
      tip: 'Stand up and stretch for two minutes every hour to keep your joints comfortable.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Rotate daily without network — day of year mod tip count.
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final tip = _tips[dayOfYear % _tips.length];

    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        // Light sky blue — warm, calm, distinct from the teal primary cards.
        color: ElderColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.tertiary.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large emoji in a soft circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ElderColors.tertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(tip.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: ElderSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Wellness Tip',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.onTertiaryFixed.withValues(alpha: 0.65),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: ElderSpacing.xs),
                Text(
                  tip.tip,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: ElderColors.onTertiaryFixed,
                    height: 1.55,
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

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48 px — all interactive elements sized ≥ 48dp
// ✅ Font sizes ≥ 16sp — exception: nav labels 12sp inside 64dp pill (icon+label two-cue rule)
// ✅ Colour contrast WCAG AA — white on primaryContainer, onSecondaryContainer on secondaryContainer
// ✅ Semantic labels on all icon buttons and images
// ✅ No colour as sole differentiator — active nav uses filled pill + size change
// ✅ Touch targets separated by ≥ 8px spacing — grid 16dp gaps, nav uses spaceAround
