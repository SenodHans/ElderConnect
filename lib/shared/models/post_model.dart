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
    this.authorAvatarUrl,
  });

  final String id;
  final String userId;

  /// Resolved from `users.full_name` via the Supabase join query.
  final String authorName;

  /// Resolved from `users.avatar_url` — null if the author has no photo.
  final String? authorAvatarUrl;
  final String content;
  final String? photoUrl;
  final DateTime createdAt;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Parses a Supabase row returned by:
  ///   `posts.select('*, users!user_id(full_name, avatar_url)')`
  factory PostModel.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: users?['full_name'] as String? ?? 'Someone',
      authorAvatarUrl: users?['avatar_url'] as String?,
      content: json['content'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
