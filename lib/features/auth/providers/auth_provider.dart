/// Auth providers for ElderConnect.
///
/// Two providers exposed here:
///   [authServiceProvider] — injectable AuthService instance.
///   [authStateProvider]   — StreamProvider that re-exposes
///                           supabase.auth.onAuthStateChange. Used by
///                           GoRouter's refreshListenable and by screens
///                           that need to react to sign-in / sign-out.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Provides the singleton [AuthService] instance.
///
/// Screens access auth operations via:
///   `ref.read(authServiceProvider).signInCaretaker(...)`
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    Supabase.instance.client,
    const FlutterSecureStorage(
      // Use encryptedSharedPreferences on Android for stronger protection.
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});

/// Stream of [AuthState] from Supabase.
///
/// Emits on every auth event: signedIn, signedOut, tokenRefreshed, etc.
/// GoRouter's refreshListenable wraps this stream so the router re-evaluates
/// redirect logic whenever auth state changes.
///
/// Usage in screens:
///   final authState = ref.watch(authStateProvider);
///   authState.when(data: (s) => s.session, ...)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
