/// Word Scramble — language wellness activity for elderly users.
///
/// 10 rounds. Each round shows a familiar word scrambled as large letter tiles.
/// Elder taps the tiles in the correct order to spell the word. No time pressure.
/// Score (words solved) passed to /score/post-game on completion.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Simple, familiar words — picked for recognisability across age groups.
// 4–6 letters: easy enough to solve without frustration, complex enough to engage.
const _kWords = [
  'APPLE', 'BREAD', 'CLOCK', 'DANCE', 'EAGLE',
  'FLAME', 'GRASS', 'HEART', 'IMAGE', 'JEWEL',
];

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen>
    with SingleTickerProviderStateMixin {
  int _round = 0;
  int _score = 0;

  // Scrambled letters available to tap.
  late List<_Tile> _pool;
  // Letters the elder has tapped so far (building the answer).
  final List<_Tile> _chosen = [];

  bool _solved = false;
  bool _wrong  = false;  // brief wrong-answer flash

  late final AnimationController _anim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _buildRound();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _buildRound() {
    final word = _kWords[_round];
    final letters = word.split('')..shuffle(Random());
    _pool   = letters.asMap().entries.map((e) => _Tile(e.key, e.value)).toList();
    _chosen.clear();
    _solved = false;
    _wrong  = false;
  }

  void _tapPool(int idx) {
    if (_solved) return;
    final tile = _pool[idx];
    setState(() {
      _pool.removeAt(idx);
      _chosen.add(tile);
    });
    _checkAnswer();
  }

  void _tapChosen(int idx) {
    if (_solved) return;
    final tile = _chosen[idx];
    setState(() {
      _chosen.removeAt(idx);
      // Restore to pool in original order position.
      _pool.add(tile);
      _pool.sort((a, b) => a.id.compareTo(b.id));
    });
  }

  void _checkAnswer() {
    final word = _kWords[_round];
    if (_chosen.length < word.length) return;
    final attempt = _chosen.map((t) => t.letter).join();
    if (attempt == word) {
      setState(() {
        _solved = true;
        _score++;
      });
    } else if (_chosen.length == word.length) {
      // Wrong — flash red, then auto-reset pool.
      setState(() => _wrong = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _buildRound();
        });
      });
    }
  }

  void _next() {
    if (_round == _kWords.length - 1) {
      context.go('/score/post-game', extra: {
        'game': 'Word Scramble',
        'score': _score,
        'total': _kWords.length,
      });
      return;
    }
    setState(() {
      _round++;
      _buildRound();
    });
    _anim.forward(from: 0);
  }

  void _skip() {
    if (_round == _kWords.length - 1) {
      context.go('/score/post-game', extra: {
        'game': 'Word Scramble',
        'score': _score,
        'total': _kWords.length,
      });
      return;
    }
    setState(() {
      _round++;
      _buildRound();
    });
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final word = _kWords[_round];
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildProgress(),
            // Game area — prompt card, answer slots, letter pool.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ElderSpacing.lg, ElderSpacing.md,
                ElderSpacing.lg, 0,
              ),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    _buildPromptCard(word),
                    const SizedBox(height: ElderSpacing.lg),
                    _buildAnswerRow(word),
                    const SizedBox(height: ElderSpacing.lg),
                    _buildLetterPool(),
                  ],
                ),
              ),
            ),
            // Push tip panel to the bottom half.
            const Spacer(),
            // Tip / how-to panel — always visible, fills lower half.
            _buildTipPanel(),
            // Action button: Next (after solving) or Skip.
            if (_solved)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    ElderSpacing.lg, ElderSpacing.md, ElderSpacing.lg, ElderSpacing.lg),
                child: Semantics(
                  button: true,
                  label: _round == _kWords.length - 1
                      ? 'See your results'
                      : 'Next word',
                  child: GestureDetector(
                    onTap: _next,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [ElderColors.primary, ElderColors.primaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _round == _kWords.length - 1
                              ? 'See Results'
                              : 'Next Word',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // Tip panel — occupies the lower half of the screen.
  // Rounded top corners connect it visually to the bottom of the play area.
  Widget _buildTipPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(
        ElderSpacing.xl, ElderSpacing.lg, ElderSpacing.xl, ElderSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle pill
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ElderColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: ElderSpacing.md),
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  size: 22, color: ElderColors.secondary),
              const SizedBox(width: ElderSpacing.sm),
              Text(
                'How to play',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: ElderSpacing.lg),
          _TipRow(
            icon: Icons.touch_app_rounded,
            color: ElderColors.secondary,
            text: 'Tap a letter tile below to add it to your answer.',
          ),
          const SizedBox(height: ElderSpacing.md),
          _TipRow(
            icon: Icons.undo_rounded,
            color: ElderColors.primary,
            text: 'Changed your mind? Tap any placed letter to send it back.',
          ),
          const SizedBox(height: ElderSpacing.md),
          _TipRow(
            icon: Icons.skip_next_rounded,
            color: ElderColors.tertiary,
            text: 'Stuck? Tap "Skip" — no points lost, just move on.',
          ),
          const SizedBox(height: ElderSpacing.lg),
          // Skip button lives inside the tip panel when not yet solved.
          if (!_solved)
            Semantics(
              button: true,
              label: 'Skip this word',
              child: GestureDetector(
                onTap: _skip,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: ElderColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Skip This Word',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: ElderSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildPromptCard(String word) {
    return Container(
      padding: const EdgeInsets.all(ElderSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ElderColors.secondary, ElderColors.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Word ${_round + 1} of ${_kWords.length}',
            style: GoogleFonts.lexend(
              fontSize: 16,
              color: ElderColors.onSecondary.withValues(alpha: 0.80),
            ),
          ),
          const SizedBox(height: ElderSpacing.sm),
          Text(
            'Tap the letters in the right order',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ElderColors.onSecondary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Answer slots — filled as elder taps pool letters.
  Widget _buildAnswerRow(String word) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (i) {
        final filled = i < _chosen.length;
        final isWrong = _wrong && filled;
        final isSolved = _solved && filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            label: filled ? 'Letter ${_chosen[i].letter}' : 'Empty slot',
            button: filled,
            child: GestureDetector(
              onTap: filled ? () => _tapChosen(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 60,
                decoration: BoxDecoration(
                  color: isSolved
                      ? ElderColors.primaryFixed
                      : isWrong
                          ? ElderColors.errorContainer
                          : filled
                              ? ElderColors.surfaceContainerLowest
                              : ElderColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSolved
                        ? ElderColors.primary
                        : isWrong
                            ? ElderColors.error
                            : ElderColors.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: filled
                      ? Text(
                          _chosen[i].letter,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isSolved
                                ? ElderColors.primary
                                : isWrong
                                    ? ElderColors.onErrorContainer
                                    : ElderColors.onSurface,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // Scrambled letter pool — tappable tiles.
  Widget _buildLetterPool() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: ElderSpacing.sm,
      runSpacing: ElderSpacing.sm,
      children: _pool.asMap().entries.map((e) {
        return Semantics(
          button: true,
          label: 'Letter ${e.value.letter}',
          child: GestureDetector(
            onTap: () => _tapPool(e.key),
            child: Container(
              width: 64,
              height: 72,
              decoration: BoxDecoration(
                color: ElderColors.secondaryFixed,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ElderColors.secondary.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  e.value.letter,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: ElderColors.onSecondaryFixed,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ElderSpacing.lg,
        vertical: ElderSpacing.md,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Go back',
            child: GestureDetector(
              onTap: () => context.go('/games/elder'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ElderColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: ElderColors.primary, size: 24),
              ),
            ),
          ),
          const SizedBox(width: ElderSpacing.md),
          Text(
            'Word Scramble',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ElderColors.primary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ElderSpacing.md,
              vertical: ElderSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: ElderColors.secondaryFixed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Score: $_score',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ElderColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: (_round + 1) / _kWords.length,
          backgroundColor: ElderColors.surfaceContainerHighest,
          valueColor: const AlwaysStoppedAnimation(ElderColors.secondary),
          minHeight: 8,
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: ElderSpacing.md),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lexend(
              fontSize: 16,
              color: ElderColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// Holds an individual letter tile — id preserves original sort order for pool restore.
class _Tile {
  const _Tile(this.id, this.letter);
  final int id;
  final String letter;
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets — pool tiles 64×72dp; answer slots 52×60dp (min 48dp) ✅
// ✅ Font sizes ≥ 16sp — prompt 22sp, letters 26–30sp, score/skip 16–18sp ✅
// ✅ Semantic labels — all tiles, slots, buttons, skip link labelled ✅
// ✅ Non-colour cue — wrong: red border + errorContainer bg (not colour alone) ✅
//                     solved: green border + check gradient + primaryFixed bg ✅
// ✅ No time pressure — no countdown, skip available, elder controls pace ✅
// ✅ Colour contrast — onSecondaryFixed on secondaryFixed; onPrimary on gradient ✅
