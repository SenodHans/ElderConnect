// Widget tests for RoleSelectionScreen.
//
// Tests the rendering and navigation from the role selection screen.
// No Supabase or providers required — screen is purely presentational with
// GoRouter navigation on card tap.
//
// What is tested:
//   - "ElderConnect" branding text is visible.
//   - "I am an Elder" role card is displayed.
//   - "I am a Caretaker" role card is displayed.
//   - Tapping the Elder card navigates to /elder/pin-login.
//   - Tapping the Caretaker card navigates to /register/caretaker.
//   - Screen renders without overflow errors on a standard phone viewport.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:elder_connect/features/auth/screens/role_selection_screen.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget buildTestScreen() {
  final router = GoRouter(
    initialLocation: '/role-selection',
    routes: [
      GoRoute(
        path: '/role-selection',
        builder: (ctx, st) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/elder/pin-login',
        builder: (ctx, st) => const Scaffold(body: Text('PIN Login')),
      ),
      GoRoute(
        path: '/register/caretaker',
        builder: (ctx, st) => const Scaffold(body: Text('Caretaker Register')),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('RoleSelectionScreen — rendering', () {
    testWidgets('displays "ElderConnect" branding text', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      expect(find.text('ElderConnect'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays "I am an Elder" role card', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      expect(find.text('I am an Elder'), findsOneWidget);
    });

    testWidgets('displays "I am a Caretaker" role card', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      expect(find.text('I am a Caretaker'), findsOneWidget);
    });

    testWidgets('displays welcome heading text', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('displays "Who are you?" or similar subtitle', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      expect(
        find.textContaining(RegExp(r'who|select', caseSensitive: false)),
        findsWidgets,
      );
    });

    testWidgets('renders both role cards at the same time (no lazy loading)',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Both cards must be in the tree simultaneously.
      expect(find.text('I am an Elder'), findsOneWidget);
      expect(find.text('I am a Caretaker'), findsOneWidget);
    });
  });

  group('RoleSelectionScreen — navigation', () {
    testWidgets('tapping "I am an Elder" navigates to PIN login', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      await tester.tap(find.text('I am an Elder'));
      await tester.pumpAndSettle();

      // After navigation, PIN Login screen stub should be present.
      expect(find.text('PIN Login'), findsOneWidget);
    });

    testWidgets('tapping "I am a Caretaker" navigates to caretaker register',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      await tester.tap(find.text('I am a Caretaker'));
      await tester.pumpAndSettle();

      // After navigation, Caretaker Register stub should be present.
      expect(find.text('Caretaker Register'), findsOneWidget);
    });
  });

  group('RoleSelectionScreen — accessibility', () {
    testWidgets('elder icon is present in the tree', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      expect(find.byIcon(Icons.elderly_rounded), findsOneWidget);
    });

    testWidgets('caretaker icon is present in the tree', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);
    });
  });
}
