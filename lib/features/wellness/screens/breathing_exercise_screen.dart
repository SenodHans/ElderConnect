/// Breathing Exercise — guided rhythmic breathing for elderly wellness.
///
/// Animates a circle through an inhale (4s expand) → hold (4s) → exhale (6s)
/// cycle. The phase label and instruction text update in sync.
/// Elder can tap Stop at any time to return to the games screen.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';

// Durations (seconds) for each phase.
const _kInhale = 4;
const _kHold   = 4;
const _kExhale = 6;
const _kTotal  = _kInhale + _kHold + _kExhale;

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;   // 0.6 → 1.0 → 1.0 → 0.6
  late final Animation<double> _opacity; // ring pulse

  int _cycles = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _kTotal),
    );

    // Breathing scale: inhale expands, hold stays large, exhale contracts.
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.55, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: _kInhale.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: _kHold.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.55).chain(CurveTween(curve: Curves.easeInOut)),
        weight: _kExhale.toDouble(),
      ),
    ]).animate(_ctrl);

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.8), weight: _kInhale.toDouble()),
      TweenSequenceItem(tween: ConstantTween(0.8), weight: _kHold.toDouble()),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.3), weight: _kExhale.toDouble()),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _cycles++);
        _ctrl.forward(from: 0);
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _phase {
    final t = _ctrl.value * _kTotal;
    if (t < _kInhale) return 'Breathe In';
    if (t < _kInhale + _kHold) return 'Hold';
    return 'Breathe Out';
  }

  String get _instruction {
    final t = _ctrl.value * _kTotal;
    if (t < _kInhale) return 'Slowly breathe in through your nose';
    if (t < _kInhale + _kHold) return 'Hold your breath gently';
    return 'Slowly breathe out through your mouth';
  }

  int get _phaseCountdown {
    final t = _ctrl.value * _kTotal;
    if (t < _kInhale) return _kInhale - t.floor();
    if (t < _kInhale + _kHold) return _kInhale + _kHold - t.floor();
    return _kTotal - t.floor();
  }

  void _togglePause() {
    setState(() => _running = !_running);
    _running ? _ctrl.forward() : _ctrl.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Phase label
                    Text(
                      _phase,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: ElderColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: ElderSpacing.sm),
                    Text(
                      _instruction,
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        color: ElderColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: ElderSpacing.xxl),

                    // Animated breathing circle
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Transform.scale(
                            scale: _scale.value * 1.15,
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ElderColors.primaryContainer
                                    .withValues(alpha: _opacity.value * 0.25),
                              ),
                            ),
                          ),
                          // Main circle
                          Transform.scale(
                            scale: _scale.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ElderColors.primary,
                                    ElderColors.primaryContainer,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ElderColors.primary.withValues(alpha: 0.30),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$_phaseCountdown',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w800,
                                    color: ElderColors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: ElderSpacing.xxl),

                    // Cycle counter
                    Text(
                      _cycles == 0 ? 'Starting your session…' : '$_cycles cycle${_cycles == 1 ? '' : 's'} completed',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(ElderSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: _running ? 'Pause' : 'Resume',
                      child: GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: ElderColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 32,
                              color: ElderColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ElderSpacing.md),
                  Expanded(
                    flex: 2,
                    child: Semantics(
                      button: true,
                      label: 'Stop session',
                      child: GestureDetector(
                        onTap: () => context.go('/games/elder'),
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
                              'Stop Session',
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
            'Breathing Exercise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ElderColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48dp — pause/stop buttons 64dp height, full-width ✅
// ✅ Font sizes ≥ 16sp — phase label 32sp, instruction 18sp, counter 18sp ✅
// ✅ Semantic labels on all controls ✅
// ✅ Colour contrast — onPrimary on primary gradient ✅
// ✅ Non-colour cue — countdown number + text label communicate phase ✅
