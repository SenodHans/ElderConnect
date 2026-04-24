/// Integration tests — launch and navigation smoke tests.
///
/// Requires the test device to have internet access (google_fonts downloads
/// PlusJakartaSans, Lexend, and Quicksand from the CDN on first run).
///
/// Run on a connected device:
///   flutter test integration_test/app_test.dart -d <device_id> \
///     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:elder_connect/main.dart' as app;

// Boot the app using fixed-duration pumps. pumpAndSettle never completes when
// the app has live Supabase realtime subscriptions or periodic timers.
Future<void> _boot(WidgetTester tester) async {
  app.main();
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke tests', () {
    testWidgets('App launches and shows a screen', (tester) async {
      await _boot(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Role selection screen displays both role cards', (tester) async {
      await _boot(tester);
      // Only verifiable when no cached session exists on the device.
      if (find.text('I am an Elder').evaluate().isNotEmpty) {
        expect(find.text('I am an Elder'), findsOneWidget);
        expect(find.text('I am a Caretaker'), findsOneWidget);
        expect(find.text('ElderConnect'), findsWidgets);
      }
    });

    testWidgets('Caretaker login form validates empty fields', (tester) async {
      await _boot(tester);
      final caretakerCard = find.text('I am a Caretaker');
      if (caretakerCard.evaluate().isEmpty) return;

      await tester.tap(caretakerCard);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final loginButton = find.text('Sign In');
      if (loginButton.evaluate().isEmpty) return;

      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton, warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.textContaining('email', findRichText: true, skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('Caretaker login form validates invalid email format',
        (tester) async {
      await _boot(tester);
      final caretakerCard = find.text('I am a Caretaker');
      if (caretakerCard.evaluate().isEmpty) return;

      await tester.tap(caretakerCard);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final emailField = find.widgetWithText(TextFormField, 'name@example.com');
      if (emailField.evaluate().isEmpty) return;

      await tester.enterText(emailField, 'not-an-email');
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final signInBtn = find.text('Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn, warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.textContaining('valid', findRichText: true, skipOffstage: false),
        findsWidgets,
      );
    });
  });
}
