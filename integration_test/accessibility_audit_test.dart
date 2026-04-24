/// Accessibility audit integration tests — WCAG compliance checks.
///
/// Runs Flutter's built-in SemanticsGuideline checks on key screens:
///  - androidTapTargetGuideline  : all tap targets ≥ 48×48 logical pixels
///  - labeledTapTargetGuideline  : all interactive elements have semantic labels
///  - textContrastGuideline      : text contrast ratio ≥ WCAG 2.1 AA (4.5:1 / 3:1)
///
/// Requires the test device to have internet access (google_fonts CDN on
/// first run; subsequent runs use the on-device cache).
///
/// Run on a connected device:
///   flutter test integration_test/accessibility_audit_test.dart -d <device_id> \
///     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:elder_connect/main.dart' as app;

// Boot the app using fixed-duration pumps. pumpAndSettle never completes when
// live Supabase realtime subscriptions or periodic timers are active.
Future<void> _boot(WidgetTester tester) async {
  app.main();
  for (var i = 0; i < 80; i++) {
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
      // Skip gracefully when a cached session routes past role-selection.
      if (caretakerCard.evaluate().isEmpty) return;
      await tester.tap(caretakerCard);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
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
