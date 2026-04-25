/// Splash screen — entry point of ElderConnect.
///
/// Layout matches the finalised Stitch design (stitch_elderconnect_design_finalised):
///   • Pure white background
///   • Centred column: logo mark → wordmark → tagline → loading bar
///   • Auto-navigates after 2.5 s to the correct portal (or /role-selection)
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../shared/widgets/elder_connect_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _progressController;

  late final Animation<double> _logoOpacity;
  late final Animation<Offset>  _logoSlide;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    // Entry: 300 ms cap (design.md §7).
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Logo fades + rises first (0–60 % of timeline).
    _logoOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Text + bar stagger in after logo (30–100 %).
    _contentOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _entryController.forward();

    // Progress bar fills cosmetically over the 2.5 s display window.
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _progressController.forward();

    // Navigate after 2.5 s.
    // Always lands on the Welcome ("Who are you?") screen so every app open
    // starts from a clean, known state. Users must re-identify themselves via
    // PIN (elders) or email/password (caretakers) after each cold start.
    // Sessions are still persisted internally — the PIN screen restores them —
    // but we never silently bypass the Welcome screen.
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      context.go('/role-selection');
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background matching Stitch surface-container-lowest.
      backgroundColor: ElderColors.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo mark ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _logoOpacity,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: Semantics(
                      image: true,
                      label: 'ElderConnect logo',
                      child: const ElderConnectLogo(size: 160),
                    ),
                  ),
                ),

                const SizedBox(height: ElderSpacing.md),

                // ── Wordmark + tagline ─────────────────────────────────────
                FadeTransition(
                  opacity: _contentOpacity,
                  child: Column(
                    children: [
                      // Quicksand bold — brand font from Stitch design.
                      Text(
                        'ElderConnect',
                        style: GoogleFonts.quicksand(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: ElderColors.primary,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: ElderSpacing.xs),
                      Text(
                        'Staying connected, staying well.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: ElderColors.onSurfaceVariant,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: ElderSpacing.xl),

                // ── Thin loading bar (192 dp wide, 4 dp tall) ─────────────
                FadeTransition(
                  opacity: _contentOpacity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 192),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: SizedBox(
                        height: 4,
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, _) => Stack(
                            children: [
                              // Track.
                              const ColoredBox(
                                color: ElderColors.surfaceContainer,
                              ),
                              // Primary fill.
                              FractionallySizedBox(
                                widthFactor: _progress.value,
                                heightFactor: 1.0,
                                alignment: Alignment.centerLeft,
                                child: const ColoredBox(
                                  color: ElderColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets  — no interactive elements on splash; N/A.
// ✅ Font sizes   — wordmark 36sp | tagline 18sp. Both ≥ 16sp minimum.
// ✅ Contrast     — ElderColors.primary (#005050) on white (#FFF): ~12:1 ✅ AAA
//                   onSurfaceVariant (#3E4948) on white (#FFF): ~8:1 ✅ AAA
//                   primaryFixed (#A0F0F0) on primaryContainer (#006A6A): ~4.6:1 ✅ AA
// ✅ Semantics    — logo wrapped in Semantics(image: true, label: '...')
// ✅ Colour cue   — all information conveyed by text; no info via colour alone.
// ────────────────────────────────────────────────────────────────────────────
