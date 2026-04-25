// Unit tests for UserModel computed getters and fromJson edge cases.
//
// Covers:
//   - firstName — splits on space, returns first token
//   - isElderly / isCaretaker — role-string comparisons
//   - hasEmergencyContact — non-null & non-empty phone required
//   - dateOfBirth parsing — nullable DateTime
//   - ttsEnabled / moodSharingConsent boolean parsing

import 'package:flutter_test/flutter_test.dart';
import 'package:elder_connect/shared/models/user_model.dart';

// Minimal valid caretaker row — used as a base for most tests.
const Map<String, dynamic> _kCaretakerRow = {
  'id': 'cc000001-cafe-0000-0000-000000000001',
  'email': 'anusha.perera@gmail.com',
  'role': 'caretaker',
  'full_name': 'Anusha Perera',
  'interests': <dynamic>[],
  'tts_enabled': false,
  'mood_sharing_consent': false,
  'created_at': '2026-01-10T08:00:00.000Z',
};

// Minimal valid elderly row.
const Map<String, dynamic> _kElderRow = {
  'id': 'ee000001-bead-0000-0000-000000000001',
  'email': 'elder_pawan.perera@elderconnect.internal',
  'role': 'elderly',
  'full_name': 'Pawan Perera',
  'interests': <dynamic>['news', 'cricket', 'gardening'],
  'tts_enabled': true,
  'mood_sharing_consent': true,
  'created_at': '2026-01-10T09:00:00.000Z',
};

void main() {
  // ── UserModel.firstName ────────────────────────────────────────────────────

  group('UserModel.firstName', () {
    test('returns first word of full name', () {
      final user = UserModel.fromJson(_kElderRow);
      expect(user.firstName, 'Pawan');
    });

    test('returns the full name when there is no space', () {
      final row = Map<String, dynamic>.from(_kCaretakerRow)
        ..['full_name'] = 'Anusha';
      final user = UserModel.fromJson(row);
      expect(user.firstName, 'Anusha');
    });

    test('handles triple-word name — only first word returned', () {
      final row = Map<String, dynamic>.from(_kCaretakerRow)
        ..['full_name'] = 'Saman Kumara Jayawardena';
      final user = UserModel.fromJson(row);
      expect(user.firstName, 'Saman');
    });
  });

  // ── UserModel.isElderly / isCaretaker ──────────────────────────────────────

  group('UserModel role predicates', () {
    test('isElderly is true for role="elderly"', () {
      final user = UserModel.fromJson(_kElderRow);
      expect(user.isElderly, isTrue);
      expect(user.isCaretaker, isFalse);
    });

    test('isCaretaker is true for role="caretaker"', () {
      final user = UserModel.fromJson(_kCaretakerRow);
      expect(user.isCaretaker, isTrue);
      expect(user.isElderly, isFalse);
    });

    test('isElderly and isCaretaker are both false for unknown role', () {
      final row = Map<String, dynamic>.from(_kCaretakerRow)
        ..['role'] = 'admin';
      final user = UserModel.fromJson(row);
      expect(user.isElderly, isFalse);
      expect(user.isCaretaker, isFalse);
    });
  });

  // ── UserModel.hasEmergencyContact ─────────────────────────────────────────

  group('UserModel.hasEmergencyContact', () {
    test('returns true when emergency contact phone is set', () {
      final row = Map<String, dynamic>.from(_kElderRow)
        ..['emergency_contact_phone'] = '+94 71 123 4567';
      final user = UserModel.fromJson(row);
      expect(user.hasEmergencyContact, isTrue);
    });

    test('returns false when emergency contact phone is null', () {
      final user = UserModel.fromJson(_kElderRow); // no emergency_contact_phone key
      expect(user.hasEmergencyContact, isFalse);
    });

    test('returns false when emergency contact phone is empty string', () {
      final row = Map<String, dynamic>.from(_kElderRow)
        ..['emergency_contact_phone'] = '';
      final user = UserModel.fromJson(row);
      expect(user.hasEmergencyContact, isFalse);
    });
  });

  // ── UserModel tts / consent booleans ──────────────────────────────────────

  group('UserModel boolean fields', () {
    test('ttsEnabled is true for elder with TTS enabled', () {
      final user = UserModel.fromJson(_kElderRow);
      expect(user.ttsEnabled, isTrue);
    });

    test('ttsEnabled is false for caretaker (not applicable)', () {
      final user = UserModel.fromJson(_kCaretakerRow);
      expect(user.ttsEnabled, isFalse);
    });

    test('moodSharingConsent is true when elder has consented', () {
      final user = UserModel.fromJson(_kElderRow);
      expect(user.moodSharingConsent, isTrue);
    });

    test('moodSharingConsent is false for caretaker', () {
      final user = UserModel.fromJson(_kCaretakerRow);
      expect(user.moodSharingConsent, isFalse);
    });
  });

  // ── UserModel interests list ───────────────────────────────────────────────

  group('UserModel.interests', () {
    test('parses non-empty interests list', () {
      final user = UserModel.fromJson(_kElderRow);
      expect(user.interests, containsAll(['news', 'cricket', 'gardening']));
      expect(user.interests.length, 3);
    });

    test('empty interests list for caretaker', () {
      final user = UserModel.fromJson(_kCaretakerRow);
      expect(user.interests, isEmpty);
    });

    test('interests defaults to empty list when column is null', () {
      final row = Map<String, dynamic>.from(_kElderRow)
        ..['interests'] = null;
      final user = UserModel.fromJson(row);
      expect(user.interests, isEmpty);
    });
  });

  // ── UserModel.dateOfBirth parsing ─────────────────────────────────────────

  group('UserModel.dateOfBirth', () {
    test('parses dateOfBirth when present', () {
      final row = Map<String, dynamic>.from(_kElderRow)
        ..['date_of_birth'] = '1948-03-15';
      final user = UserModel.fromJson(row);
      expect(user.dateOfBirth, isNotNull);
      expect(user.dateOfBirth!.year, 1948);
      expect(user.dateOfBirth!.month, 3);
      expect(user.dateOfBirth!.day, 15);
    });

    test('dateOfBirth is null when not provided', () {
      final user = UserModel.fromJson(_kCaretakerRow);
      expect(user.dateOfBirth, isNull);
    });
  });

  // ── UserModel.pinHash / pinPlain ──────────────────────────────────────────

  group('UserModel PIN fields', () {
    test('pinHash is null when not present in row', () {
      final user = UserModel.fromJson(_kCaretakerRow);
      expect(user.pinHash, isNull);
    });

    test('pinPlain is populated when present for elder', () {
      final row = Map<String, dynamic>.from(_kElderRow)
        ..['pin_plain'] = '1234';
      final user = UserModel.fromJson(row);
      expect(user.pinPlain, '1234');
    });
  });
}
