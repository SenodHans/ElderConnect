/// Post Game Score — celebration result screen shown after an elder completes
/// a wellness game. No bottom nav — this is a self-contained result card.
/// Navigating away goes back to /games/elder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../social/providers/post_submission_provider.dart';
import '../providers/wellness_scores_provider.dart';

const double _kScoreCardRadius  = 24.0;
const double _kBentoCardRadius  = 32.0;
const double _kActionCardRadius = 40.0;
const double _kButtonRadius     = 12.0;
const double _kLeaderRowRadius  = 16.0;

class PostGameScoreScreen extends ConsumerStatefulWidget {
  const PostGameScoreScreen({super.key, required this.result});

  // Keys: {'game': String, 'score': int, 'total': int}  (Trivia/Scramble/Word)
  //       {'game': String, 'moves': int, 'time': String} (Memory)
  //       {'game': String}                               (Breathing)
  final Map<String, dynamic> result;

  @override
  ConsumerState<PostGameScoreScreen> createState() =>
      _PostGameScoreScreenState();
}

class _PostGameScoreScreenState extends ConsumerState<PostGameScoreScreen>
    with TickerProviderStateMixin {
  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;
  bool _shareLoading = false;
  bool _shared = false;

  String get _gameName =>
      widget.result['game'] as String? ?? 'Wellness Activity';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _anims = List.generate(
      4,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.08, (i * 0.08) + 0.60, curve: Curves.easeOut),
      ),
    );
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('wellness_logs').insert({
        'user_id': user.id,
        'game_name': _gameName,
        if (widget.result['score'] != null) 'score': widget.result['score'] as int,
        if (widget.result['total'] != null) 'total': widget.result['total'] as int,
      });
      // Refresh leaderboard + personal best after save
      ref.invalidate(gameLeaderboardProvider(_gameName));
      ref.invalidate(personalBestProvider(_gameName));
      ref.invalidate(myRecentScoresProvider);
    } catch (_) {}
  }

  Future<void> _shareScore() async {
    setState(() => _shareLoading = true);
    final score = widget.result['score'] as int?;
    final total = widget.result['total'] as int?;
    final moves = widget.result['moves'] as int?;
    final time  = widget.result['time'] as String?;

    String message;
    if (score != null && total != null) {
      message = 'I scored $score/$total in $_gameName! 🎮';
    } else if (moves != null && time != null) {
      message = 'I completed $_gameName in $time with $moves moves! 🎮';
    } else {
      message = 'I just completed $_gameName! 🎮';
    }

    try {
      await ref
          .read(postSubmissionProvider.notifier)
          .submitPost(content: message);
      if (mounted) {
        setState(() { _shareLoading = false; _shared = true; });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/games/elder');
      }
    } catch (_) {
      if (mounted) setState(() => _shareLoading = false);
    }
  }

  @override
  void dispose() {
    for (final a in _anims) { a.dispose(); }
    _anim.dispose();
    super.dispose();
  }

  Widget _fade(int i, Widget child) => AnimatedBuilder(
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
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: Column(
        children: [
          // Close button row (no full app bar — score screen is self-contained)
          _fade(0, _CloseBar(onClose: () => context.go('/games/elder'))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ElderSpacing.lg,
                ElderSpacing.sm,
                ElderSpacing.lg,
                ElderSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fade(1, _HeroSection(result: widget.result)),
                  const SizedBox(height: ElderSpacing.xxl),
                  _fade(2, _BentoSection(
                    gameName: _gameName,
                    currentScore: widget.result['score'] as int?,
                  )),
                  const SizedBox(height: ElderSpacing.xxl),
                  _fade(3, _ActionSection(
                    shareLoading: _shareLoading,
                    shared: _shared,
                    onShare: _shareScore,
                    onSkip: () => context.go('/games/elder'),
                  )),
                  const SizedBox(height: ElderSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Close Bar ─────────────────────────────────────────────────────────────────

class _CloseBar extends StatelessWidget {
  const _CloseBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ElderSpacing.md,
          vertical: ElderSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            label: 'Back to games',
            button: true,
            child: Material(
              color: ElderColors.surfaceContainerLow,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClose,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.close_rounded,
                    color: ElderColors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.result});
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final gameName = result['game'] as String? ?? 'Wellness Activity';
    final score = result['score'] as int?;
    final total = result['total'] as int?;
    final moves = result['moves'] as int?;
    final time  = result['time'] as String?;

    return Column(
      children: [
        Text(
          gameName,
          style: GoogleFonts.lexend(
            fontSize: 18, color: ElderColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ElderSpacing.md),
        SizedBox(
          width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: ElderColors.secondaryContainer.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
            ),
            const Icon(Icons.stars_rounded, size: 80, color: ElderColors.secondary),
          ]),
        ),
        const SizedBox(height: ElderSpacing.lg),
        Text(
          'Great Job!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 48, fontWeight: FontWeight.w800,
            color: ElderColors.primary, height: 1.1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ElderSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ElderSpacing.xl),
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(_kScoreCardRadius),
            boxShadow: [
              BoxShadow(
                color: ElderColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: score != null && total != null
              ? _TriviaResult(score: score, total: total)
              : moves != null && time != null
                  ? _MemoryResult(moves: moves, time: time)
                  : _GenericResult(),
        ),
      ],
    );
  }
}

class _TriviaResult extends StatelessWidget {
  const _TriviaResult({required this.score, required this.total});
  final int score, total;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text('Your Score',
            style: GoogleFonts.lexend(
                fontSize: 18, fontWeight: FontWeight.w500,
                color: ElderColors.onSurfaceVariant)),
        const SizedBox(height: ElderSpacing.sm),
        Text('$score / $total',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 56, fontWeight: FontWeight.w800,
                color: ElderColors.secondary, height: 1.1),
            textAlign: TextAlign.center),
        const SizedBox(height: ElderSpacing.xs),
        Text(
          score == total
              ? 'Perfect score!'
              : score >= total * 0.7 ? 'Well done!' : 'Keep practising!',
          style: GoogleFonts.lexend(fontSize: 18, color: ElderColors.onSurfaceVariant),
        ),
      ]);
}

class _MemoryResult extends StatelessWidget {
  const _MemoryResult({required this.moves, required this.time});
  final int moves; final String time;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(label: 'Moves', value: '$moves', icon: Icons.touch_app_rounded),
          Container(width: 1, height: 48, color: ElderColors.outlineVariant),
          _Stat(label: 'Time', value: time, icon: Icons.timer_rounded),
        ],
      );
}

class _GenericResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
        'Activity complete!',
        style: GoogleFonts.lexend(
            fontSize: 24, fontWeight: FontWeight.w600,
            color: ElderColors.primary),
        textAlign: TextAlign.center,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label, value; final IconData icon;

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, size: 28, color: ElderColors.primary),
        const SizedBox(height: ElderSpacing.xs),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 36, fontWeight: FontWeight.w800,
                color: ElderColors.secondary)),
        Text(label,
            style: GoogleFonts.lexend(
                fontSize: 16, color: ElderColors.onSurfaceVariant)),
      ]);
}

// ── Bento Section (Personal Best + Leaderboard) ───────────────────────────────

class _BentoSection extends ConsumerWidget {
  const _BentoSection({required this.gameName, this.currentScore});
  final String gameName;
  final int? currentScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      _PersonalBestCard(gameName: gameName, currentScore: currentScore),
      const SizedBox(height: ElderSpacing.lg),
      _LeaderboardCard(gameName: gameName),
    ]);
  }
}

class _PersonalBestCard extends ConsumerWidget {
  const _PersonalBestCard({required this.gameName, this.currentScore});
  final String gameName; final int? currentScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestAsync = ref.watch(personalBestProvider(gameName));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kBentoCardRadius),
      ),
      child: Column(children: [
        const Icon(Icons.emoji_events_rounded, size: 40, color: ElderColors.tertiary),
        const SizedBox(height: ElderSpacing.md),
        Text('Personal Best',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: ElderColors.onSurface),
            textAlign: TextAlign.center),
        const SizedBox(height: ElderSpacing.sm),
        bestAsync.when(
          loading: () => const SizedBox(
              height: 28,
              child: CircularProgressIndicator(
                  color: ElderColors.primary, strokeWidth: 2)),
          error: (_, __) => const SizedBox.shrink(),
          data: (best) {
            if (best == null || currentScore == null) {
              return Text(
                currentScore != null
                    ? 'Your first score: $currentScore pts!'
                    : 'Activity complete!',
                style: GoogleFonts.lexend(
                    fontSize: 18, color: ElderColors.onSurfaceVariant,
                    height: 1.5),
                textAlign: TextAlign.center,
              );
            }
            final diff = currentScore! - best;
            if (diff > 0) {
              return RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.lexend(
                      fontSize: 18, color: ElderColors.onSurfaceVariant, height: 1.5),
                  children: [
                    const TextSpan(text: 'New personal best! You surpassed by '),
                    TextSpan(
                      text: '+$diff pts',
                      style: GoogleFonts.lexend(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: ElderColors.primary),
                    ),
                    const TextSpan(text: ' 🎉'),
                  ],
                ),
              );
            }
            return Text(
              'Your best is $best pts. Keep going!',
              style: GoogleFonts.lexend(
                  fontSize: 18, color: ElderColors.onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            );
          },
        ),
      ]),
    );
  }
}

class _LeaderboardCard extends ConsumerWidget {
  const _LeaderboardCard({required this.gameName});
  final String gameName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(gameLeaderboardProvider(gameName));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ElderSpacing.lg),
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_kBentoCardRadius),
        boxShadow: [
          BoxShadow(
            color: ElderColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.leaderboard_rounded, size: 22, color: ElderColors.primary),
          const SizedBox(width: ElderSpacing.sm),
          Text('Leaderboard',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: ElderColors.onSurface)),
        ]),
        const SizedBox(height: ElderSpacing.lg),
        boardAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: ElderColors.primary)),
          error: (_, __) => Text('Could not load scores',
              style: GoogleFonts.lexend(
                  fontSize: 16, color: ElderColors.onSurfaceVariant)),
          data: (entries) {
            if (entries.isEmpty) {
              return Text('No scores yet — be the first!',
                  style: GoogleFonts.lexend(
                      fontSize: 16, color: ElderColors.onSurfaceVariant));
            }
            return Column(
              children: entries.asMap().entries.map((e) {
                final rank = e.key + 1;
                final entry = e.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: rank < entries.length ? ElderSpacing.md : 0),
                  child: _LeaderRow(rank: rank, entry: entry),
                );
              }).toList(),
            );
          },
        ),
      ]),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.rank, required this.entry});
  final int rank; final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rank $rank: ${entry.name}, ${entry.score} points',
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.sm, vertical: ElderSpacing.sm),
        decoration: BoxDecoration(
          color: entry.isMe ? ElderColors.primaryFixed : ElderColors.surface,
          borderRadius: BorderRadius.circular(_kLeaderRowRadius),
        ),
        child: Row(children: [
          SizedBox(
            width: 24,
            child: Text('$rank',
                style: GoogleFonts.lexend(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: entry.isMe
                        ? ElderColors.onPrimaryFixed
                        : ElderColors.onSurfaceVariant)),
          ),
          const SizedBox(width: ElderSpacing.sm),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isMe
                  ? ElderColors.primaryFixedDim
                  : ElderColors.surfaceContainerLow,
              border: entry.isMe
                  ? Border.all(color: ElderColors.primaryContainer, width: 2)
                  : null,
            ),
            child: Icon(Icons.person_rounded, size: 22,
                color: entry.isMe
                    ? ElderColors.onPrimaryFixed
                    : ElderColors.onSurfaceVariant),
          ),
          const SizedBox(width: ElderSpacing.sm),
          Expanded(
            child: Text(entry.name,
                style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight:
                        entry.isMe ? FontWeight.w600 : FontWeight.w500,
                    color: entry.isMe
                        ? ElderColors.onPrimaryFixed
                        : ElderColors.onSurface)),
          ),
          Text('${entry.score} pts',
              style: GoogleFonts.lexend(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: entry.isMe
                      ? ElderColors.onPrimaryFixed
                      : ElderColors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ── Action Section ────────────────────────────────────────────────────────────

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.shareLoading,
    required this.shared,
    required this.onShare,
    required this.onSkip,
  });

  final bool shareLoading, shared;
  final VoidCallback onShare, onSkip;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kActionCardRadius),
      child: Container(
        color: ElderColors.tertiaryFixed,
        child: Stack(children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: ElderColors.tertiaryFixedDim.withValues(alpha: 0.30),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(ElderSpacing.xxl),
            child: Column(children: [
              Text('Share your success?',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 30, fontWeight: FontWeight.w700,
                      color: ElderColors.onTertiaryFixed, height: 1.2),
                  textAlign: TextAlign.center),
              const SizedBox(height: ElderSpacing.md),
              Text(
                "Post your score to the feed so your caretaker and family can celebrate with you!",
                style: GoogleFonts.lexend(
                    fontSize: 18, color: ElderColors.onTertiaryFixedVariant,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ElderSpacing.xxl),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Share button
                Semantics(
                  button: true, label: 'Share my score',
                  child: Material(
                    color: shared ? Colors.green : ElderColors.primary,
                    borderRadius: BorderRadius.circular(_kButtonRadius),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_kButtonRadius),
                      onTap: (shareLoading || shared) ? null : onShare,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        padding: const EdgeInsets.symmetric(
                            horizontal: ElderSpacing.xxl, vertical: ElderSpacing.md),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (shareLoading)
                                const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                              else
                                Icon(
                                  shared
                                      ? Icons.check_circle_rounded
                                      : Icons.share_rounded,
                                  color: ElderColors.onPrimary, size: 24),
                              const SizedBox(width: ElderSpacing.sm),
                              Text(
                                shared ? 'Shared!' : 'Yes, Share!',
                                style: GoogleFonts.lexend(
                                    fontSize: 20, fontWeight: FontWeight.w700,
                                    color: ElderColors.onPrimary)),
                            ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ElderSpacing.md),
                // Skip button
                Semantics(
                  button: true, label: 'Maybe later',
                  child: Material(
                    color: ElderColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(_kButtonRadius),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_kButtonRadius),
                      onTap: onSkip,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        padding: const EdgeInsets.symmetric(
                            horizontal: ElderSpacing.xxl, vertical: ElderSpacing.md),
                        child: Center(
                          child: Text('Maybe Later',
                              style: GoogleFonts.lexend(
                                  fontSize: 20, fontWeight: FontWeight.w600,
                                  color: ElderColors.onSurface)),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48dp  — close button 48dp circle, action buttons minHeight 72dp
// ✅ Font sizes ≥ 16sp   — all body text 16sp+, exception: none
// ✅ WCAG AA contrast    — onPrimary/white on primary teal, onTertiaryFixed on tertiaryFixed
// ✅ Semantic labels     — close, share, skip, leaderboard rows all labelled
// ✅ No colour-only cue  — rank number + name + score on every leaderboard row
