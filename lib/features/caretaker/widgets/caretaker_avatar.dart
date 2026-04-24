import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../auth/providers/user_provider.dart';

class CaretakerAvatar extends ConsumerWidget {
  const CaretakerAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;

    return Semantics(
      button: true,
      label: 'Caretaker profile',
      child: GestureDetector(
        onTap: () => context.go('/profile/caretaker'),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ElderColors.tertiaryFixed,
            shape: BoxShape.circle,
            border: Border.all(
              color: ElderColors.surfaceContainerLowest,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: user?.avatarUrl != null
                ? Image.network(
                    user!.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: ElderColors.onTertiaryFixed,
                    ),
                  )
                : user != null && user.fullName.isNotEmpty
                    ? Center(
                        child: Text(
                          user.fullName[0].toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ElderColors.onTertiaryFixed,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 22,
                        color: ElderColors.onTertiaryFixed,
                      ),
          ),
        ),
      ),
    );
  }
}
