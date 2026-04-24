// Widget tests for CaretakerLoginScreen form validation.
//
// These tests exercise the UI layer in isolation — no Supabase calls are made.
// We override authServiceProvider with a stub so the provider graph resolves
// without needing a live Supabase instance.
//
// What is tested:
//   - Screen renders the expected UI elements (fields, buttons, header).
//   - Empty form submission shows the correct validation error messages.
//   - Invalid email triggers the email validation error.
//   - Valid email + password allows form submission.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:elder_connect/features/auth/screens/caretaker_login_screen.dart';
import 'package:elder_connect/features/auth/providers/auth_provider.dart';
import 'package:elder_connect/features/auth/services/auth_service.dart';
import 'package:elder_connect/shared/widgets/elder_connect_logo.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Wraps the screen in the minimal widget tree required for testing:
/// GoRouter (needed for context.go), ProviderScope with authService override.
Widget buildTestScreen(AuthService mockService) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, st) => const CaretakerLoginScreen(),
      ),
      // Stub target route so navigation doesn't throw.
      GoRoute(
        path: '/home/caretaker',
        builder: (ctx, st) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/register/caretaker',
        builder: (ctx, st) => const Scaffold(body: Text('Register')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(mockService),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  group('CaretakerLoginScreen — rendering', () {
    testWidgets('displays the ElderConnect wordmark', (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));
      expect(find.byType(ElderConnectLogo), findsOneWidget);
    });

    testWidgets('displays "Caretaker Sign In" heading', (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));
      expect(find.text('Caretaker Sign In'), findsOneWidget);
    });

    testWidgets('displays email and password field labels', (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('displays Sign In and Create an Account buttons', (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create an Account'), findsOneWidget);
    });
  });

  group('CaretakerLoginScreen — form validation', () {
    testWidgets('shows email error when submitted empty', (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));

      // Tap Sign In with empty fields.
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows password error when email is filled but password empty',
        (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows invalid email error for text without @', (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'notanemail',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('no validation errors shown before first submit',
        (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));

      // Nothing typed, nothing submitted — no errors yet.
      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
    });

    testWidgets('calls signInCaretaker when form is valid', (tester) async {
      when(() => mockAuthService.signInCaretaker(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => throw const AuthException('test'));

      await tester.pumpWidget(buildTestScreen(mockAuthService));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'caretaker@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      verify(() => mockAuthService.signInCaretaker(
            email: 'caretaker@example.com',
            password: 'Password123',
          )).called(1);
    });
  });

  group('CaretakerLoginScreen — password visibility toggle', () {
    testWidgets('password field is obscured by default', (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('tapping visibility icon toggles password visibility',
        (tester) async {
      await tester.pumpWidget(buildTestScreen(mockAuthService));

      // Tap the visibility toggle icon.
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isFalse);
    });
  });
}
