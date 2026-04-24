/// Trivia Quiz — knowledge wellness activity for elderly users.
///
/// 10 general-knowledge questions (static dataset). Multiple choice, 4 options.
/// Score tallied and passed to /score/post-game on completion.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

class _Question {
  const _Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
  final String question;
  final List<String> options;
  final int correctIndex;
}

const _kQuestions = [
  _Question(
    question: 'Which planet is known as the Red Planet?',
    options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
    correctIndex: 1,
  ),
  _Question(
    question: 'How many sides does a hexagon have?',
    options: ['5', '6', '7', '8'],
    correctIndex: 1,
  ),
  _Question(
    question: 'What is the capital city of Australia?',
    options: ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
    correctIndex: 2,
  ),
  _Question(
    question: 'Which instrument has 88 keys?',
    options: ['Violin', 'Guitar', 'Piano', 'Flute'],
    correctIndex: 2,
  ),
  _Question(
    question: 'In which ocean is the island of Madagascar?',
    options: ['Atlantic', 'Pacific', 'Indian', 'Arctic'],
    correctIndex: 2,
  ),
  _Question(
    question: 'How many minutes are in one hour?',
    options: ['30', '45', '60', '90'],
    correctIndex: 2,
  ),
  _Question(
    question: 'What colour is the sky on a clear day?',
    options: ['Green', 'Blue', 'Purple', 'White'],
    correctIndex: 1,
  ),
  _Question(
    question: 'Which animal is known as the "King of the Jungle"?',
    options: ['Tiger', 'Elephant', 'Lion', 'Leopard'],
    correctIndex: 2,
  ),
  _Question(
    question: 'How many months are in a year?',
    options: ['10', '11', '12', '13'],
    correctIndex: 2,
  ),
  _Question(
    question: 'What do bees produce?',
    options: ['Milk', 'Honey', 'Wax only', 'Silk'],
    correctIndex: 1,
  ),
];

class TriviaQuizScreen extends StatefulWidget {
  const TriviaQuizScreen({super.key});

  @override
  State<TriviaQuizScreen> createState() => _TriviaQuizScreenState();
}

class _TriviaQuizScreenState extends State<TriviaQuizScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  int _score = 0;
  int? _chosen;          // selected option index for current question
  bool _answered = false;

  late final AnimationController _anim;
  late final Animation<double> _slideIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
    _slideIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onOption(int i) {
    if (_answered) return;
    final correct = _kQuestions[_current].correctIndex == i;
    setState(() {
      _chosen = i;
      _answered = true;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_current == _kQuestions.length - 1) {
      context.go('/score/post-game', extra: {
        'game': 'Trivia Quiz',
        'score': _score,
        'total': _kQuestions.length,
      });
      return;
    }
    setState(() {
      _current++;
      _chosen = null;
      _answered = false;
    });
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final q = _kQuestions[_current];
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildProgress(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ElderSpacing.lg),
                child: FadeTransition(
                  opacity: _slideIn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: ElderSpacing.lg),
                      // Question card
                      Container(
                        padding: const EdgeInsets.all(ElderSpacing.xl),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [ElderColors.primary, ElderColors.primaryContainer],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${_current + 1} of ${_kQuestions.length}',
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                color: ElderColors.onPrimary.withValues(alpha: 0.80),
                              ),
                            ),
                            const SizedBox(height: ElderSpacing.md),
                            Text(
                              q.question,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: ElderColors.onPrimary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ElderSpacing.xl),
                      // Options
                      ...List.generate(q.options.length, (i) {
                        Color bg = ElderColors.surfaceContainerLowest;
                        Color border = ElderColors.outlineVariant;
                        Color textColor = ElderColors.onSurface;
                        if (_answered) {
                          if (i == q.correctIndex) {
                            bg = ElderColors.primaryFixed;
                            border = ElderColors.primary;
                            textColor = ElderColors.primary;
                          } else if (i == _chosen && i != q.correctIndex) {
                            bg = ElderColors.errorContainer;
                            border = ElderColors.error;
                            textColor = ElderColors.onErrorContainer;
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: ElderSpacing.md),
                          child: Semantics(
                            button: true,
                            label: q.options[i],
                            child: GestureDetector(
                              onTap: () => _onOption(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(ElderSpacing.lg),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: border, width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: border.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          String.fromCharCode(65 + i), // A B C D
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: ElderSpacing.md),
                                    Expanded(
                                      child: Text(
                                        q.options[i],
                                        style: GoogleFonts.lexend(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (_answered && i == q.correctIndex)
                                      const Icon(Icons.check_circle_rounded,
                                          color: ElderColors.primary, size: 24),
                                    if (_answered && i == _chosen && i != q.correctIndex)
                                      Icon(Icons.cancel_rounded,
                                          color: ElderColors.error, size: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            // Next / Finish button
            if (_answered)
              Padding(
                padding: const EdgeInsets.all(ElderSpacing.lg),
                child: Semantics(
                  button: true,
                  label: _current == _kQuestions.length - 1
                      ? 'See your results'
                      : 'Next question',
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
                          _current == _kQuestions.length - 1
                              ? 'See Results'
                              : 'Next Question',
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
            'Trivia Quiz',
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
              color: ElderColors.primaryFixed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Score: $_score',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ElderColors.primary,
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
          value: (_current + 1) / _kQuestions.length,
          backgroundColor: ElderColors.surfaceContainerHighest,
          valueColor: const AlwaysStoppedAnimation(ElderColors.primary),
          minHeight: 8,
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets — options padded to ≥56dp height ✅
// ✅ Font sizes ≥ 16sp — question 24sp, options 18sp, labels 16sp ✅
// ✅ Semantic labels on all options and buttons ✅
// ✅ Non-colour cue — correct: check icon; wrong: X icon (not colour alone) ✅
// ✅ Colour contrast — onPrimary on gradient card ✅
