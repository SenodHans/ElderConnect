/// Elder Support Sheet — shown when the elder taps the help button on the
/// PIN login screen.
///
/// Uses the same blur-modal pattern as the caretaker modals so the visual
/// language is consistent, but the content is large-print and icon-led to
/// suit the elder audience.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../../../shared/widgets/blur_modal.dart';

/// Presents the elder support sheet over the PIN login screen.
Future<void> showElderSupportSheet(BuildContext context) {
  return showBlurModal(
    context: context,
    builder: (ctx, animation) => const _ElderSupportSheet(),
  );
}

// ---------------------------------------------------------------------------

class _ElderSupportSheet extends StatelessWidget {
  const _ElderSupportSheet();

  static const _supportEmail = 'support@elderconnect.care';
  static const _supportPhone = '+94 11 000 0000'; // placeholder — update before go-live

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _supportEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportPhone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(ElderSpacing.xl),
            decoration: BoxDecoration(
              color: ElderColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(28),
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
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: ElderColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 44,
                    color: ElderColors.onPrimaryFixedVariant,
                  ),
                ),

                const SizedBox(height: ElderSpacing.lg),

                Text(
                  'Need Help?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: ElderSpacing.sm),

                Text(
                  'Ask your caretaker to help you sign in,\nor contact us below.',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    color: ElderColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: ElderSpacing.xl),

                // ── Contact options ───────────────────────────────────────
                _ContactTile(
                  icon: Icons.phone_rounded,
                  label: 'Call Support',
                  value: _supportPhone,
                  onTap: () => _launchPhone(context),
                ),

                const SizedBox(height: ElderSpacing.md),

                _ContactTile(
                  icon: Icons.mail_rounded,
                  label: 'Email Support',
                  value: _supportEmail,
                  onTap: () => _launchEmail(context),
                ),

                const SizedBox(height: ElderSpacing.xl),

                // ── Dismiss ───────────────────────────────────────────────
                Semantics(
                  button: true,
                  label: 'Close help panel',
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: ElderColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Close',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ElderColors.onSurface,
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

// ── _ContactTile ─────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ElderSpacing.md,
            vertical: ElderSpacing.md,
          ),
          decoration: BoxDecoration(
            color: ElderColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ElderColors.outlineVariant.withValues(alpha: 0.40),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: ElderColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: ElderColors.onPrimaryFixedVariant),
              ),
              const SizedBox(width: ElderSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ElderColors.onSurface,
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        color: ElderColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: ElderColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
