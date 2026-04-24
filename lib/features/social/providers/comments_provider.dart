/// Comment thread and comment likes for social posts.
///
/// [commentsProvider] is an AsyncNotifierProvider.family keyed by postId.
///   - Fetches comments + per-comment like counts in one pass
///   - Realtime subscription refreshes after any post_comments change
///   - [addComment()] appends optimistically then writes to DB
///   - [toggleCommentLike()] optimistically flips the like state on a comment
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentModel {
  const CommentModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.isLikedByMe,
    this.authorAvatarUrl,
  });

  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;

  CommentModel copyWith({int? likeCount, bool? isLikedByMe}) => CommentModel(
        id: id,
        userId: userId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        content: content,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      );
}

final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<CommentModel>, String>(
  CommentsNotifier.new,
);

class CommentsNotifier
    extends FamilyAsyncNotifier<List<CommentModel>, String> {
  @override
  Future<List<CommentModel>> build(String arg) async {
    final client = Supabase.instance.client;

    // Realtime channel for this post's comments
    final channel = client
        .channel('comments_$arg')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_comments',
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

  Future<List<CommentModel>> _fetch(SupabaseClient client) async {
    final me = client.auth.currentUser?.id;

    final commentRows = await client
        .from('post_comments')
        .select('*, users!user_id(full_name, avatar_url)')
        .eq('post_id', arg)
        .order('created_at', ascending: true);

    if (commentRows.isEmpty) return [];

    final commentIds = commentRows.map((r) => r['id'] as String).toList();

    // Fetch all likes for these comments in one query
    final likeRows = await client
        .from('comment_likes')
        .select('comment_id, user_id')
        .inFilter('comment_id', commentIds);

    // Build likes map: commentId → {count, isLikedByMe}
    final Map<String, ({int count, bool liked})> likesMap = {};
    for (final r in likeRows) {
      final cid = r['comment_id'] as String;
      final uid = r['user_id'] as String;
      final prev = likesMap[cid] ?? (count: 0, liked: false);
      likesMap[cid] = (count: prev.count + 1, liked: prev.liked || uid == me);
    }

    return commentRows.map((r) {
      final users = r['users'] as Map<String, dynamic>?;
      final cid = r['id'] as String;
      final likes = likesMap[cid] ?? (count: 0, liked: false);
      return CommentModel(
        id: cid,
        userId: r['user_id'] as String,
        authorName: users?['full_name'] as String? ?? 'Someone',
        authorAvatarUrl: users?['avatar_url'] as String?,
        content: r['content'] as String,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
        likeCount: likes.count,
        isLikedByMe: likes.liked,
      );
    }).toList();
  }

  Future<void> _refetch() async {
    final result = await _fetch(Supabase.instance.client);
    state = AsyncData(result);
  }

  /// Inserts a new comment and optimistically appends it to the list.
  Future<void> addComment(String content) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // Optimistic append
    final optimistic = CommentModel(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      authorName: user.userMetadata?['full_name'] as String? ?? 'You',
      authorAvatarUrl: user.userMetadata?['avatar_url'] as String?,
      content: content,
      createdAt: DateTime.now(),
      likeCount: 0,
      isLikedByMe: false,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, optimistic]);

    try {
      await client.from('post_comments').insert({
        'post_id': arg,
        'user_id': user.id,
        'content': content,
      });
      // Realtime subscription will replace optimistic with real row
    } catch (_) {
      state = AsyncData(current); // revert
    }
  }

  /// Toggles a like on a specific comment — optimistic, no realtime needed.
  Future<void> toggleCommentLike(String commentId) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;

    final comment = current[idx];
    final liked = comment.isLikedByMe;

    // Optimistic update
    final updated = List<CommentModel>.from(current);
    updated[idx] = comment.copyWith(
      likeCount: liked
          ? (comment.likeCount - 1).clamp(0, 99999)
          : comment.likeCount + 1,
      isLikedByMe: !liked,
    );
    state = AsyncData(updated);

    try {
      if (liked) {
        await client
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', userId);
      } else {
        await client.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': userId,
        });
      }
    } catch (_) {
      state = AsyncData(current); // revert
    }
  }
}
