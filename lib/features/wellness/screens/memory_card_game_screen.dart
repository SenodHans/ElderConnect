/// Memory Card Flip Game — cognitive wellness activity.
///
/// 4×4 grid of face-down cards (8 emoji pairs). Tap to flip; matched pairs
/// stay face-up. Tracks moves and time. On completion navigates to
/// /score/post-game with the result.
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// 8 emoji pairs shuffled into 16 cards.
const _kEmojis = ['🌸', '🦋', '🌈', '⭐', '🎵', '🌺', '🐝', '🍀'];

class MemoryCardGameScreen extends StatefulWidget {
  const MemoryCardGameScreen({super.key});

  @override
  State<MemoryCardGameScreen> createState() => _MemoryCardGameScreenState();
}

class _MemoryCardGameScreenState extends State<MemoryCardGameScreen> {
  late List<_Card> _cards;
  final List<int> _flipped = [];   // indices currently face-up (max 2)
  final Set<int> _matched = {};    // indices permanently matched
  bool _checking = false;          // lock while checking pair
  int _moves = 0;
  late final Stopwatch _timer;
  late final Timer _ticker;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _buildDeck();
    _timer = Stopwatch()..start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _elapsed = _timer.elapsed.inSeconds),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    _timer.stop();
    super.dispose();
  }

  void _buildDeck() {
    final pool = [..._kEmojis, ..._kEmojis]..shuffle(Random());
    _cards = pool.map((e) => _Card(emoji: e)).toList();
  }

  Future<void> _onTap(int i) async {
    if (_checking) return;
    if (_matched.contains(i)) return;
    if (_flipped.contains(i)) return;
    if (_flipped.length == 2) return;

    setState(() => _cards[i].faceUp = true);
    _flipped.add(i);

    if (_flipped.length == 2) {
      _moves++;
      _checking = true;
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final a = _flipped[0], b = _flipped[1];
      if (_cards[a].emoji == _cards[b].emoji) {
        _matched.addAll([a, b]);
      } else {
        _cards[a].faceUp = false;
        _cards[b].faceUp = false;
      }
      _flipped.clear();
      _checking = false;

      if (_matched.length == _cards.length) {
        _timer.stop();
        _ticker.cancel();
        if (mounted) _showComplete();
      }
      if (mounted) setState(() {});
    }
  }

  void _showComplete() {
    final secs = _elapsed;
    final mins = secs ~/ 60;
    final rem  = secs % 60;
    final time = mins > 0 ? '${mins}m ${rem}s' : '${secs}s';
    context.go('/score/post-game', extra: {
      'game': 'Memory Card Flip',
      'moves': _moves,
      'time': time,
    });
  }

  String get _timeLabel {
    final m = _elapsed ~/ 60, s = _elapsed % 60;
    return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStats(),
            const SizedBox(height: ElderSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: ElderSpacing.sm,
                    mainAxisSpacing: ElderSpacing.sm,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (_, i) => _CardTile(
                    card: _cards[i],
                    matched: _matched.contains(i),
                    onTap: () => _onTap(i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ElderSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: ElderColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: ElderSpacing.md),
          Text(
            'Memory Card Flip',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ElderColors.primary,
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Restart game',
            child: GestureDetector(
              onTap: () => setState(() {
                _matched.clear();
                _flipped.clear();
                _moves = 0;
                _elapsed = 0;
                _buildDeck();
                _timer.reset();
                _timer.start();
              }),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ElderColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: ElderColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.touch_app_rounded,
            label: '$_moves moves',
            color: ElderColors.primary,
          ),
          const SizedBox(width: ElderSpacing.md),
          _StatChip(
            icon: Icons.timer_rounded,
            label: _timeLabel,
            color: ElderColors.tertiary,
          ),
          const Spacer(),
          _StatChip(
            icon: Icons.grid_view_rounded,
            label: '${_matched.length ~/ 2}/${_kEmojis.length} matched',
            color: ElderColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _Card {
  _Card({required this.emoji});
  final String emoji;
  bool faceUp = false;
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.matched,
    required this.onTap,
  });

  final _Card card;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: card.faceUp ? 'Card showing ${card.emoji}' : 'Face-down card',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: matched
                ? ElderColors.primaryFixed
                : card.faceUp
                    ? ElderColors.surfaceContainerLowest
                    : ElderColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ElderColors.onSurface.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: card.faceUp || matched
                ? Text(card.emoji, style: const TextStyle(fontSize: 32))
                : const Icon(
                    Icons.question_mark_rounded,
                    color: ElderColors.onPrimary,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ElderSpacing.md,
        vertical: ElderSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: ElderSpacing.xs),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets — card tiles fill grid cells (~80dp on S23 Ultra) ✅
// ✅ Font sizes ≥ 16sp — stat chips 16sp, title 24sp ✅
// ✅ Semantic labels — all cards and buttons have Semantics ✅
// ✅ Colour contrast — onPrimary on primaryContainer ✅
// ✅ Non-colour cue — matched cards: green fill + emoji visible (not just colour) ✅
