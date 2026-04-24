/// Love reactions on social posts.
///
/// [reactionsProvider] is an AsyncNotifierProvider.family that:
///   - Fetches the initial reaction count + liked state on first build
///   - Sets up a Supabase realtime channel for live updates
///   - Exposes [toggle()] which applies an optimistic update immediately
///     before the DB write, so the button responds on the first tap.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReactionState {
  const ReactionState({required this.count, required this.isLiked});
  final int count;
  final bool isLiked;
}

final reactionsProvider =
    AsyncNotifierProvider.family<ReactionsNotifier, ReactionState, String>(
  ReactionsNotifier.new,
);

class ReactionsNotifier extends FamilyAsyncNotifier<ReactionState, String> {
  @override
  Future<ReactionState> build(String arg) async {
    final client = Supabase.instance.client;

    // Realtime channel — updates state in the background after remote changes.
    final channel = client
        .channel('reactions_$arg')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: arg,
          ),
          callback: (_) => _refetch(),
        )
        .subscribe();

    ref.onDispose(channel.unsubscribe);

    return _fetch(client);
  }

  Future<ReactionState> _fetch(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    final rows = await client
        .from('post_reactions')
        .select('user_id')
        .eq('post_id', arg);
    return ReactionState(
      count: rows.length,
      isLiked:
          userId != null && rows.any((r) => r['user_id'] as String == userId),
    );
  }

  Future<void> _refetch() async {
    final s = await _fetch(Supabase.instance.client);
    state = AsyncData(s);
  }

  /// Optimistic toggle — updates UI immediately, then writes to DB.
  /// Reverts on error.
  Future<void> toggle() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    final current = state.valueOrNull;
    if (current == null) return;

    // Immediate optimistic update
    state = AsyncData(ReactionState(
      count: current.isLiked
          ? (current.count - 1).clamp(0, 99999)
          : current.count + 1,
      isLiked: !current.isLiked,
    ));

    try {
      if (current.isLiked) {
        await client
            .from('post_reactions')
            .delete()
            .eq('post_id', arg)
            .eq('user_id', userId);
      } else {
        await client.from('post_reactions').insert({
          'post_id': arg,
          'user_id': userId,
          'reaction': 'love',
        });
      }
    } catch (_) {
      state = AsyncData(current); // revert on failure
    }
  }
}
