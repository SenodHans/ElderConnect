/// Provider exposing the logged-in user's profile as a live Supabase stream.
///
/// Backed by `SupabaseClient.from('users').stream()` which sends an initial
/// snapshot and then pushes an update any time the row changes — e.g. when
/// the caretaker updates the elder's PIN or interests.
///
/// Usage in screens:
///   final user = ref.watch(userProvider);
///   user.when(data: (u) => u?.fullName, ...)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_model.dart';

/// StreamProvider of UserModel? — emits the current user's profile row.
///
/// Emits null when:
///   - No user is signed in.
///   - The users row has not yet been inserted (race condition on first login).
///
/// Consumers should handle the null case with a loading or redirect state.
final userProvider = StreamProvider<UserModel?>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return const Stream.empty();

  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', uid)
      .map((rows) => rows.isEmpty ? null : UserModel.fromJson(rows.first));
});
