/// Authentication service for ElderConnect.
///
/// Encapsulates all Supabase Auth operations and elder session management.
/// Screens and providers call this service — never the Supabase client directly.
///
/// Two auth patterns co-exist:
///   Caretaker: standard email/password JWT via Supabase Auth.
///   Elder: persistent session stored in flutter_secure_storage; PIN is
///          fallback-only for app reinstall or session expiry.
library;

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Storage keys used by flutter_secure_storage.
const _kAccessToken = 'ec_access_token';
const _kRefreshToken = 'ec_refresh_token';
const _kElderId = 'ec_elder_id';
const _kElderPhone = 'ec_elder_phone';
const _kElderPinHash = 'ec_elder_pin_hash';

/// Provides all authentication operations for the ElderConnect app.
class AuthService {
  AuthService(this._supabase, this._storage);

  final SupabaseClient _supabase;
  final FlutterSecureStorage _storage;

  // ── Caretaker auth ──────────────────────────────────────────────────────

  /// Creates a new caretaker account.
  ///
  /// Calls supabase.auth.signUp then inserts a row into the users table
  /// with role='caretaker'. Returns the new [User] on success.
  Future<User> signUpCaretaker({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      // Store role in auth user_metadata so GoRouter redirect can read it
      // synchronously without a DB query.
      data: {'role': 'caretaker', 'full_name': name.trim()},
    );

    final user = res.user;
    if (user == null) {
      throw const AuthException('Sign-up returned no user. Check email confirmation settings.');
    }

    // Insert the caretaker profile row.
    await _supabase.from('users').insert({
      'id': user.id,
      'email': email,
      'role': 'caretaker',
      'full_name': name.trim(),
      'phone': phone.trim(),
    });

    return user;
  }

  /// Signs in an existing caretaker with email and password.
  ///
  /// Returns the authenticated [User] on success.
  Future<User> signInCaretaker({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) throw const AuthException('Sign-in failed — no user returned.');
    return user;
  }

  /// Signs out the current user and clears elder session storage.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _clearElderSession();
  }

  // ── Elder auth ──────────────────────────────────────────────────────────

  /// Calls the create-elder-account Edge Function to create a Supabase Auth
  /// account for an elderly user. Must be called with a valid caretaker session.
  ///
  /// Returns a map containing `elder_id` and `email`.
  /// The system_password is NEVER returned — it lives server-side only.
  Future<Map<String, dynamic>> createElderAccount({
    required String phone,
    required String fullName,
  }) async {
    final res = await _supabase.functions.invoke(
      'create-elder-account',
      body: {'phone': phone, 'full_name': fullName},
    );

    if (res.status != 201) {
      final message = (res.data as Map<String, dynamic>?)?['error']
          ?? 'Failed to create elder account';
      throw Exception(message);
    }

    return res.data as Map<String, dynamic>;
  }

  /// Verifies a 4-digit PIN against the bcrypt hash stored in users.pin_hash.
  ///
  /// Returns `true` if the PIN matches, `false` otherwise.
  Future<bool> verifyElderPin({
    required String elderId,
    required String pin,
  }) async {
    final row = await _supabase
        .from('users')
        .select('pin_hash')
        .eq('id', elderId)
        .single();

    final storedHash = row['pin_hash'] as String?;
    if (storedHash == null) return false;

    // BCrypt comparison is CPU-intensive — runs synchronously on the Dart isolate.
    return BCrypt.checkpw(pin, storedHash);
  }

  /// Hashes a 4-digit PIN and stores it in users.pin_hash.
  ///
  /// Called by the caretaker when setting or resetting an elder's PIN.
  Future<void> setElderPin({
    required String elderId,
    required String pin,
  }) async {
    final hashed = BCrypt.hashpw(pin, BCrypt.gensalt());
    await _supabase
        .from('users')
        .update({'pin_hash': hashed})
        .eq('id', elderId);
  }

  // ── Elder session persistence ───────────────────────────────────────────

  /// Writes the elder's session tokens and profile data to flutter_secure_storage.
  ///
  /// [elderId] and [phone] are stored once during initial setup so the fallback
  /// screen can identify the elder without a DB query.
  /// [pinHash] is the bcrypt hash from the users table — cached locally so PIN
  /// verification works offline (refresh token may be expired but hash is valid).
  Future<void> persistElderSession(
    Session session, {
    String? elderId,
    String? phone,
    String? pinHash,
  }) async {
    final writes = <Future>[
      _storage.write(key: _kAccessToken, value: session.accessToken),
      _storage.write(key: _kRefreshToken, value: session.refreshToken),
    ];
    if (elderId != null) writes.add(_storage.write(key: _kElderId, value: elderId));
    if (phone != null) writes.add(_storage.write(key: _kElderPhone, value: phone));
    if (pinHash != null) writes.add(_storage.write(key: _kElderPinHash, value: pinHash));
    await Future.wait(writes);
  }

  /// Returns the stored elder id, or null if not set.
  Future<String?> getStoredElderId() => _storage.read(key: _kElderId);

  /// Returns the stored elder phone number, or null if not set.
  Future<String?> getStoredPhone() => _storage.read(key: _kElderPhone);

  /// Returns the locally cached bcrypt PIN hash, or null if not set.
  Future<String?> getStoredPinHash() => _storage.read(key: _kElderPinHash);

  /// Updates the locally cached PIN hash — called after caretaker resets the PIN
  /// and the elder re-opens the app (user_provider fetches updated profile row).
  Future<void> updateStoredPinHash(String newHash) =>
      _storage.write(key: _kElderPinHash, value: newHash);

  /// Reads stored elder tokens and restores the Supabase session.
  ///
  /// Returns the restored [Session] if tokens exist and are valid,
  /// or `null` if no tokens are stored (first launch or post-reinstall).
  Future<Session?> restoreElderSession() async {
    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (refreshToken == null) return null;

    try {
      final res = await _supabase.auth.setSession(refreshToken);
      final session = res.session;
      if (session != null) {
        // Persist the newly issued tokens (refresh token rotates on each use).
        await persistElderSession(session);
      }
      return session;
    } on AuthException {
      // Tokens expired or revoked — clear storage so the PIN screen is shown.
      await _clearElderSession();
      return null;
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _clearElderSession() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kElderId),
      _storage.delete(key: _kElderPhone),
      _storage.delete(key: _kElderPinHash),
    ]);
  }

  /// Verifies a PIN against a locally supplied hash without a DB query.
  ///
  /// Used on the PIN fallback screen when the session has expired and the
  /// pin_hash was cached in flutter_secure_storage during initial setup.
  bool verifyPinLocal(String pin, String storedHash) =>
      BCrypt.checkpw(pin, storedHash);
}
