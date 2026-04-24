/// Shared blur-modal helper.
///
/// [showBlurModal] presents any widget as a centred card that slides up from
/// below while the background blurs and darkens — used by the email-
/// verification and forgot-password flows, and the elder-support sheet.
library;

import 'dart:ui';
import 'package:flutter/material.dart';

/// Shows a centred modal card with a backdrop blur + slide-up animation.
///
/// [builder] receives the animation so internal elements can stagger if needed.
/// Returns whatever value the modal pops with (same as [showGeneralDialog]).
Future<T?> showBlurModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, Animation<double> animation) builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, animation, _) => builder(ctx, animation),
    transitionBuilder: (ctx, animation, _, child) {
      return Stack(
        children: [
          // ── Backdrop: blur + dark tint fades in together ──────────────
          FadeTransition(
            opacity: animation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.black.withValues(alpha: 0.42)),
            ),
          ),

          // ── Card: slides up from 30 % below and fades in ──────────────
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.30),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.7),
              ),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}
