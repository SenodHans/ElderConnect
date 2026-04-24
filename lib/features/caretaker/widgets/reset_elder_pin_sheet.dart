/// Reset Elder PIN Sheet — caretaker portal action for setting a new 4-digit
/// PIN for a linked elder.
///
/// Two-step flow: enter new PIN → confirm PIN → write to Supabase.
/// Uses the same blur-modal presentation as the caretaker auth modals.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/blur_modal.dart';

/// Presents the reset-PIN sheet over the elder management screen.
///
/// [elderId] is the Supabase UUID of the elder whose PIN will be changed.
/// [elderName] is used in the heading so the caretaker knows who they're
/// resetting for (important when managing multiple elders).
Future<void> showResetElderPinSheet(
  BuildContext context,
  WidgetRef ref, {
  required String elderId,
  required String elderName,
  String? currentPin,
}) {
  return showBlurModal(
    context: context,
    builder: (ctx, animation) => _ResetElderPinSheet(
      ref: ref,
      elderId: elderId,
      elderName: elderName,
      currentPin: currentPin,
    ),
  );
}

// ---------------------------------------------------------------------------

enum _PinStep { viewCurrent, enterNew, confirm, success }

class _ResetElderPinSheet extends ConsumerStatefulWidget {
  const _ResetElderPinSheet({
    required this.ref,
    required this.elderId,
    required this.elderName,
    this.currentPin,
  });

  final WidgetRef ref;
  final String elderId;
  final String elderName;
  final String? currentPin;

  @override
  ConsumerState<_ResetElderPinSheet> createState() =>
      _ResetElderPinSheetState();
}

class _ResetElderPinSheetState extends ConsumerState<_ResetElderPinSheet> {
  late _PinStep _step;
  String _newPin = '';
  bool _isSaving = false;
  bool _hasMismatch = false;
  bool _pinVisible = false;

  @override
  void initState() {
    super.initState();
    // If elder has a current PIN, show it first; otherwise go straight to entry.
    _step = widget.currentPin != null
        ? _PinStep.viewCurrent
        : _PinStep.enterNew;
  }

  // ── Digit entry ───────────────────────────────────────────────────────────

  void _onDigit(int digit) {
    final current = _step == _PinStep.enterNew ? _newPin : _confirmPin;
    if (current.length >= 4) return;

    if (_step == _PinStep.enterNew) {
      setState(() => _newPin = _newPin + digit.toString());
      if (_newPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _step = _PinStep.confirm);
        });
      }
    } else {
      setState(() {
        _confirmPin = _confirmPin + digit.toString();
        _hasMismatch = false;
      });
      if (_confirmPin.length == 4) _onConfirmComplete();
    }
  }

  void _onBackspace() {
    if (_step == _PinStep.enterNew) {
      if (_newPin.isEmpty) return;
      setState(() => _newPin = _newPin.substring(0, _newPin.length - 1));
    } else {
      if (_confirmPin.isEmpty) return;
      setState(
        () => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1),
      );
    }
  }

  String _confirmPin = '';

  Future<void> _onConfirmComplete() async {
    if (_confirmPin != _newPin) {
      setState(() {
        _hasMismatch = true;
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.ref.read(authServiceProvider).setElderPin(
            elderId: widget.elderId,
            pin: _newPin,
          );
      if (mounted) setState(() => _step = _PinStep.success);
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasMismatch = false;
          _confirmPin = '';
          _isSaving = false;
          _step = _PinStep.enterNew;
          _newPin = '';
          // show snackbar-level error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update PIN. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(ElderSpacing.xl),
            decoration: BoxDecoration(
              color: ElderColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (_step) {
                _PinStep.viewCurrent => _buildViewCurrent(),
                _PinStep.enterNew => _buildPinEntry(
                    key: const ValueKey('enter'),
                    title: 'Set new PIN',
                    subtitle: 'Enter a new 4-digit PIN for ${widget.elderName}.',
                    currentPin: _newPin,
                    hasMismatch: false,
                  ),
                _PinStep.confirm => _buildPinEntry(
                    key: const ValueKey('confirm'),
                    title: 'Confirm PIN',
                    subtitle: 'Enter the PIN again to confirm.',
                    currentPin: _confirmPin,
                    hasMismatch: _hasMismatch,
                    showBack: true,
                  ),
                _PinStep.success => _buildSuccess(),
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── View current PIN state ────────────────────────────────────────────────

  Widget _buildViewCurrent() {
    final pin = widget.currentPin!;
    final displayed = _pinVisible ? pin : '• ' * pin.length;

    return Column(
      key: const ValueKey('viewCurrent'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Cancel',
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: ElderColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 20,
                      color: ElderColors.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: ElderSpacing.sm),
            Expanded(
              child: Text(
                'PIN for ${widget.elderName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.onSurface,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: ElderSpacing.xl),

        // PIN display card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ElderSpacing.lg),
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT PIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: ElderSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayed.trim(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.onSurface,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: _pinVisible ? 'Hide PIN' : 'Show PIN',
                    child: GestureDetector(
                      onTap: () => setState(() => _pinVisible = !_pinVisible),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ElderColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _pinVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 22,
                          color: ElderColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: ElderSpacing.md),

        Text(
          'Share this PIN with ${widget.elderName} so they can log in.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: ElderColors.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: ElderSpacing.xl),

        // Change PIN button
        Semantics(
          button: true,
          label: 'Change PIN',
          child: GestureDetector(
            onTap: () => setState(() => _step = _PinStep.enterNew),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ElderColors.tertiary, ElderColors.tertiaryContainer],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Change PIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.onTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: ElderColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 40,
            color: ElderColors.onPrimaryFixedVariant,
          ),
        ),
        const SizedBox(height: ElderSpacing.lg),
        Text(
          'PIN updated!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ElderSpacing.sm),
        Text(
          '${widget.elderName}\'s PIN has been changed.\nMake sure they know the new PIN.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: ElderColors.onSurfaceVariant,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ElderSpacing.xl),
        Semantics(
          button: true,
          label: 'Done',
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ElderColors.primary, ElderColors.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── PIN entry state ───────────────────────────────────────────────────────

  Widget _buildPinEntry({
    required Key key,
    required String title,
    required String subtitle,
    required String currentPin,
    required bool hasMismatch,
    bool showBack = false,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Row(
          children: [
            if (showBack)
              Semantics(
                button: true,
                label: 'Back to new PIN entry',
                child: GestureDetector(
                  onTap: () => setState(() {
                    _step = _PinStep.enterNew;
                    _confirmPin = '';
                    _hasMismatch = false;
                  }),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: ElderColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: ElderColors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Semantics(
                button: true,
                label: 'Cancel',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: ElderColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: ElderColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: ElderSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.onSurface,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: ElderSpacing.sm),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: ElderColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),

        const SizedBox(height: ElderSpacing.lg),

        // PIN slot display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < currentPin.length;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
              child: _PinDot(filled: filled, hasError: hasMismatch),
            );
          }),
        ),

        if (hasMismatch) ...[
          const SizedBox(height: ElderSpacing.sm),
          Text(
            'PINs don\'t match. Try again.',
            style: GoogleFonts.lexend(fontSize: 14, color: ElderColors.error),
            textAlign: TextAlign.center,
          ),
        ],

        if (_isSaving) ...[
          const SizedBox(height: ElderSpacing.md),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],

        const SizedBox(height: ElderSpacing.lg),

        // Numpad
        _Numpad(onDigit: _onDigit, onBackspace: _onBackspace),
      ],
    );
  }
}

// ── _PinDot ───────────────────────────────────────────────────────────────────

class _PinDot extends StatelessWidget {
  const _PinDot({required this.filled, this.hasError = false});
  final bool filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 56,
      height: 64,
      decoration: BoxDecoration(
        color: ElderColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          bottom: BorderSide(
            color: hasError
                ? ElderColors.error
                : (filled ? ElderColors.primary : Colors.transparent),
            width: 3,
          ),
        ),
      ),
      child: filled
          ? Align(
              alignment: const Alignment(0, 0.2),
              child: Text(
                '•',
                style: TextStyle(
                  fontSize: 32,
                  color: hasError ? ElderColors.error : ElderColors.onSurface,
                  height: 1,
                ),
              ),
            )
          : null,
    );
  }
}

// ── _Numpad ───────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onDigit, required this.onBackspace});
  final void Function(int) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NumRow(digits: const [1, 2, 3], onDigit: onDigit),
        const SizedBox(height: ElderSpacing.md),
        _NumRow(digits: const [4, 5, 6], onDigit: onDigit),
        const SizedBox(height: ElderSpacing.md),
        _NumRow(digits: const [7, 8, 9], onDigit: onDigit),
        const SizedBox(height: ElderSpacing.md),
        Row(
          children: [
            const Expanded(child: SizedBox(height: 64)),
            const SizedBox(width: ElderSpacing.md),
            Expanded(
              child: _NumKey(digit: 0, onPressed: () => onDigit(0)),
            ),
            const SizedBox(width: ElderSpacing.md),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Backspace',
                child: GestureDetector(
                  onTap: onBackspace,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: ElderColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 28,
                        color: ElderColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumRow extends StatelessWidget {
  const _NumRow({required this.digits, required this.onDigit});
  final List<int> digits;
  final void Function(int) onDigit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: ElderSpacing.md),
          Expanded(child: _NumKey(digit: digits[i], onPressed: () => onDigit(digits[i]))),
        ],
      ],
    );
  }
}

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
          duration: const Duration(milliseconds: 80),
          height: 64,
          decoration: BoxDecoration(
            color: _pressed
                ? ElderColors.surfaceContainerLow
                : ElderColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: ElderColors.onSurface.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              '${widget.digit}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
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
