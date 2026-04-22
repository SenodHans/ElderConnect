import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:elder_connect/features/mood/providers/journal_provider.dart';
import 'package:elder_connect/features/mood/services/mood_service.dart';
import 'package:elder_connect/features/mood/providers/mood_service_provider.dart';

class MockMoodService extends Mock implements MoodService {}

void main() {
  group('JournalNotifier', () {
    late MockMoodService mockMoodService;
    late ProviderContainer container;

    setUp(() {
      mockMoodService = MockMoodService();
      container = ProviderContainer(
        overrides: [
          moodServiceProvider.overrideWithValue(mockMoodService),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initial state is idle with no emoji selected', () {
      final state = container.read(journalNotifierProvider);
      expect(state.status, JournalStatus.idle);
      expect(state.selectedEmoji, isNull);
      expect(state.text, isEmpty);
    });

    test('selectEmoji updates selectedEmoji', () {
      container.read(journalNotifierProvider.notifier).selectEmoji('😄');
      expect(container.read(journalNotifierProvider).selectedEmoji, '😄');
    });

    test('selectEmoji deselects when same emoji tapped again', () {
      container.read(journalNotifierProvider.notifier).selectEmoji('😄');
      container.read(journalNotifierProvider.notifier).selectEmoji('😄');
      expect(container.read(journalNotifierProvider).selectedEmoji, isNull);
    });

    test('submit transitions to submitted on ok response', () async {
      when(() => mockMoodService.analyseJournalEntry(
            text: any(named: 'text'),
            emojiSelfReport: any(named: 'emojiSelfReport'),
          )).thenAnswer((_) async => const MoodResult(
            status: MoodStatus.ok,
            label: 'POSITIVE',
            score: 0.87,
          ));

      container.read(journalNotifierProvider.notifier).selectEmoji('😄');
      await container
          .read(journalNotifierProvider.notifier)
          .submit(text: 'I had a wonderful morning walk.');

      final state = container.read(journalNotifierProvider);
      expect(state.status, JournalStatus.submitted);
      expect(state.moodLabel, 'POSITIVE');
    });

    test('submit transitions to error on exception', () async {
      when(() => mockMoodService.analyseJournalEntry(
            text: any(named: 'text'),
            emojiSelfReport: any(named: 'emojiSelfReport'),
          )).thenThrow(Exception('network error'));

      await container
          .read(journalNotifierProvider.notifier)
          .submit(text: 'Something');

      expect(
        container.read(journalNotifierProvider).status,
        JournalStatus.error,
      );
    });

    test('reset returns to idle', () async {
      when(() => mockMoodService.analyseJournalEntry(
            text: any(named: 'text'),
            emojiSelfReport: any(named: 'emojiSelfReport'),
          )).thenAnswer((_) async => const MoodResult(
            status: MoodStatus.ok,
            label: 'NEUTRAL',
            score: 0.5,
          ));

      await container
          .read(journalNotifierProvider.notifier)
          .submit(text: 'Fine day.');
      container.read(journalNotifierProvider.notifier).reset();

      final state = container.read(journalNotifierProvider);
      expect(state.status, JournalStatus.idle);
      expect(state.selectedEmoji, isNull);
    });
  });
}
