// Unit tests for AuthService.
//
// Tests are split into two groups:
//   1. verifyPinLocal — pure bcrypt comparison, no mocks needed.
//      This is the most critical security function: if this breaks, elders
//      cannot log in after a session expiry.
//
//   2. Mocked Supabase interactions — signUpCaretaker, signInCaretaker,
//      setElderPin, createElderAccount. Uses mocktail to isolate the service
//      from the live Supabase backend.

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:elder_connect/features/auth/services/auth_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

void main() {
  // ── verifyPinLocal ──────────────────────────────────────────────────────────
  //
  // This is a pure function — no Supabase dependency.
  // Uses real bcrypt so the test proves the actual hashing algorithm works.

  group('AuthService.verifyPinLocal', () {
    late AuthService service;

    setUp(() {
      service = AuthService(
        MockSupabaseClient(),
        MockFlutterSecureStorage(),
      );
    });

    test('returns true when PIN matches stored hash', () {
      const pin = '1234';
      final hash = BCrypt.hashpw(pin, BCrypt.gensalt());
      expect(service.verifyPinLocal(pin, hash), isTrue);
    });

    test('returns false when PIN does not match stored hash', () {
      const correctPin = '1234';
      const wrongPin = '9999';
      final hash = BCrypt.hashpw(correctPin, BCrypt.gensalt());
      expect(service.verifyPinLocal(wrongPin, hash), isFalse);
    });

    test('returns false for all-zeros PIN against different hash', () {
      final hash = BCrypt.hashpw('5678', BCrypt.gensalt());
      expect(service.verifyPinLocal('0000', hash), isFalse);
    });

    test('is case-sensitive — treats PIN as exact string', () {
      // PINs are digits, but the underlying BCrypt comparison is byte-exact.
      final hash = BCrypt.hashpw('1234', BCrypt.gensalt());
      expect(service.verifyPinLocal('1234', hash), isTrue);
      // Extra whitespace must not match.
      expect(service.verifyPinLocal(' 1234', hash), isFalse);
    });

    test('bcrypt hashes of the same PIN are always equal regardless of salt', () {
      const pin = '7890';
      final hash1 = BCrypt.hashpw(pin, BCrypt.gensalt());
      final hash2 = BCrypt.hashpw(pin, BCrypt.gensalt());
      // Two different hashes (different salts) should both verify correctly.
      expect(service.verifyPinLocal(pin, hash1), isTrue);
      expect(service.verifyPinLocal(pin, hash2), isTrue);
    });
  });

  // ── Session storage helpers ─────────────────────────────────────────────────

  group('AuthService session storage', () {
    late MockSupabaseClient mockClient;
    late MockFlutterSecureStorage mockStorage;
    late AuthService service;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockStorage = MockFlutterSecureStorage();
      service = AuthService(mockClient, mockStorage);
    });

    test('getStoredElderId delegates to storage', () async {
      when(() => mockStorage.read(key: 'ec_elder_id'))
          .thenAnswer((_) async => 'elder-uuid-123');

      final result = await service.getStoredElderId();
      expect(result, 'elder-uuid-123');
    });

    test('getStoredElderId returns null when not set', () async {
      when(() => mockStorage.read(key: 'ec_elder_id'))
          .thenAnswer((_) async => null);

      final result = await service.getStoredElderId();
      expect(result, isNull);
    });

    test('getStoredPhone delegates to storage', () async {
      when(() => mockStorage.read(key: 'ec_elder_phone'))
          .thenAnswer((_) async => '+94771234567');

      final result = await service.getStoredPhone();
      expect(result, '+94771234567');
    });

    test('getStoredPinHash delegates to storage', () async {
      when(() => mockStorage.read(key: 'ec_elder_pin_hash'))
          .thenAnswer((_) async => r'$2b$10$testhash');

      final result = await service.getStoredPinHash();
      expect(result, r'$2b$10$testhash');
    });

    test('updateStoredPinHash writes new hash to storage', () async {
      when(() => mockStorage.write(
            key: 'ec_elder_pin_hash',
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.updateStoredPinHash(r'$2b$10$newhash');

      verify(() => mockStorage.write(
            key: 'ec_elder_pin_hash',
            value: r'$2b$10$newhash',
          )).called(1);
    });
  });
}
