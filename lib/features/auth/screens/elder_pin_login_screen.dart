/// Elder PIN Login — high-visibility variant for elderly users.
///
/// Fallback screen shown after session expiry or app reinstall.
/// Not a daily login screen — per auth spec, elder sessions persist
/// indefinitely. PIN validation deferred to backend sprint.
///
/// Stitch folder: elder_pin_login_high_visibility
/// HTML comment: "Significantly increased font size and weight for legibility"
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../providers/auth_provider.dart';

// Stitch config: rounded-2xl = 1.25rem = 20dp, rounded-xl = 0.75rem = 12dp.
const double _kKeyRadius = 20.0;   // rounded-2xl — numpad keys
const double _kSlotRadius = 12.0;  // rounded-xl — PIN slot containers

// Stitch config: w-16 = 64dp, h-20 = 80dp, h-[84px] = 84dp.
const double _kSlotWidth = 64.0;
const double _kSlotHeight = 80.0;
const double _kKeyHeight = 84.0;

const int _kPinLength = 4;

class ElderPinLoginScreen extends ConsumerStatefulWidget {
  const ElderPinLoginScreen({super.key});

  @override
  ConsumerState<ElderPinLoginScreen> createState() =>
      _ElderPinLoginScreenState();
}

class _ElderPinLoginScreenState extends ConsumerState<ElderPinLoginScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _anim;
  late final CurvedAnimation _fadeIn;

  final List<int> _pin = [];
  bool _isVerifying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onDigit(int digit) {
    if (_pin.length >= _kPinLength) return;
    setState(() => _pin.add(digit));
    if (_pin.length == _kPinLength) _onPinComplete();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _onPinComplete() async {
    if (_isVerifying) return;
    setState(() { _isVerifying = true; _hasError = false; });

    final service = ref.read(authServiceProvider);
    final enteredPin = _pin.join();

    try {
      // Verify against the locally cached hash — no DB query needed.
      final storedHash = await service.getStoredPinHash();

      if (storedHash != null && service.verifyPinLocal(enteredPin, storedHash)) {
        // Hash matches — restore the Supabase session from secure storage.
        final session = await service.restoreElderSession();
        if (mounted && session != null) {
          context.go('/home/elder');
          return;
        }
      }

      // PIN wrong or session restore failed — clear input and show error.
      if (mounted) {
        setState(() {
          _pin.clear();
          _hasError = true;
          _isVerifying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pin.clear();
          _hasError = true;
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeIn,
          builder: (_, child) => Opacity(
            opacity: _fadeIn.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _fadeIn.value)),
              child: child,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: ElderSpacing.md), // pt-4

                    // "Welcome Back" — text-[2.5rem] = 40sp, bold, onSurface
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ElderSpacing.lg),
                      child: Text(
                        'Welcome Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 40, // text-[2.5rem]
                          fontWeight: FontWeight.bold,
                          color: ElderColors.onSurface,
                          height: 1.2, // leading-tight
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: ElderSpacing.lg), // mb-6

                    // Subtitle — text-2xl (24sp) bold, onSurfaceVariant.
                    // HTML comment: "Significantly increased font size and weight for legibility"
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ElderSpacing.lg),
                      child: Text(
                        'Enter your PIN to continue.',
                        style: GoogleFonts.lexend(
                          fontSize: 24, // text-2xl — intentionally large per HTML design comment
                          fontWeight: FontWeight.bold,
                          color: ElderColors.onSurfaceVariant,
                          height: 1.6, // leading-relaxed
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: ElderSpacing.xxl), // mb-14 ≈ 56dp → xxl (48dp)

                    _buildPinSlots(),

                    const Spacer(),

                    _buildNumPad(),

                    const SizedBox(height: ElderSpacing.xxl), // pb-12 = 48dp
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Screen-owned header: support button (left) + wordmark (center).
  /// The pr-14 on the wordmark optically balances it against the left button.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ElderSpacing.lg, // px-6 = 24dp
        vertical: ElderSpacing.xl,   // py-8 = 32dp
      ),
      child: Row(
        children: [
          // Support / help button — 56×56 circle, surfaceContainerLow bg
          Semantics(
            button: true,
            label: 'Help and Support',
            child: GestureDetector(
              onTap: () {
                // TODO(backend-sprint): open support contact flow.
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: ElderColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_outlined,
                  size: 30, // text-3xl
                  color: ElderColors.primary,
                ),
              ),
            ),
          ),

          // Wordmark — flex-1 + pr-14 to optically center against left button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 56), // pr-14 = 56dp
              child: Text(
                'ElderConnect',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, // text-2xl
                  fontWeight: FontWeight.bold,
                  color: ElderColors.primary,
                  letterSpacing: -0.5, // tracking-tight
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4 PIN slot tiles — filled slots show bullet dot with primary bottom border.
  /// Empty slots show a transparent bottom border (invisible at rest).
  /// Slots turn error colour on incorrect PIN entry.
  Widget _buildPinSlots() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_kPinLength, (i) {
            final filled = i < _pin.length;
            return Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : ElderSpacing.md, // gap-4 = 16dp
              ),
              child: _PinSlot(filled: filled, hasError: _hasError),
            );
          }),
        ),
        // Error message shown below the slots on wrong PIN
        if (_hasError) ...[
          const SizedBox(height: ElderSpacing.md),
          Text(
            'Incorrect PIN. Please try again.',
            style: GoogleFonts.lexend(
              fontSize: 16,
              color: ElderColors.error,
            ),
          ),
        ],
      ],
    );
  }

  /// 3-column numpad grid — gap-6 = 24dp, max-width 340dp.
  Widget _buildNumPad() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
        child: Column(
          children: [
            _buildNumRow(1, 2, 3),
            const SizedBox(height: ElderSpacing.lg), // gap-y-6 = 24dp
            _buildNumRow(4, 5, 6),
            const SizedBox(height: ElderSpacing.lg),
            _buildNumRow(7, 8, 9),
            const SizedBox(height: ElderSpacing.lg),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  /// Builds a row of three digit keys.
  /// Explicit int params avoid the classic Dart closure-captures-loop-variable bug.
  Widget _buildNumRow(int a, int b, int c) {
    return Row(
      children: [
        Expanded(child: _NumKey(digit: a, onPressed: () => _onDigit(a))),
        const SizedBox(width: ElderSpacing.lg), // gap-x-6 = 24dp
        Expanded(child: _NumKey(digit: b, onPressed: () => _onDigit(b))),
        const SizedBox(width: ElderSpacing.lg),
        Expanded(child: _NumKey(digit: c, onPressed: () => _onDigit(c))),
      ],
    );
  }

  /// Row 4: empty spacer | 0 | backspace
  Widget _buildBottomRow() {
    return Row(
      children: [
        // Empty cell — HTML: <div></div>
        const Expanded(child: SizedBox(height: _kKeyHeight)),
        const SizedBox(width: ElderSpacing.lg),
        Expanded(child: _NumKey(digit: 0, onPressed: () => _onDigit(0))),
        const SizedBox(width: ElderSpacing.lg),
        Expanded(child: _BackspaceKey(onPressed: _onBackspace)),
      ],
    );
  }
}

// ── _PinSlot ─────────────────────────────────────────────────────────────────

/// Single PIN entry slot.
///
/// Filled: 3px primary bottom border + bullet dot (text-4xl = 36sp).
/// Empty: transparent bottom border (visually no border at rest).
/// Error state: error-colour bottom border + error-colour dot.
class _PinSlot extends StatelessWidget {
  const _PinSlot({required this.filled, this.hasError = false});
  final bool filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? ElderColors.error
        : (filled ? ElderColors.primary : Colors.transparent);
    final dotColor = hasError ? ElderColors.error : ElderColors.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _kSlotWidth,
      height: _kSlotHeight,
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_kSlotRadius),
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 3, // border-b-[3px]
          ),
        ),
      ),
      child: filled
          ? Align(
              alignment: const Alignment(0, 0.2), // mb-2 optical baseline
              child: Text(
                '•',
                style: TextStyle(
                  fontSize: 36, // text-4xl
                  color: dotColor,
                  height: 1,
                ),
              ),
            )
          : null,
    );
  }
}

// ── _NumKey ───────────────────────────────────────────────────────────────────

/// Single numpad digit key — surfaceContainerLowest bg + shadow at rest,
/// surfaceContainerLow on press. Matches CSS `active:bg-surface-container-low`.
class _NumKey extends StatefulWidget {
  const _NumKey({required this.digit, required this.onPressed});
  final int digit;
  final VoidCallback onPressed;

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.digit}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: _kKeyHeight,
          decoration: BoxDecoration(
            color: _pressed
                ? ElderColors.surfaceContainerLow
                : ElderColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(_kKeyRadius),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: ElderColors.onSurface.withValues(alpha: 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              '${widget.digit}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32, // text-[2rem]
                fontWeight: FontWeight.bold,
                color: ElderColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── _BackspaceKey ─────────────────────────────────────────────────────────────

/// Backspace key — surfaceContainerLow bg (always, per HTML), onSurfaceVariant icon.
/// Press: surfaceVariant bg.
class _BackspaceKey extends StatefulWidget {
  const _BackspaceKey({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_BackspaceKey> createState() => _BackspaceKeyState();
}

class _BackspaceKeyState extends State<_BackspaceKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Backspace',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: _kKeyHeight,
          decoration: BoxDecoration(
            color: _pressed
                ? ElderColors.surfaceVariant
                : ElderColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(_kKeyRadius),
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 40, // text-[2.5rem]
              color: ElderColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 56×56dp    — Support button: 56×56 circle ✅
//                               _NumKey: _kKeyHeight=84dp full column width ✅
//                               _BackspaceKey: 84dp full column width ✅
//                               _PinSlot: 64×80dp (read-only display, not interactive) ✅
// ✅ Font sizes ≥ 16sp         — wordmark 24sp | "Welcome Back" 40sp
//                               | subtitle 24sp (intentionally large per HTML design comment)
//                               | digit keys 32sp | bullet dot 36sp ✅
// ✅ Colour contrast WCAG AA   — primary (#005050) on background (#FAF9FA): ~12:1 ✅ AAA
//                               onSurface (#1A1C1D) on background: ~17:1 ✅ AAA
//                               onSurface (#1A1C1D) on surfaceContainerHighest (#E3E2E3): ~13:1 ✅ AAA
//                               onSurface (#1A1C1D) on surfaceContainerLowest (#FFF): ~18:1 ✅ AAA
//                               onSurfaceVariant (#3E4948) on surfaceContainerLow (#F4F3F4): ~7:1 ✅ AAA
// ✅ Semantic labels            — Support button, all numpad keys, backspace: Semantics(button:true, label) ✅
// ✅ No colour as sole cue      — PIN slot state: filled dot + primary border (2 cues) ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.lg (24dp) gap between numpad keys ✅
//                               ElderSpacing.md (16dp) gap between PIN slots ✅
// ────────────────────────────────────────────────────────────────────────────
