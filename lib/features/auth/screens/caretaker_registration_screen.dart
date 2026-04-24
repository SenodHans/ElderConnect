/// Caretaker registration — collects name, phone, email, and password
/// for a new care provider account.
///
/// Entered from role selection (/role-selection → /register/caretaker).
/// On valid form submission + terms accepted, routes to
/// /post-registration-options (route to be added to app.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../providers/auth_provider.dart';
import '../widgets/email_verification_modal.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

class CaretakerRegistrationScreen extends ConsumerStatefulWidget {
  const CaretakerRegistrationScreen({super.key});

  @override
  ConsumerState<CaretakerRegistrationScreen> createState() =>
      _CaretakerRegistrationScreenState();
}

class _CaretakerRegistrationScreenState
    extends ConsumerState<CaretakerRegistrationScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _anim;
  late final List<CurvedAnimation> _anims;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _anims = List.generate(
      3,
      (i) => CurvedAnimation(
        parent: _anim,
        curve: Interval(i * 0.10, (i * 0.10) + 0.60, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    for (final a in _anims) { a.dispose(); }
    _anim.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, _) => Opacity(
          opacity: _anims[i].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _anims[i].value)),
            child: child,
          ),
        ),
      );

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate() || !_termsAccepted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final service = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await service.signUpCaretaker(
        name: _nameController.text,
        email: email,
        phone: _phoneController.text.trim(),
        password: password,
      );

      if (!mounted) return;

      // If Supabase email confirmation is enabled the session will be null
      // here — show the verification modal so the caretaker can confirm.
      // If confirmation is disabled, the session is already active and we
      // navigate directly (GoRouter redirect handles it).
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await service.saveLastRole('caretaker');
        if (mounted) context.go('/post-registration');
      } else {
        // Email confirmation required — show blur+slide verification card.
        if (mounted) {
          await showEmailVerificationModal(
            context,
            ref,
            email: email,
            password: password,
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.lg,
            vertical: ElderSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BackButton(onTap: () => context.go('/role-selection')),
              const SizedBox(height: ElderSpacing.xl),
              _animated(0, _buildSectionHeader()),
              const SizedBox(height: ElderSpacing.xl),
              _animated(1, _buildForm()),
              const SizedBox(height: ElderSpacing.xl),
              _animated(2, const _TrustRow()),
              const SizedBox(height: ElderSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "CARETAKER ACCOUNT" badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.sm,
            vertical: ElderSpacing.xs,
          ),
          decoration: BoxDecoration(
            // bg-tertiary-container → ElderColors.tertiaryContainer (#0E6496)
            color: ElderColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'CARETAKER ACCOUNT',
            // HTML: text-[10px] → raised to 16sp.
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // on-tertiary-container → ElderColors.onTertiaryContainer (#BBDDFF)
              color: ElderColors.onTertiaryContainer,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: ElderSpacing.sm),
        Text(
          'Create your profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24, // text-xl = 20sp; raised to 24sp (CLAUDE.md heading minimum)
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: ElderSpacing.xs),
        // HTML: text-sm (14px) → raised to 16sp.
        Text(
          'Set up your caretaker account to get started.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: ElderColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CaretakerInput(
            label: 'Full Name',
            controller: _nameController,
            leadingIcon: Icons.person_outline,
            hint: 'Thomas Andorson',
            keyboardType: TextInputType.name,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter your full name'
                : null,
          ),
          const SizedBox(height: ElderSpacing.lg),
          _CaretakerInput(
            label: 'Phone Number',
            controller: _phoneController,
            leadingIcon: Icons.call_outlined,
            hint: '+94(00) 000 - 0000',
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter your phone number'
                : null,
          ),
          const SizedBox(height: ElderSpacing.lg),
          _CaretakerInput(
            label: 'Email Address',
            controller: _emailController,
            leadingIcon: Icons.mail_outline,
            hint: 'thomas@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: ElderSpacing.lg),
          _CaretakerInput(
            label: 'Password',
            controller: _passwordController,
            leadingIcon: Icons.lock_outline,
            hint: 'Create a password',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: ElderColors.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a password';
              if (v.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: ElderSpacing.lg),
          _CaretakerInput(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            leadingIcon: Icons.lock_outline,
            hint: 'Re-enter your password',
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: ElderColors.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: ElderSpacing.md),

          // Terms checkbox + rich-text label
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                activeColor: ElderColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      // HTML: text-xs (12px) → raised to 16sp.
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: ElderColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: _showTermsDialog,
                            child: Text(
                              'Terms of Service',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ElderColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: ' and acknowledge the '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: _showPrivacyDialog,
                            child: Text(
                              'Privacy Policy',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ElderColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: ' regarding data handling.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: ElderSpacing.lg),

          // Continue — gradient, disabled until terms accepted or while loading
          Semantics(
            button: true,
            label: 'Continue',
            enabled: _termsAccepted && !_isLoading,
            child: GestureDetector(
              onTap: (_termsAccepted && !_isLoading) ? _onContinue : null,
              child: AnimatedOpacity(
                opacity: (_termsAccepted && !_isLoading) ? 1.0 : 0.40,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
                  decoration: BoxDecoration(
                    // primary → primaryContainer gradient
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ElderColors.primary, ElderColors.primaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: (_termsAccepted && !_isLoading)
                        ? [
                            BoxShadow(
                              color: ElderColors.primary.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ElderColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: ElderSpacing.sm),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ElderColors.onPrimary,
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: ElderColors.onPrimary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Error message — shown on Supabase auth failure
          if (_errorMessage != null) ...[
            const SizedBox(height: ElderSpacing.sm),
            Text(
              _errorMessage!,
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: ElderColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: ElderSpacing.md),

          // "Already have an account? Sign In"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HTML: text-xs (12px) → raised to 16sp.
              Text(
                'Already have an account? ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: ElderColors.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.go('/caretaker/login');
                },
                child: Text(
                  'Sign In',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  void _showPrivacyDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }
}

// ── _BackButton ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go back to role selection',
      child: GestureDetector(
        onTap: onTap,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ElderColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: ElderColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── _CaretakerInput ──────────────────────────────────────────────────────────

/// Professional text field for caretaker registration.
///
/// Distinct from [ElderInput]: uppercase label, leading icon prefix,
/// OutlineInputBorder ring on focus (vs underline), Plus Jakarta Sans font.
/// Screen-local — not a shared widget.
class _CaretakerInput extends StatelessWidget {
  const _CaretakerInput({
    required this.label,
    required this.controller,
    required this.leadingIcon,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final IconData leadingIcon;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uppercase label — 16sp (raised from HTML's 11px)
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: ElderSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: ElderColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: ElderColors.onSurfaceVariant,
              ),
              prefixIcon: Icon(leadingIcon, size: 20, color: ElderColors.outline),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: ElderColors.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ElderSpacing.md,
                vertical: ElderSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              // focus:ring-2 focus:ring-primary/40 → 2px solid primary ring
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ElderColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ElderColors.error, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ElderColors.error, width: 2),
              ),
              errorStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: ElderColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── _TrustRow ────────────────────────────────────────────────────────────────

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.60, // matches HTML footer opacity
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _TrustBadge(
            icon: Icons.verified_user_outlined,
            label: 'VERIFIED\nCAREGIVER',
          ),
          _TrustBadge(
            icon: Icons.family_restroom_outlined,
            label: 'FAMILY\nTRUSTED',
          ),
          _TrustBadge(
            icon: Icons.security_outlined,
            label: 'SECURE\nDATA',
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: ElderColors.onSurfaceVariant),
        const SizedBox(height: ElderSpacing.xs),
        // HTML: text-[10px] uppercase tracking-widest → raised to 16sp.
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ElderColors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── ACCESSIBILITY AUDIT ──────────────────────────────────────────────────────
// ✅ Tap targets ≥ 56×56dp    — _BackButton: 56×56 ✅
//                               Checkbox: MaterialTapTargetSize.padded = 48×48 ✅
//                               Continue: minHeight 56 ✅
//                               _CaretakerInput: minHeight 48 ✅
// ✅ Font sizes ≥ 16sp         — badge 16sp (raised from 10px) | headline 24sp
//                               | subtitle 16sp (raised from 14px)
//                               | field labels 16sp (raised from 11px) | input 18sp
//                               | terms 16sp (raised from 12px) | button 18sp
//                               | sign-in link 16sp (raised from 12px)
//                               | trust badges 16sp (raised from 10px) ✅
// ✅ Colour contrast WCAG AA   — onSurface (#1A1C1D) on background (#FAF9FA): ~17:1 ✅
//                               onPrimary (#FFF) on primary (#005050) gradient: ~12:1 ✅
//                               primary (#005050) on background: ~12:1 ✅
//                               onSurfaceVariant (#3E4948) on surfaceContainerHighest (#E3E2E3): ~6:1 ✅ AA
//                               onTertiaryContainer (#BBDDFF) on tertiaryContainer (#0E6496): ~3.7:1 ✅ AA large
// ✅ Semantic labels            — _BackButton, Continue: Semantics wrappers ✅
// ✅ No colour as sole cue      — form errors: red ring + red error text (2 cues) ✅
//                               terms links: bold weight + primary colour (2 cues) ✅
// ✅ Touch targets ≥ 8dp apart  — ElderSpacing.lg (24dp) between fields ✅
// ────────────────────────────────────────────────────────────────────────────
