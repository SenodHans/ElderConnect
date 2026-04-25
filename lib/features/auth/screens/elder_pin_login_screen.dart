/// Elder PIN Login — high-visibility fallback shown after session expiry or reinstall.
///
/// Normal daily flow: session restores from flutter_secure_storage automatically.
/// This screen only appears when that restoration fails.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../providers/auth_provider.dart';

const double _kKeyRadius = 20.0;
const double _kSlotRadius = 12.0;
const double _kSlotWidth = 60.0;
const double _kSlotHeight = 72.0;
const double _kKeyHeight = 72.0; // slightly smaller to make room for buttons below
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
  bool _sendingHelp = false;

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
    if (_pin.length >= _kPinLength || _isVerifying) return;
    setState(() => _pin.add(digit));
    if (_pin.length == _kPinLength) _onPinComplete();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _onPinComplete() async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    final service = ref.read(authServiceProvider);
    final enteredPin = _pin.join().trim();

    try {
      // Sign out any existing session first so switching elders on a shared
      // device works cleanly. `signOut()` clears secure storage + Supabase
      // session — the new session is written immediately after PIN matches.
      await service.signOut();

      // Global DB lookup — find any elder whose pin_plain matches.
      // This works regardless of which device/session was last used.
      final elder = await service.findElderByPin(enteredPin);

      if (elder == null) {
        if (mounted) {
          setState(() {
            _pin.clear();
            _hasError = true;
            _isVerifying = false;
          });
        }
        return;
      }

      // Sign in with the elder's system-generated credentials.
      final session = await service.signInWithEmailAndPassword(
        email: elder['email'] as String,
        password: elder['system_password'] as String,
      );

      if (session != null) {
        await service.saveLastRole('elderly');
        if (mounted) context.go('/home/elder');
        return;
      }

      // Elder found but sign-in failed (network/server issue).
      if (mounted) {
        setState(() {
          _pin.clear();
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not sign in. Please check your connection and try again.',
              style: GoogleFonts.lexend(fontSize: 16),
            ),
            backgroundColor: ElderColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 6),
          ),
        );
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

  /// Notifies the caretaker that the elder needs help.
  ///
  /// Fast path: if a session can be restored, calls send-sos-alert (authenticated).
  /// Fallback: if no session (reinstall), shows a phone number dialog and calls
  /// send-help-request (unauthenticated, identifies elder by phone).
  Future<void> _sendHelpNotification() async {
    if (_sendingHelp) return;
    setState(() => _sendingHelp = true);

    final service = ref.read(authServiceProvider);
    try {
      var session = await service.restoreElderSession();
      session ??= await service.signInWithCachedCredentials();

      if (session != null) {
        // Authenticated path — elder is known, use send-sos-alert.
        await Supabase.instance.client.functions.invoke(
          'send-sos-alert',
          body: {'message': 'Elder needs help signing in'},
        );
        if (mounted) _showHelpSentSnackBar();
      } else {
        // Reinstall path — ask for phone number, then send unauthenticated request.
        if (mounted) await _sendHelpWithPhone(service);
      }
    } catch (_) {
      if (mounted) {
        // Fallback: still offer the phone-based path.
        await _sendHelpWithPhone(service);
      }
    } finally {
      if (mounted) setState(() => _sendingHelp = false);
    }
  }

  /// Shows a phone number dialog and calls send-help-request with the anon key.
  Future<void> _sendHelpWithPhone(dynamic service) async {
    final phoneCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter Your Phone Number',
          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We will notify your caretaker right away.',
              style: GoogleFonts.lexend(fontSize: 17, color: ElderColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: GoogleFonts.lexend(fontSize: 20),
              decoration: InputDecoration(
                hintText: '07X XXX XXXX',
                hintStyle: GoogleFonts.lexend(fontSize: 20, color: ElderColors.outline),
                filled: true,
                fillColor: ElderColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.lexend(fontSize: 18, color: ElderColors.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ElderColors.primary),
            child: Text('Send', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    final phone = phoneCtrl.text.trim();
    phoneCtrl.dispose();

    if (confirmed == true && phone.isNotEmpty && mounted) {
      final ok = await service.sendHelpRequest(phone);
      if (mounted) {
        if (ok) {
          _showHelpSentSnackBar();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Could not send notification. Please call your caretaker directly.',
              style: GoogleFonts.lexend(fontSize: 16),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    }
  }

  void _showHelpSentSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Your caretaker has been notified. They will contact you shortly.',
        style: GoogleFonts.lexend(fontSize: 16),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ElderColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ));
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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: ElderSpacing.sm),

                    // Welcome heading — generic, never shows a cached name.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ElderSpacing.lg),
                      child: Text(
                        'Welcome',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: ElderColors.onSurface,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: ElderSpacing.md),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ElderSpacing.lg),
                      child: Text(
                        'Enter your PIN to sign in.',
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: ElderColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: ElderSpacing.xl),

                    _buildPinSlots(),

                    const Spacer(),
                    const SizedBox(height: ElderSpacing.lg),

                    _buildNumPad(),

                    const SizedBox(height: ElderSpacing.lg),

                    // ── Action buttons row below numpad ───────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ElderSpacing.lg),
                      child: Row(
                        children: [
                          // Need Help — teal pill, notifies caretaker
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: 'Need help — notify my caretaker',
                              child: _sendingHelp
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24, height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : TextButton.icon(
                                      onPressed: _sendHelpNotification,
                                      icon: const Icon(
                                        Icons.notifications_active_outlined,
                                        color: ElderColors.primary,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Need Help?',
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: ElderColors.primary,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: ElderSpacing.sm),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          side: const BorderSide(
                                              color: ElderColors.primaryFixed,
                                              width: 1.5),
                                        ),
                                        backgroundColor: ElderColors.primaryFixed
                                            .withValues(alpha: 0.40),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: ElderSpacing.md),
                          // I'm New Here — green/white
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: 'I am new to ElderConnect',
                              child: TextButton(
                                onPressed: () =>
                                    context.go('/register/elder'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: ElderSpacing.sm),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: Colors.green.shade600,
                                      width: 1.5,
                                    ),
                                  ),
                                  backgroundColor:
                                      Colors.green.shade50,
                                ),
                                child: Text(
                                  "I'm New Here",
                                  style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: ElderSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ElderSpacing.lg,
        vertical: ElderSpacing.lg,
      ),
      child: Center(
        child: Text(
          'ElderConnect',
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ElderColors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPinSlots() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_kPinLength, (i) {
            final filled = i < _pin.length;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : ElderSpacing.md),
              child: _PinSlot(filled: filled, hasError: _hasError),
            );
          }),
        ),
        if (_hasError) ...[
          const SizedBox(height: ElderSpacing.sm),
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

  Widget _buildNumPad() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
        child: Column(
          children: [
            _buildNumRow(1, 2, 3),
            const SizedBox(height: ElderSpacing.md),
            _buildNumRow(4, 5, 6),
            const SizedBox(height: ElderSpacing.md),
            _buildNumRow(7, 8, 9),
            const SizedBox(height: ElderSpacing.md),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(int a, int b, int c) {
    return Row(
      children: [
        Expanded(child: _NumKey(digit: a, onPressed: () => _onDigit(a))),
        const SizedBox(width: ElderSpacing.md),
        Expanded(child: _NumKey(digit: b, onPressed: () => _onDigit(b))),
        const SizedBox(width: ElderSpacing.md),
        Expanded(child: _NumKey(digit: c, onPressed: () => _onDigit(c))),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        const Expanded(child: SizedBox(height: _kKeyHeight)),
        const SizedBox(width: ElderSpacing.md),
        Expanded(child: _NumKey(digit: 0, onPressed: () => _onDigit(0))),
        const SizedBox(width: ElderSpacing.md),
        Expanded(child: _BackspaceKey(onPressed: _onBackspace)),
      ],
    );
  }
}

// ── _PinSlot ─────────────────────────────────────────────────────────────────

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
        border: Border(bottom: BorderSide(color: borderColor, width: 3)),
      ),
      child: filled
          ? Align(
              alignment: const Alignment(0, 0.2),
              child: Text('•',
                  style: TextStyle(fontSize: 32, color: dotColor, height: 1)),
            )
          : null,
    );
  }
}

// ── _NumKey ───────────────────────────────────────────────────────────────────

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
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              '${widget.digit}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
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
            child: Icon(Icons.backspace_outlined,
                size: 32, color: ElderColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48dp — numpad keys 72dp; action buttons padded to ≥ 48dp
// ✅ Font sizes ≥ 16sp — all text 16sp+; title 36sp; numpad digits 28sp
// ✅ Colour contrast WCAG AA — primary on primaryFixed tint; green.700 on green.50
// ✅ Semantics labels on all interactive elements
// ✅ No overflow — SingleChildScrollView + IntrinsicHeight
// ✅ Two distinct button styles so colour is not the sole differentiator
