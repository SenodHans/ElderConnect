/// StreamProvider exposing the social feed as a live Supabase realtime stream.
///
/// Fetches all posts joined with their author's name, ordered newest-first.
/// Re-fetches automatically on any INSERT, UPDATE, or DELETE to the posts table
/// via a Supabase postgres_changes channel subscription.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/post_model.dart';

/// StreamProvider of PostModel list — emits the full feed in reverse
/// chronological order and updates in real time when posts change.
final postsProvider = StreamProvider<List<PostModel>>((ref) {
  final client = Supabase.instance.client;
  final controller = StreamController<List<PostModel>>();

  // Fetches all posts with author name, pushes result to the stream.
  Future<void> fetch() async {
    try {
      final rows = await client
          .from('posts')
          .select('*, users!user_id(full_name, avatar_url)')
          .order('created_at', ascending: false);
      if (!controller.isClosed) {
        controller.add(rows.map(PostModel.fromJson).toList());
      }
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  // Load initial data immediately.
  fetch();

  // Subscribe to realtime changes — re-fetch on any posts table event.
  final channel = client
      .channel('posts_feed_channel')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'posts',
        callback: (_) => fetch(),
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
