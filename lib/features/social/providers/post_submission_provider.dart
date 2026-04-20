/// Post submission with integrated mood analysis trigger.
///
/// submitPost() inserts to Supabase and fires mood analysis in the background.
/// Mood analysis is entirely non-fatal — post submission succeeds regardless.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mood/providers/mood_service_provider.dart';
import '../../mood/services/mood_service.dart';

final postSubmissionProvider =
    AsyncNotifierProvider<PostSubmissionNotifier, void>(
  PostSubmissionNotifier.new,
);

class PostSubmissionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Inserts a text post for the current user, then triggers mood analysis.
  ///
  /// Sets state to AsyncLoading while the insert is in flight.
  /// Returns (AsyncData) as soon as the DB write succeeds — mood analysis
  /// continues in the background and never delays the elder's UI.
  Future<void> submitPost({required String content}) async {
    state = const AsyncLoading();

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Insert and retrieve the generated UUID — needed for mood_logs foreign key.
      final row = await client
          .from('posts')
          .insert({'user_id': userId, 'content': content.trim()})
          .select('id')
          .single();

      state = const AsyncData(null);

      // Fire-and-forget mood analysis — never awaited by the UI.
      _analyseMood(postId: row['id'] as String, text: content.trim());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Calls mood-detection-proxy, with one automatic retry after 25s on cold start.
  void _analyseMood({required String postId, required String text}) {
    final moodService = ref.read(moodServiceProvider);
    Future(() async {
      var result = await moodService.analysePost(postId: postId, text: text);
      if (result.status == MoodStatus.loading) {
        // HuggingFace model warming up — wait 25s then retry once.
        await Future<void>.delayed(const Duration(seconds: 25));
        await moodService.analysePost(postId: postId, text: text);
        // Second attempt result is not inspected — if still loading, give up silently.
      }
      // MoodStatus.ok and MoodStatus.consentNotGiven are both silent from the elder's view.
    }).catchError((_) {
      // Mood analysis is non-fatal — never surface errors to the elder.
    });
  }
}
