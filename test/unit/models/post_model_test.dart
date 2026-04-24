// Unit tests for PostModel.fromJson
//
// The posts table is joined with users!user_id(full_name) in the query.
// These tests verify parsing of both the post fields and the embedded author
// name, and confirm edge cases like missing photo_url and unknown author.

import 'package:flutter_test/flutter_test.dart';
import 'package:elder_connect/shared/models/post_model.dart';

void main() {
  group('PostModel.fromJson', () {
    final Map<String, dynamic> fullRow = {
      'id': 'post-abc',
      'user_id': 'user-xyz',
      'content': 'Had a lovely morning walk today.',
      'photo_url': 'https://example.com/photo.jpg',
      'created_at': '2024-06-01T10:30:00.000Z',
      'users': {'full_name': 'Eleanor Riggs'},
    };

    test('parses all fields from a full row', () {
      final post = PostModel.fromJson(fullRow);
      expect(post.id, 'post-abc');
      expect(post.userId, 'user-xyz');
      expect(post.content, 'Had a lovely morning walk today.');
      expect(post.photoUrl, 'https://example.com/photo.jpg');
      expect(post.authorName, 'Eleanor Riggs');
    });

    test('createdAt is parsed as local DateTime', () {
      final post = PostModel.fromJson(fullRow);
      expect(post.createdAt, isA<DateTime>());
      expect(post.createdAt.year, 2024);
      expect(post.createdAt.month, 6);
    });

    test('photoUrl is null when absent', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['photo_url'] = null;
      final post = PostModel.fromJson(row);
      expect(post.photoUrl, isNull);
    });

    test('authorName falls back to "Someone" when users join is null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['users'] = null;
      final post = PostModel.fromJson(row);
      expect(post.authorName, 'Someone');
    });

    test('authorName falls back to "Someone" when full_name is null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['users'] = {'full_name': null};
      final post = PostModel.fromJson(row);
      expect(post.authorName, 'Someone');
    });
  });

  group('PostModel computed getters', () {
    test('hasPhoto is true when photoUrl is set', () {
      final post = PostModel.fromJson({
        'id': 'p1',
        'user_id': 'u1',
        'content': 'hello',
        'photo_url': 'https://example.com/img.jpg',
        'created_at': '2024-01-01T00:00:00.000Z',
        'users': {'full_name': 'Test User'},
      });
      expect(post.hasPhoto, isTrue);
    });

    test('hasPhoto is false when photoUrl is null', () {
      final post = PostModel.fromJson({
        'id': 'p2',
        'user_id': 'u2',
        'content': 'hello',
        'photo_url': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'users': {'full_name': 'Test User'},
      });
      expect(post.hasPhoto, isFalse);
    });

    test('hasPhoto is false when photoUrl is empty string', () {
      final post = PostModel.fromJson({
        'id': 'p3',
        'user_id': 'u3',
        'content': 'hello',
        'photo_url': '',
        'created_at': '2024-01-01T00:00:00.000Z',
        'users': {'full_name': 'Test User'},
      });
      expect(post.hasPhoto, isFalse);
    });
  });
}
