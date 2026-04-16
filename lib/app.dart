import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/elder_registration_screen.dart';
import 'features/auth/screens/interest_selection_screen.dart';
import 'features/auth/screens/post_registration_options_screen.dart';
import 'features/auth/screens/caretaker_registration_screen.dart';
import 'features/auth/screens/caretaker_login_screen.dart';
import 'features/auth/screens/elder_pin_login_screen.dart';
import 'features/elderly/screens/elder_home_screen.dart';
import 'features/social/screens/elder_feed_screen.dart';
import 'features/medications/screens/elder_medication_list_screen.dart';
import 'features/medications/screens/elder_medication_detail_screen.dart';
import 'features/wellness/screens/elder_games_screen.dart';
import 'features/elderly/screens/elder_profile_screen.dart';
import 'features/caretaker/screens/caretaker_dashboard_screen.dart';
import 'features/caretaker/screens/elder_management_screen.dart';
import 'features/caretaker/screens/manage_links_screen.dart';
import 'features/caretaker/screens/search_link_elder_screen.dart';
import 'features/caretaker/screens/mood_activity_logs_screen.dart';
import 'features/wellness/screens/post_game_score_screen.dart';
import 'features/auth/screens/elder_login_fallback_screen.dart';

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

// Routes that require an active session to access.
// Any path starting with one of these prefixes will redirect to
// /role-selection when there is no Supabase session.
const _kProtectedPrefixes = [
  '/home/',
  '/feed/',
  '/games/',
  '/profile/',
  '/medications/',
  '/elders/',
  '/links/',
  '/search/',
  '/mood-logs/',
  '/score/',
];

// Routes that are only meaningful when NOT authenticated.
// Visiting these while logged in redirects to the appropriate portal.
const _kLoginOnlyRoutes = [
  '/role-selection',
  '/register/caretaker',
  '/caretaker/login',
];

// Listens to Supabase auth state changes and notifies GoRouter to
// re-evaluate its redirect callback on sign-in / sign-out.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Initialised lazily — Supabase.instance is ready by the time build() runs.
final _authRefreshNotifier = _AuthRefreshNotifier(
  Supabase.instance.client.auth.onAuthStateChange,
);

final GoRouter _router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authRefreshNotifier,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loc = state.matchedLocation;

    // No session — block portal routes and send to role selection.
    if (session == null) {
      final isProtected = _kProtectedPrefixes.any((p) => loc.startsWith(p));
      return isProtected ? '/role-selection' : null;
    }

    // Authenticated — redirect away from login-only routes to the portal.
    if (_kLoginOnlyRoutes.contains(loc)) {
      final role = Supabase.instance.client.auth.currentUser
          ?.userMetadata?['role'] as String?;
      if (role == 'elderly') return '/home/elder';
      if (role == 'caretaker') return '/home/caretaker';
    }

    return null;
  },
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

    // ── Elder portal ───────────────────────────────────────────────────────
    GoRoute(
      path: '/feed/elder',
      builder: (context, state) => const ElderFeedScreen(),
    ),
    GoRoute(
      path: '/games/elder',
      builder: (context, state) => const ElderGamesScreen(),
    ),
    GoRoute(
      path: '/profile/elder',
      builder: (context, state) => const ElderProfileScreen(),
    ),
    GoRoute(
      path: '/medications/elder',
      builder: (context, state) => const ElderMedicationListScreen(),
    ),
    GoRoute(
      path: '/medications/elder/detail',
      builder: (context, state) => const ElderMedicationDetailScreen(),
    ),

    // ── Portal placeholders (Batch 2 / 3) ─────────────────────────────────
    GoRoute(
      path: '/home/elder',
      builder: (context, state) => const ElderHomeScreen(),
    ),
    GoRoute(
      path: '/home/caretaker',
      builder: (context, state) => const CaretakerDashboardScreen(),
    ),
    GoRoute(
      path: '/elders/caretaker',
      builder: (context, state) => const ElderManagementScreen(),
    ),
    GoRoute(
      path: '/links/caretaker',
      builder: (context, state) => const ManageLinksScreen(),
    ),
    GoRoute(
      path: '/search/elder',
      builder: (context, state) => const SearchLinkElderScreen(),
    ),
    GoRoute(
      path: '/mood-logs/caretaker',
      builder: (context, state) => const MoodActivityLogsScreen(),
    ),
    GoRoute(
      path: '/score/post-game',
      builder: (context, state) => const PostGameScoreScreen(),
    ),
    GoRoute(
      path: '/login/elder/fallback',
      builder: (context, state) => const ElderLoginFallbackScreen(),
    ),
  ],
);

