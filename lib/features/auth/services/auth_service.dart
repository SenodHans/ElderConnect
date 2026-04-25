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
const _kAccessToken   = 'ec_access_token';
const _kRefreshToken  = 'ec_refresh_token';
const _kElderId       = 'ec_elder_id';
const _kElderPhone    = 'ec_elder_phone';
const _kElderPinHash  = 'ec_elder_pin_hash';
// Credential cache — stored at first registration so the elder can recover
// their session after reinstall without going through caretaker again.
const _kElderEmail    = 'ec_elder_email';
const _kElderPassword = 'ec_elder_password';
const _kElderName     = 'ec_elder_name';
// Tracks the last successfully authenticated role so the splash screen can
// route to the correct login screen after session expiry, not role-selection.
const _kLastRole      = 'ec_last_role';

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

  /// Signs out the current user and wipes all cached session data.
  ///
  /// Clears the entire secure storage so no stale identity (name, PIN hash,
  /// credentials) persists. The next app open lands on the welcome screen,
  /// and the elder must re-enter their PIN to sign back in.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _storage.deleteAll();
  }

  // ── Role tracking ───────────────────────────────────────────────────────

  /// Saves the last successfully authenticated role ('elderly' or 'caretaker').
  ///
  /// Called after sign-in/sign-up so the splash screen can route directly to
  /// the correct login screen if the session expires, skipping role-selection.
  Future<void> saveLastRole(String role) =>
      _storage.write(key: _kLastRole, value: role);

  /// Returns the last authenticated role, or null for a fresh install.
  Future<String?> getLastRole() => _storage.read(key: _kLastRole);

  // ── Caretaker email + password recovery ────────────────────────────────

  /// Re-sends the signup confirmation email for a pending caretaker account.
  Future<void> resendVerificationEmail(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  /// Sends a password-reset link to the caretaker's email address.
  /// The link redirects to elderconnect://reset-password so Android opens the app.
  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'elderconnect://reset-password',
    );
  }

  // ── Elder PIN DB fallback ───────────────────────────────────────────────

  /// Fetches the latest pin_hash from Supabase and updates local secure storage.
  ///
  /// Called after a caretaker resets the elder's PIN so the local cache stays
  /// in sync without requiring the elder to go through the caretaker again.
  Future<String?> fetchAndCachePinHash(String elderId) async {
    final row = await _supabase
        .from('users')
        .select('pin_hash')
        .eq('id', elderId)
        .single();
    final hash = row['pin_hash'] as String?;
    if (hash != null) await updateStoredPinHash(hash);
    return hash;
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
  ///
  /// On token expiry, only the token pair is cleared — identity data
  /// (elderId, phone, pinHash, email, password, name) is intentionally
  /// preserved so PIN verification works correctly on the PIN screen.
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
      return null;
    }
  }

  // ── Elder credential cache ──────────────────────────────────────────────

  /// Stores the elder's synthetic email + system password locally so the
  /// session can be restored after reinstall without contacting the caretaker.
  Future<void> persistElderCredentials({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await Future.wait([
      _storage.write(key: _kElderEmail, value: email),
      _storage.write(key: _kElderPassword, value: password),
      _storage.write(key: _kElderName, value: fullName),
    ]);
  }

  /// Returns stored elder name, or null if never registered on this device.
  Future<String?> getStoredElderName() => _storage.read(key: _kElderName);

  /// Signs in with explicitly provided email and password.
  /// Used by the PIN login screen after a global DB lookup returns credentials.
  Future<Session?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.session;
    } on AuthException {
      return null;
    }
  }

  /// Attempts to sign in using locally cached email + password.
  /// Returns the [Session] on success, null if credentials are missing or stale.
  Future<Session?> signInWithCachedCredentials() async {
    final email = await _storage.read(key: _kElderEmail);
    final password = await _storage.read(key: _kElderPassword);
    if (email == null || password == null) return null;

    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = res.session;
      if (session != null) await persistElderSession(session);
      return session;
    } on AuthException {
      return null;
    }
  }

  /// Calls restore-elder-session Edge Function (verify_jwt: false) with the
  /// elder's name + PIN. Used when device storage has been wiped after reinstall.
  /// Returns the restored [Session] on success, null on failure.
  Future<Session?> restoreSessionWithNameAndPin({
    required String fullName,
    required String pin,
  }) async {
    try {
      final res = await _supabase.functions.invoke(
        'restore-elder-session',
        body: {'full_name': fullName, 'pin': pin},
      );
      if (res.status != 200) return null;

      final data = res.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) return null;

      final sessionRes = await _supabase.auth.setSession(refreshToken);
      final session = sessionRes.session;
      if (session != null) await persistElderSession(session);
      return session;
    } catch (_) {
      return null;
    }
  }

  /// Calls restore-elder-session Edge Function with phone + PIN.
  /// Used after app reinstall when no stored credentials remain.
  /// Caches retrieved credentials locally so future restores use stored tokens.
  Future<Session?> restoreSessionWithPhoneAndPin({
    required String phone,
    required String pin,
  }) async {
    try {
      final res = await _supabase.functions.invoke(
        'restore-elder-session',
        body: {'phone': phone, 'pin': pin},
      );
      if (res.status != 200) return null;

      final data = res.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final elderId = data['elder_id'] as String?;
      final fullName = data['full_name'] as String?;
      if (accessToken == null || refreshToken == null) return null;

      final sessionRes = await _supabase.auth.setSession(refreshToken);
      final session = sessionRes.session;
      if (session != null) {
        await persistElderSession(session, elderId: elderId, phone: phone);
        if (fullName != null) {
          await _storage.write(key: _kElderName, value: fullName);
        }
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  /// Sends an unauthenticated help request to notify the caretaker.
  /// Used when "Need Help" is tapped and no session can be restored (reinstall).
  /// Returns true if the request was accepted by the server.
  Future<bool> sendHelpRequest(String phone) async {
    try {
      final res = await _supabase.functions.invoke(
        'send-help-request',
        body: {'phone': phone},
      );
      return res.status == 200;
    } catch (_) {
      return false;
    }
  }

  /// Looks up an elder by plain PIN across ALL elders in the database.
  ///
  /// Calls the SECURITY DEFINER function find_elder_by_pin which bypasses
  /// RLS and returns id, full_name, email, system_password for the matching
  /// elder. Returns null if no elder has this PIN.
  Future<Map<String, dynamic>?> findElderByPin(String pin) async {
    final result = await _supabase.rpc(
      'find_elder_by_pin',
      params: {'pin_input': pin},
    ) as List<dynamic>;
    if (result.isEmpty) return null;
    return result.first as Map<String, dynamic>;
  }

  // ── Private helpers ─────────────────────────────────────────────────────

/// Verifies a PIN against a locally supplied hash without a DB query.
  ///
  /// Used on the PIN fallback screen when the session has expired and the
  /// pin_hash was cached in flutter_secure_storage during initial setup.
  bool verifyPinLocal(String pin, String storedHash) =>
      BCrypt.checkpw(pin, storedHash);
}
