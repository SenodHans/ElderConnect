import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/font_scale_provider.dart';
import 'core/providers/high_contrast_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/elder_registration_screen.dart';
import 'features/auth/screens/interest_selection_screen.dart';
import 'features/auth/screens/post_registration_options_screen.dart';
import 'features/auth/screens/caretaker_registration_screen.dart';
import 'features/auth/screens/caretaker_login_screen.dart';
import 'features/auth/screens/elder_pin_login_screen.dart';
import 'features/auth/screens/elder_pin_creation_screen.dart';
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
import 'features/caretaker/screens/caretaker_profile_screen.dart';
import 'features/wellness/screens/post_game_score_screen.dart';
import 'features/wellness/screens/memory_card_game_screen.dart';
import 'features/wellness/screens/breathing_exercise_screen.dart';
import 'features/wellness/screens/trivia_quiz_screen.dart';
import 'features/wellness/screens/word_scramble_screen.dart';
import 'features/auth/screens/elder_login_fallback_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/mood/screens/daily_journal_screen.dart';

/// Root application widget.
/// Role-based routing: elderly → ElderlyShell, caretaker → CaretakerShell
class ElderConnectApp extends ConsumerStatefulWidget {
  const ElderConnectApp({super.key});

  @override
  ConsumerState<ElderConnectApp> createState() => _ElderConnectAppState();
}

class _ElderConnectAppState extends ConsumerState<ElderConnectApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // When the app returns to the foreground with no active session, reset to
  // the Welcome screen so navigation never strands the user mid-flow.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _router.go('/role-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final highContrast = ref.watch(highContrastProvider);
    return MaterialApp.router(
      title: 'ElderConnect',
      debugShowCheckedModeBanner: false,
      theme: highContrast ? AppTheme.highContrast : AppTheme.light,
      routerConfig: _router,
      // Applies the elder's chosen text scale across the entire app.
      builder: (context, child) => Consumer(
        builder: (context, ref, _) {
          final scale = ref.watch(fontScaleProvider);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          );
        },
      ),
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
  '/mood/',
];

// Routes that are only meaningful when NOT authenticated.
// Visiting these while logged in redirects to the appropriate portal.
// NOTE: /role-selection and /elder/pin-login are intentionally excluded —
// users can reach the Welcome screen at any time (e.g. after logout or when
// switching elders on a shared device). The PIN screen also handles its own
// sign-out before initiating a new PIN-based sign-in.
const _kLoginOnlyRoutes = [
  '/register/caretaker',
  '/caretaker/login',
];

// Listens to Supabase auth state changes and notifies GoRouter to
// re-evaluate its redirect callback on sign-in / sign-out.
// Also detects passwordRecovery events from deep links and stores
// a flag so the router can redirect to /reset-password.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((authState) {
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      }
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;
  bool _isPasswordRecovery = false;

  bool consumePasswordRecovery() {
    if (_isPasswordRecovery) {
      _isPasswordRecovery = false;
      return true;
    }
    return false;
  }

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

    // If Supabase fired a passwordRecovery event (deep link from email),
    // redirect to the set-new-password screen immediately.
    if (_authRefreshNotifier.consumePasswordRecovery()) {
      return '/reset-password';
    }

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
    ShellRoute(
      builder: (context, state, child) => _GlobalBackNavWrapper(
        currentPath: state.matchedLocation,
        child: child,
      ),
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
      path: '/register/elder/pin',
      builder: (context, state) => const ElderPinCreationScreen(),
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
    _fadeRoute('/feed/elder', const ElderFeedScreen()),
    _fadeRoute('/games/elder', const ElderGamesScreen()),
    _fadeRoute('/profile/elder', const ElderProfileScreen()),
    _fadeRoute('/medications/elder', const ElderMedicationListScreen()),
    GoRoute(
      path: '/medications/elder/detail',
      builder: (context, state) => const ElderMedicationDetailScreen(),
    ),

    // ── Portal placeholders (Batch 2 / 3) ─────────────────────────────────
    _fadeRoute('/home/elder', const ElderHomeScreen()),
    _fadeRoute('/home/caretaker', const CaretakerDashboardScreen()),
    _fadeRoute('/elders/caretaker', const ElderManagementScreen()),
    _fadeRoute('/links/caretaker', const ManageLinksScreen()),
    GoRoute(
      path: '/search/elder',
      builder: (context, state) => const SearchLinkElderScreen(),
    ),
    _fadeRoute('/mood-logs/caretaker', const MoodActivityLogsScreen()),
    GoRoute(
      path: '/score/post-game',
      builder: (context, state) => PostGameScoreScreen(
        result: (state.extra as Map<String, dynamic>?) ?? {},
      ),
    ),
    GoRoute(
      path: '/games/memory',
      builder: (context, state) => const MemoryCardGameScreen(),
    ),
    GoRoute(
      path: '/games/breathing',
      builder: (context, state) => const BreathingExerciseScreen(),
    ),
    GoRoute(
      path: '/games/trivia',
      builder: (context, state) => const TriviaQuizScreen(),
    ),
    GoRoute(
      path: '/games/scramble',
      builder: (context, state) => const WordScrambleScreen(),
    ),
    GoRoute(
      path: '/login/elder/fallback',
      builder: (context, state) => const ElderLoginFallbackScreen(),
    ),
    GoRoute(
      path: '/mood/journal',
      builder: (context, state) => const DailyJournalScreen(),
    ),
    _fadeRoute('/profile/caretaker', const CaretakerProfileScreen()),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
      ],
    ),
  ],
);

GoRoute _fadeRoute(String path, Widget screen) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    ),
  );
}

class _GlobalBackNavWrapper extends StatefulWidget {
  final String currentPath;
  final Widget child;

  const _GlobalBackNavWrapper({
    required this.currentPath,
    required this.child,
  });

  @override
  State<_GlobalBackNavWrapper> createState() => _GlobalBackNavWrapperState();
}

class _GlobalBackNavWrapperState extends State<_GlobalBackNavWrapper> {
  DateTime? _lastBackTime;

  @override
  Widget build(BuildContext context) {
    final isHome = widget.currentPath == '/home/elder' ||
        widget.currentPath == '/home/caretaker' ||
        widget.currentPath == '/role-selection' ||
        widget.currentPath == '/';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (_router.canPop()) {
          _router.pop();
          return;
        }

        if (!isHome) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            final role = Supabase.instance.client.auth.currentUser?.userMetadata?['role'] as String?;
            if (role == 'elderly') {
              _router.go('/home/elder');
            } else if (role == 'caretaker') {
              _router.go('/home/caretaker');
            } else {
              _router.go('/role-selection');
            }
          } else {
            _router.go('/role-selection');
          }
          return;
        }

        final now = DateTime.now();
        if (_lastBackTime == null || now.difference(_lastBackTime!) > const Duration(seconds: 2)) {
          _lastBackTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}

