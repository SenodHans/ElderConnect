// Unit tests for MoodService.analysePost
//
// MoodService is the Dart client for the mood-detection-proxy Edge Function.
// These tests verify that all three documented response shapes from the proxy
// are correctly parsed into MoodResult — without calling the real API.
//
// Response contract (from Edge Function):
//   { "status": "ok",                "label": "POSITIVE", "score": 0.987 }
//   { "status": "loading"                                                 }
//   { "status": "consent_not_given"                                       }
//   Any unexpected shape → treated as loading (safe default).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:elder_connect/features/mood/services/mood_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFunctionsClient extends Mock implements FunctionsClient {}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Wraps a map response into a FunctionResponse for test use.
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

  group('MoodService.analysePost — response parsing', () {
    test('"ok" response returns MoodStatus.ok with label and score', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({
                'status': 'ok',
                'label': 'POSITIVE',
                'score': 0.9876,
              }));

      final result = await service.analysePost(
        postId: 'post-001',
        text: 'Had a wonderful day!',
      );

      expect(result.status, MoodStatus.ok);
      expect(result.label, 'POSITIVE');
      expect(result.score, closeTo(0.9876, 0.0001));
    });

    test('"ok" response with NEGATIVE label is parsed correctly', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({
                'status': 'ok',
                'label': 'NEGATIVE',
                'score': 0.823,
              }));

      final result = await service.analysePost(
        postId: 'post-002',
        text: 'Feeling lonely today.',
      );

      expect(result.status, MoodStatus.ok);
      expect(result.label, 'NEGATIVE');
      expect(result.score, closeTo(0.823, 0.001));
    });

    test('"loading" response returns MoodStatus.loading with null label/score',
        () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'loading'}));

      final result = await service.analysePost(
        postId: 'post-003',
        text: 'Test',
      );

      expect(result.status, MoodStatus.loading);
      expect(result.label, isNull);
      expect(result.score, isNull);
    });

    test('"consent_not_given" returns MoodStatus.consentNotGiven', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'consent_not_given'}));

      final result = await service.analysePost(
        postId: 'post-004',
        text: 'Test',
      );

      expect(result.status, MoodStatus.consentNotGiven);
      expect(result.label, isNull);
      expect(result.score, isNull);
    });

    test('unexpected status defaults to MoodStatus.loading', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'unknown_value'}));

      final result = await service.analysePost(
        postId: 'post-005',
        text: 'Test',
      );

      // Safe default — never crash, never force a classification.
      expect(result.status, MoodStatus.loading);
    });

    test('null status defaults to MoodStatus.loading', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': null}));

      final result = await service.analysePost(
        postId: 'post-006',
        text: 'Test',
      );

      expect(result.status, MoodStatus.loading);
    });

    test('passes correct postId and text in request body', () async {
      when(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: any(named: 'body'),
          )).thenAnswer((_) async => _res({'status': 'loading'}));

      await service.analysePost(
        postId: 'post-verify',
        text: 'Some content to analyse.',
      );

      verify(() => mockFunctions.invoke(
            'mood-detection-proxy',
            body: {
              'post_id': 'post-verify',
              'text': 'Some content to analyse.',
            },
          )).called(1);
    });
  });
}
