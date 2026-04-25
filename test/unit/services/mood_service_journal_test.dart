// Unit tests for MoodService.analyseJournalEntry.
//
// Covers the daily_prompt flow separately from the post flow — the request
// body shape differs (no post_id, optional emoji_self_report, source field).
// Mirrors the same response-parsing matrix used for analysePost, plus
// verifying the body contract.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:elder_connect/features/mood/services/mood_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFunctionsClient extends Mock implements FunctionsClient {}

FunctionResponse _res(Map<String, dynamic> data) =>
    FunctionResponse(data: data, status: 200);

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late MoodService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockClient.functions).thenReturn(mockFunctions);
    service = MoodService(mockClient);
  });

  group('MoodService.analyseJournalEntry — response parsing', () {
    test('"ok" response with POSITIVE label is parsed correctly', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({
                'status': 'ok',
                'label': 'POSITIVE',
                'score': 0.87,
                'discrepancy_flagged': false,
              }));

      final result = await service.analyseJournalEntry(
        text: 'Today was a beautiful day.',
      );

      expect(result.status, MoodStatus.ok);
      expect(result.label, 'POSITIVE');
      expect(result.score, closeTo(0.87, 0.001));
    });

    test('"ok" response with NEGATIVE label is parsed correctly', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({
                'status': 'ok',
                'label': 'NEGATIVE',
                'score': 0.76,
                'discrepancy_flagged': true,
              }));

      final result = await service.analyseJournalEntry(
        text: 'Feeling very tired and sad.',
        emojiSelfReport: '😄',
      );

      expect(result.status, MoodStatus.ok);
      expect(result.label, 'NEGATIVE');
    });

    test('"ok" response with NEUTRAL label is parsed correctly', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({
                'status': 'ok',
                'label': 'NEUTRAL',
                'score': 0.5,
                'discrepancy_flagged': false,
              }));

      final result = await service.analyseJournalEntry(
        text: 'Just an ordinary day.',
      );

      expect(result.status, MoodStatus.ok);
      expect(result.label, 'NEUTRAL');
    });

    test('"loading" response returns MoodStatus.loading', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'loading'}));

      final result = await service.analyseJournalEntry(text: 'Test');
      expect(result.status, MoodStatus.loading);
      expect(result.label, isNull);
      expect(result.score, isNull);
    });

    test('"consent_not_given" returns MoodStatus.consentNotGiven', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'consent_not_given'}));

      final result = await service.analyseJournalEntry(text: 'Test');
      expect(result.status, MoodStatus.consentNotGiven);
    });

    test('unexpected status defaults to MoodStatus.loading (safe default)',
        () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'bogus'}));

      final result = await service.analyseJournalEntry(text: 'Test');
      expect(result.status, MoodStatus.loading);
    });

    test('null status defaults to MoodStatus.loading', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': null}));

      final result = await service.analyseJournalEntry(text: 'Test');
      expect(result.status, MoodStatus.loading);
    });
  });

  // ── Request body contract ─────────────────────────────────────────────────

  group('MoodService.analyseJournalEntry — request body', () {
    test('sends source="daily_prompt" and text without emoji when not provided',
        () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'loading'}));

      await service.analyseJournalEntry(text: 'Sample text');

      final captured = verify(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: captureAny(named: 'body'),
          )).captured.last as Map<String, dynamic>;

      expect(captured['source'], 'daily_prompt');
      expect(captured['text'], 'Sample text');
      // When no emoji provided, key is still present but value is null
      // because the Dart pattern `if (x case final v)` always matches.
      expect(captured['emoji_self_report'], isNull);
    });

    test('sends emoji_self_report when provided', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'loading'}));

      await service.analyseJournalEntry(
        text: 'All good.',
        emojiSelfReport: '🙂',
      );

      final captured = verify(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: captureAny(named: 'body'),
          )).captured.last as Map<String, dynamic>;

      expect(captured['emoji_self_report'], '🙂');
    });

    test('does NOT include post_id in the body for daily_prompt source',
        () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'loading'}));

      await service.analyseJournalEntry(text: 'Hello world');

      final captured = verify(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: captureAny(named: 'body'),
          )).captured.last as Map<String, dynamic>;

      expect(captured.containsKey('post_id'), isFalse);
    });
  });
}
