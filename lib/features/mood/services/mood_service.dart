// MoodService — Dart layer for the mood-detection-proxy Edge Function.
//
// Called from PostsProvider after a post is successfully written to Supabase.
// Handles three response states from the function:
//   ok               → mood analysed, label + score available
//   loading          → HuggingFace model cold start — caller retries after delay
//   consent_not_given → elder has not consented to mood sharing — silent no-op
//
// Retry pattern for 'loading':
//   PostsProvider calls analysePost() → gets MoodStatus.loading
//   → waits 25 seconds → calls analysePost() once more
//   → if still loading, gives up silently (not surfaced to the elder)

import 'package:supabase_flutter/supabase_flutter.dart';

/// The three outcomes the mood-detection-proxy can return.
enum MoodStatus { ok, loading, consentNotGiven }

/// Holds the result of a mood analysis call.
class MoodResult {
  final MoodStatus status;

  /// 'POSITIVE', 'NEGATIVE', or 'NEUTRAL'. Null unless status is [MoodStatus.ok].
  final String? label;

  /// HuggingFace confidence score (0.0–1.0). Null unless status is [MoodStatus.ok].
  final double? score;

  const MoodResult({required this.status, this.label, this.score});
}

class MoodService {
  final SupabaseClient _supabase;

  const MoodService(this._supabase);

  /// Calls mood-detection-proxy with the post text and ID.
  ///
  /// [postId] must be the UUID returned by the Supabase insert — the Edge
  /// Function writes the result to mood_logs with source_post_id = postId.
  ///
  /// Returns a [MoodResult] — the caller is responsible for retry logic
  /// when status is [MoodStatus.loading].
  Future<MoodResult> analysePost({
    required String postId,
    required String text,
  }) async {
    final response = await _supabase.functions.invoke(
      'mood-detection-proxy',
      body: {'post_id': postId, 'text': text},
    );

    final data = response.data as Map<String, dynamic>;
    final status = data['status'] as String?;

    switch (status) {
      case 'ok':
        return MoodResult(
          status: MoodStatus.ok,
          label: data['label'] as String?,
          score: (data['score'] as num?)?.toDouble(),
        );
      case 'loading':
        return const MoodResult(status: MoodStatus.loading);
      case 'consent_not_given':
        return const MoodResult(status: MoodStatus.consentNotGiven);
      default:
        // Unexpected response shape — treat as loading to allow silent retry.
        return const MoodResult(status: MoodStatus.loading);
    }
  }

  /// Sends a daily journal entry for mood analysis.
  ///
  /// [emojiSelfReport] is one of 😄 🙂 😐 😔 😢 — discrepancy detection only.
  Future<MoodResult> analyseJournalEntry({
    required String text,
    String? emojiSelfReport,
  }) async {
    final response = await _supabase.functions.invoke(
      'mood-detection-proxy',
      body: {
        'source': 'daily_prompt',
        'text': text,
        if (emojiSelfReport case final report) 'emoji_self_report': report,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final status = data['status'] as String?;

    switch (status) {
      case 'ok':
        return MoodResult(
          status: MoodStatus.ok,
          label: data['label'] as String?,
          score: (data['score'] as num?)?.toDouble(),
        );
      case 'loading':
        return const MoodResult(status: MoodStatus.loading);
      case 'consent_not_given':
        return const MoodResult(status: MoodStatus.consentNotGiven);
      default:
        return const MoodResult(status: MoodStatus.loading);
    }
  }
}
