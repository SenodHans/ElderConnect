/// Email Verification Modal — shown after caretaker registration when Supabase
/// email confirmation is enabled.
///
/// Slides up from below with a backdrop blur. Lets the caretaker resend the
/// link and confirm once they have clicked it in their inbox.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../shared/widgets/blur_modal.dart';
import '../providers/auth_provider.dart';

/// Presents the email-verification modal over the current screen.
///
/// [email] and [password] are passed in so the modal can attempt sign-in once
/// the caretaker confirms they clicked the link. On success it navigates to
/// [onVerified] destination (defaults to /post-registration).
Future<void> showEmailVerificationModal(
  BuildContext context,
  WidgetRef ref, {
  required String email,
  required String password,
  String destination = '/post-registration',
}) {
  return showBlurModal(
    context: context,
    barrierDismissible: false,
    builder: (ctx, animation) => _EmailVerificationModal(
      animation: animation,
      email: email,
      password: password,
      destination: destination,
      ref: ref,
    ),
  );
}

// ---------------------------------------------------------------------------

class _EmailVerificationModal extends ConsumerStatefulWidget {
  const _EmailVerificationModal({
    required this.animation,
    required this.email,
    required this.password,
    required this.destination,
    required this.ref,
  });

  final Animation<double> animation;
  final String email;
  final String password;
  final String destination;
  final WidgetRef ref;

  @override
  ConsumerState<_EmailVerificationModal> createState() =>
      _EmailVerificationModalState();
}

class _EmailVerificationModalState
    extends ConsumerState<_EmailVerificationModal> {
  bool _isVerifying = false;
  bool _isResending = false;
  bool _resentSuccess = false;
  String? _errorMessage;

  /// Tries to sign in — succeeds only once the email link has been clicked.
  Future<void> _onIveVerified() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      final service = widget.ref.read(authServiceProvider);
      await service.signInCaretaker(
        email: widget.email,
        password: widget.password,
      );
      await service.saveLastRole('caretaker');
      if (mounted) {
        Navigator.of(context).pop();
        context.go(widget.destination);
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      setState(() {
        _errorMessage = msg.contains('not confirmed')
            ? 'Email not yet confirmed. Check your inbox and click the link.'
            : 'Sign-in failed: ${e.message}';
      });
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _onResend() async {
    setState(() {
      _isResending = true;
      _resentSuccess = false;
      _errorMessage = null;
    });
    try {
      await widget.ref
          .read(authServiceProvider)
          .resendVerificationEmail(widget.email);
      if (mounted) setState(() => _resentSuccess = true);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not resend. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ─────────────────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: ElderColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 36,
                    color: ElderColors.onPrimaryFixedVariant,
                  ),
                ),

                const SizedBox(height: ElderSpacing.lg),

                // ── Title ─────────────────────────────────────────────────
                Text(
                  'Check your email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: ElderSpacing.sm),

                // ── Subtitle ──────────────────────────────────────────────
                Text(
                  'We sent a verification link to',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: ElderColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: ElderSpacing.xl),

                // ── "I've verified" button ────────────────────────────────
                Semantics(
                  button: true,
                  label: "I've verified my email",
                  child: GestureDetector(
                    onTap: _isVerifying ? null : _onIveVerified,
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
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: ElderColors.onPrimary,
                                ),
                              )
                            : Text(
                                "I've verified my email",
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

                // ── Error message ─────────────────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: ElderSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: ElderColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: ElderSpacing.md),

                // ── Divider ───────────────────────────────────────────────
                Container(
                  height: 1,
                  color: ElderColors.outlineVariant.withValues(alpha: 0.30),
                ),

                const SizedBox(height: ElderSpacing.md),

                // ── Resend row ────────────────────────────────────────────
                if (_resentSuccess)
                  Text(
                    'Link resent! Check your inbox.',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: ElderColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive it? ",
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: ElderColors.onSurfaceVariant,
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Resend verification email',
                        child: GestureDetector(
                          onTap: _isResending ? null : _onResend,
                          child: Text(
                            _isResending ? 'Sending…' : 'Resend link',
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ElderColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
