import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/elder_colors.dart';
import '../../core/providers/font_scale_provider.dart';

/// "Aa" text-size toggle button for the elder portal top bar.
/// Cycles Normal → Large → XL on each tap.
class AaButton extends ConsumerWidget {
  const AaButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(fontScaleProvider);
    return Semantics(
      button: true,
      label: 'Text size: ${scale.aaLabel}. Tap to increase.',
      child: GestureDetector(
        onTap: () =>
            ref.read(fontScaleProvider.notifier).state = scale.next,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scale > 1.0
                ? ElderColors.primaryFixed
                : ElderColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              scale.aaLabel,
              // Fixed size — must not scale with textScaler itself.
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: scale > 1.0
                    ? ElderColors.primary
                    : ElderColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
