/// Forgot Password Modal — caretaker portal password-reset flow.
///
/// Slides up from below with backdrop blur. The caretaker enters their email
/// and Supabase sends a reset link. The modal shows a success state once sent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../shared/widgets/blur_modal.dart';
import '../providers/auth_provider.dart';

/// Presents the forgot-password modal over the caretaker login screen.
Future<void> showForgotPasswordModal(BuildContext context, WidgetRef ref) {
  return showBlurModal(
    context: context,
    builder: (ctx, animation) => _ForgotPasswordModal(ref: ref),
  );
}

// ---------------------------------------------------------------------------

class _ForgotPasswordModal extends ConsumerStatefulWidget {
  const _ForgotPasswordModal({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_ForgotPasswordModal> createState() =>
      _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends ConsumerState<_ForgotPasswordModal> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSending = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      await widget.ref
          .read(authServiceProvider)
          .sendPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.message,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not send reset link: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ElderSpacing.lg),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
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
              duration: const Duration(milliseconds: 300),
              child: _sent ? _buildSuccessState() : _buildInputState(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Success state ───────────────────────────────────────────────────────────

  Widget _buildSuccessState() {
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
          'Link sent!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ElderSpacing.sm),
        Text(
          'Check your inbox at\n${_emailController.text.trim()}\nand follow the link to reset your password.\n\nDon\'t see it? Check your spam folder.',
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
                color: ElderColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Input state ─────────────────────────────────────────────────────────────

  Widget _buildInputState() {
    return Column(
      key: const ValueKey('input'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row — title + close button
        Row(
          children: [
            Expanded(
              child: Text(
                'Reset password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.onSurface,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Close',
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
          ],
        ),

        const SizedBox(height: ElderSpacing.sm),
        Text(
          'Enter the email address you registered with and we\'ll send you a link to reset your password.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: ElderColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),

        const SizedBox(height: ElderSpacing.lg),

        // Email input
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email address',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ElderColors.onSurface,
                ),
              ),
              const SizedBox(height: ElderSpacing.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  color: ElderColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  hintStyle: GoogleFonts.lexend(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: ElderColors.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ElderSpacing.md,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: ElderColors.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: ElderColors.error,
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: ElderColors.error,
                      width: 2,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!v.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: ElderSpacing.sm),
          Text(
            _errorMessage!,
            style: GoogleFonts.lexend(fontSize: 14, color: ElderColors.error),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: ElderSpacing.lg),

        // Send button
        Semantics(
          button: true,
          label: 'Send reset link',
          child: GestureDetector(
            onTap: _isSending ? null : _onSend,
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
                child: _isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ElderColors.onPrimary,
                        ),
                      )
                    : Text(
                        'Send reset link',
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
}
