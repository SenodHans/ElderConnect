/// Accessibility audit integration tests — WCAG compliance checks.
///
/// Runs Flutter's built-in SemanticsGuideline checks on key screens:
///  - androidTapTargetGuideline  : all tap targets ≥ 48×48 logical pixels
///  - labeledTapTargetGuideline  : all interactive elements have semantic labels
///  - textContrastGuideline      : text contrast ratio ≥ WCAG 2.1 AA (4.5:1 / 3:1)
///
/// Run on a connected device:
///   flutter test integration_test/accessibility_audit_test.dart -d R5CWC0CWABR \
///     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:elder_connect/main.dart' as app;

// Boot timeout — use pump() instead of pumpAndSettle() so that ongoing
// Supabase realtime subscriptions and periodic timers do not prevent settling.
Future<void> _boot(WidgetTester tester) async {
  app.main();
  // Give the app 6 seconds of wall-clock time to initialise Supabase and route.
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Accessibility audit — role-selection screen', () {
    testWidgets('Tap targets meet Android minimum (48×48 dp)', (tester) async {
      await _boot(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('All interactive elements have semantic labels', (tester) async {
      await _boot(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('Text contrast meets WCAG 2.1 AA', (tester) async {
      await _boot(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('Accessibility audit — caretaker login screen', () {
    Future<void> navigateToCaretakerLogin(WidgetTester tester) async {
      await _boot(tester);
      final caretakerCard = find.text('I am a Caretaker');
      // Skip gracefully when a session is already present on the device.
      if (caretakerCard.evaluate().isEmpty) return;
      await tester.tap(caretakerCard);
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('Tap targets meet Android minimum', (tester) async {
      await navigateToCaretakerLogin(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('All interactive elements have semantic labels', (tester) async {
      await navigateToCaretakerLogin(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('Text contrast meets WCAG 2.1 AA', (tester) async {
      await navigateToCaretakerLogin(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
