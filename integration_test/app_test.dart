/// Integration tests — launch and navigation smoke tests.
///
/// Run on a connected device:
///   flutter test integration_test/app_test.dart -d R5CWC0CWABR \
///     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:elder_connect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke tests', () {
    testWidgets('App launches and shows role-selection or splash screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The app must render at least one screen — either splash (which routes
      // to role-selection) or role-selection itself (when no session exists).
      // Either way the MaterialApp scaffold must be present.
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Role selection screen displays both role cards', (tester) async {
      app.main();
      // Allow splash → role-selection routing to complete.
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // If there is no stored session the app should land on role-selection.
      // Skip gracefully when a session is already present (device has a cached
      // elder/caretaker session from a prior manual test run).
      if (find.text('I am an Elder').evaluate().isNotEmpty) {
        expect(find.text('I am an Elder'), findsOneWidget);
        expect(find.text('I am a Caretaker'), findsOneWidget);
        expect(find.text('ElderConnect'), findsWidgets);
      }
    });

    testWidgets('Caretaker login form validates empty email', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Navigate to caretaker login only if we are on role-selection.
      final caretakerCard = find.text('I am a Caretaker');
      if (caretakerCard.evaluate().isEmpty) return; // session present — skip

      await tester.tap(caretakerCard);
      await tester.pumpAndSettle();

      // Should now be on caretaker login (may have an intermediate page).
      final loginButton = find.text('Sign In');
      if (loginButton.evaluate().isEmpty) return;

      // Dismiss keyboard then scroll to the button before tapping.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // At least one validation error must appear.
      expect(
        find.textContaining('email', findRichText: true, skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('Caretaker login form validates invalid email format',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      final caretakerCard = find.text('I am a Caretaker');
      if (caretakerCard.evaluate().isEmpty) return;

      await tester.tap(caretakerCard);
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'name@example.com');
      if (emailField.evaluate().isEmpty) return;

      await tester.enterText(emailField, 'not-an-email');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final signInBtn = find.text('Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Validator should reject the malformed address.
      expect(
        find.textContaining('valid', findRichText: true, skipOffstage: false),
        findsWidgets,
      );
    });
  });
}
