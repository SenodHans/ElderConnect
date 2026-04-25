/// Elder PIN creation — shown once at the end of first-time registration.
///
/// Two-step flow: create a 4-digit PIN → confirm it.
/// On match: bcrypt-hashes and stores the PIN in Supabase (pin_hash + pin_plain)
/// and caches the hash locally via flutter_secure_storage so session recovery
/// works offline without re-entering name or photo.
library;

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../providers/auth_provider.dart';

class ElderPinCreationScreen extends ConsumerStatefulWidget {
  const ElderPinCreationScreen({super.key});

  @override
  ConsumerState<ElderPinCreationScreen> createState() =>
      _ElderPinCreationScreenState();
}

class _ElderPinCreationScreenState
    extends ConsumerState<ElderPinCreationScreen>
    with SingleTickerProviderStateMixin {
  // Step 0 = create PIN, step 1 = confirm PIN.
  int _step = 0;
  String _firstPin = '';
  String _currentInput = '';
  bool _isLoading = false;
  bool _mismatch = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_currentInput.length >= 4 || _isLoading) return;
    setState(() {
      _currentInput += digit;
      _mismatch = false;
    });
    if (_currentInput.length == 4) _onComplete();
  }

  void _onBackspace() {
    if (_currentInput.isEmpty || _isLoading) return;
    setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  Future<void> _onComplete() async {
    if (_step == 0) {
      // Save the first entry and move to confirmation step.
      setState(() {
        _firstPin = _currentInput;
        _currentInput = '';
        _step = 1;
      });
      return;
    }

    // Confirmation step — check match.
    if (_currentInput != _firstPin) {
      setState(() { _mismatch = true; _currentInput = ''; });
      _shakeController.forward(from: 0);
      return;
    }

    // PINs match — hash and store.
    setState(() => _isLoading = true);
    try {
      final pin = _firstPin;
      final hash = BCrypt.hashpw(pin, BCrypt.gensalt());
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('No authenticated user');

      // Store in DB: hash for verification, plain for caretaker display.
      await Supabase.instance.client.from('users').update({
        'pin_hash': hash,
        'pin_plain': pin,
      }).eq('id', userId);

      // Persist session with elderId and hash so the PIN login screen can
      // always identify this elder for the DB fallback, even after reinstall.
      final authService = ref.read(authServiceProvider);
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await authService.persistElderSession(
          session,
          elderId: userId,
          pinHash: hash,
        );
      } else {
        // Fallback: at minimum cache the hash.
        await authService.updateStoredPinHash(hash);
      }

      if (mounted) context.go('/interest-selection');
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _currentInput = ''; _step = 0; _firstPin = ''; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save PIN. Please try again.',
              style: GoogleFonts.lexend(fontSize: 16)),
          backgroundColor: ElderColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: ElderSpacing.xxl),

            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: ElderColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        size: 36, color: ElderColors.primary),
                  ),
                  const SizedBox(height: ElderSpacing.lg),
                  Text(
                    _step == 0 ? 'Create Your PIN' : 'Confirm Your PIN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ElderSpacing.sm),
                  Text(
                    _step == 0
                        ? 'Choose a 4-digit PIN you will remember easily.'
                        : 'Enter your PIN again to confirm.',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      color: ElderColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: ElderSpacing.xxl),

            // ── 4 dot indicators ──────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  _mismatch ? 8 * (0.5 - _shakeAnim.value).abs() * 8 : 0,
                  0,
                ),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _currentInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: filled ? 20 : 16,
                    height: filled ? 20 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _mismatch
                          ? ElderColors.error
                          : filled
                              ? ElderColors.primary
                              : ElderColors.surfaceContainerHighest,
                      border: filled
                          ? null
                          : Border.all(color: ElderColors.outline, width: 2),
                    ),
                  );
                }),
              ),
            ),

            if (_mismatch) ...[
              const SizedBox(height: ElderSpacing.md),
              Text(
                "PINs don't match. Try again.",
                style: GoogleFonts.lexend(
                    fontSize: 16, color: ElderColors.error),
              ),
            ],

            const Spacer(),

            // ── Numpad ────────────────────────────────────────────────────────
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 64),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: ElderSpacing.xl, vertical: ElderSpacing.lg),
                child: _Numpad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Numpad ───────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: ElderSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 88, height: 88);
              return _NumpadKey(
                label: key,
                onTap: () => key == '⌫' ? onBackspace() : onDigit(key),
                isBackspace: key == '⌫',
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.label,
    required this.onTap,
    this.isBackspace = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isBackspace;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isBackspace ? 'Delete' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(44),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isBackspace
                  ? ElderColors.surfaceContainerLow
                  : ElderColors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isBackspace
                ? const Icon(Icons.backspace_outlined,
                    size: 28, color: ElderColors.onSurfaceVariant)
                : Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: ElderColors.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48dp   — numpad keys: 88×88dp ✅
// ✅ Font sizes ≥ 16sp        — heading 32sp | subtitle 18sp | key digits 32sp ✅
// ✅ Colour contrast WCAG AA  — primary (#005050) on primaryFixed: ~10:1 ✅
//                               onSurface (#1A1C1D) on surfaceContainerHighest: ~13:1 ✅
// ✅ Semantic labels           — all keys wrapped in Semantics(button:true) ✅
// ✅ No colour as sole cue     — mismatch shows text + colour ✅
// ✅ Touch targets ≥ 8dp apart — spaceEvenly with 88dp keys on ~360dp width ✅
// ────────────────────────────────────────────────────────────────────────────
