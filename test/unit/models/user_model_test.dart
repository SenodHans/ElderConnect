// Unit tests for UserModel.fromJson
//
// Verifies that every field from the Supabase `users` table row is correctly
// parsed into the strongly-typed Dart model. Covers required fields, optional
// nullable fields, enum-like role values, list parsing (interests), and
// boolean defaults.

import 'package:flutter_test/flutter_test.dart';
import 'package:elder_connect/shared/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    // Minimal valid row — all nullable fields absent.
    final Map<String, dynamic> minimalRow = {
      'id': 'abc-123',
      'email': 'test@example.com',
      'role': 'caretaker',
      'full_name': 'Jane Smith',
      'interests': <dynamic>[],
      'tts_enabled': false,
      'mood_sharing_consent': false,
      'created_at': '2024-01-15T08:00:00.000Z',
    };

    test('parses required string fields', () {
      final model = UserModel.fromJson(minimalRow);
      expect(model.id, 'abc-123');
      expect(model.email, 'test@example.com');
      expect(model.role, 'caretaker');
      expect(model.fullName, 'Jane Smith');
    });

    test('parses boolean fields', () {
      final model = UserModel.fromJson(minimalRow);
      expect(model.ttsEnabled, isFalse);
      expect(model.moodSharingConsent, isFalse);
    });

    test('parses createdAt as DateTime', () {
      final model = UserModel.fromJson(minimalRow);
      expect(model.createdAt, isA<DateTime>());
      expect(model.createdAt.year, 2024);
    });

    test('nullable fields default to null when absent', () {
      final model = UserModel.fromJson(minimalRow);
      expect(model.phone, isNull);
      expect(model.dateOfBirth, isNull);
      expect(model.pinHash, isNull);
    });

    test('parses interests list correctly', () {
      final row = Map<String, dynamic>.from(minimalRow)
        ..['interests'] = ['news', 'sports', 'health'];
      final model = UserModel.fromJson(row);
      expect(model.interests, ['news', 'sports', 'health']);
    });

    test('interests defaults to empty list when null', () {
      final row = Map<String, dynamic>.from(minimalRow)
        ..['interests'] = null;
      final model = UserModel.fromJson(row);
      expect(model.interests, isEmpty);
    });

    test('parses optional phone', () {
      final row = Map<String, dynamic>.from(minimalRow)
        ..['phone'] = '+94771234567';
      final model = UserModel.fromJson(row);
      expect(model.phone, '+94771234567');
    });

    test('parses optional dateOfBirth', () {
      final row = Map<String, dynamic>.from(minimalRow)
        ..['date_of_birth'] = '1942-03-14';
      final model = UserModel.fromJson(row);
      expect(model.dateOfBirth, isNotNull);
      expect(model.dateOfBirth!.year, 1942);
      expect(model.dateOfBirth!.month, 3);
      expect(model.dateOfBirth!.day, 14);
    });

    test('parses optional pinHash', () {
      final row = Map<String, dynamic>.from(minimalRow)
        ..['pin_hash'] = r'$2b$10$somehashedvalue';
      final model = UserModel.fromJson(row);
      expect(model.pinHash, r'$2b$10$somehashedvalue');
    });

    test('ttsEnabled defaults to false when null', () {
      final row = Map<String, dynamic>.from(minimalRow)
        ..['tts_enabled'] = null;
      final model = UserModel.fromJson(row);
      expect(model.ttsEnabled, isFalse);
    });

    test('moodSharingConsent defaults to false when null', () {
      final row = Map<String, dynamic>.from(minimalRow)
        ..['mood_sharing_consent'] = null;
      final model = UserModel.fromJson(row);
      expect(model.moodSharingConsent, isFalse);
    });
  });

  group('UserModel computed getters', () {
    late UserModel elderUser;
    late UserModel caretakerUser;

    setUp(() {
      final base = {
        'id': 'uid-1',
        'email': 'e@e.com',
        'full_name': 'Arthur Thompson',
        'interests': <dynamic>[],
        'tts_enabled': false,
        'mood_sharing_consent': true,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      elderUser = UserModel.fromJson({...base, 'role': 'elderly'});
      caretakerUser = UserModel.fromJson({...base, 'role': 'caretaker'});
    });

    test('isElderly returns true for elderly role', () {
      expect(elderUser.isElderly, isTrue);
      expect(elderUser.isCaretaker, isFalse);
    });

    test('isCaretaker returns true for caretaker role', () {
      expect(caretakerUser.isCaretaker, isTrue);
      expect(caretakerUser.isElderly, isFalse);
    });

    test('firstName returns first word of fullName', () {
      expect(elderUser.firstName, 'Arthur');
    });

    test('firstName handles single-word name', () {
      final user = UserModel.fromJson({
        'id': 'uid-2',
        'email': 'e@e.com',
        'role': 'elderly',
        'full_name': 'Sundar',
        'interests': <dynamic>[],
        'tts_enabled': false,
        'mood_sharing_consent': false,
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(user.firstName, 'Sundar');
    });
  });
}
