/// Dart model for a row from the `posts` table, joined with the author's
/// full_name from `users`. Used by [postsProvider] to drive the social feed.
library;

/// A single social post with its author's name resolved from the joined
/// users table. Immutable value object — no setters.
class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.photoUrl,
  });

  final String id;
  final String userId;

  /// Resolved from `users.full_name` via the Supabase join query.
  final String authorName;
  final String content;
  final String? photoUrl;
  final DateTime createdAt;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Parses a Supabase row returned by:
  ///   `posts.select('*, users!user_id(full_name)')`
  factory PostModel.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: users?['full_name'] as String? ?? 'Someone',
      content: json['content'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
