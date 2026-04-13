import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/elder_registration_screen.dart';
import 'features/auth/screens/interest_selection_screen.dart';
import 'features/auth/screens/post_registration_options_screen.dart';
import 'features/auth/screens/caretaker_registration_screen.dart';
import 'features/auth/screens/caretaker_login_screen.dart';
import 'features/auth/screens/elder_pin_login_screen.dart';

/// Root application widget.
/// Role-based routing: elderly → ElderlyShell, caretaker → CaretakerShell
class ElderConnectApp extends ConsumerWidget {
  const ElderConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ElderConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Auth flow ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),

    // ── Elder auth ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/register/elder',
      builder: (context, state) => const ElderRegistrationScreen(),
    ),
    GoRoute(
      path: '/interest-selection',
      builder: (context, state) => const InterestSelectionScreen(),
    ),
    GoRoute(
      path: '/elder/pin-login',
      builder: (context, state) => const ElderPinLoginScreen(),
    ),

    // ── Caretaker auth ─────────────────────────────────────────────────────
    GoRoute(
      path: '/register/caretaker',
      builder: (context, state) => const CaretakerRegistrationScreen(),
    ),
    GoRoute(
      path: '/caretaker/login',
      builder: (context, state) => const CaretakerLoginScreen(),
    ),
    GoRoute(
      path: '/post-registration',
      builder: (context, state) => const PostRegistrationOptionsScreen(),
    ),

    // ── Portal placeholders (Batch 2 / 3) ─────────────────────────────────
    GoRoute(
      path: '/home/elder',
      builder: (context, state) =>
          const _PlaceholderScreen(label: 'Elder Home — coming in Batch 2'),
    ),
    GoRoute(
      path: '/home/caretaker',
      builder: (context, state) =>
          const _PlaceholderScreen(label: 'Caretaker Dashboard — coming in Batch 3'),
    ),
  ],
);

/// Temporary placeholder used for routes whose screens are not yet built.
/// Replaced screen-by-screen as the auth and portal flows are implemented.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // ElderColors.backgroundWarm
      body: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
