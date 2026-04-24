/// Providers for an elder's linked caretakers and caretaker name search.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaretakerInfo {
  const CaretakerInfo({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.phone,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
}

/// All caretakers currently linked to the signed-in elder.
final elderLinkedCaretakersProvider =
    FutureProvider<List<CaretakerInfo>>((ref) async {
  final client = Supabase.instance.client;
  final me = client.auth.currentUser?.id;
  if (me == null) return [];

  final rows = await client
      .from('caretaker_links')
      .select('caretaker_id, caretaker:users!caretaker_id(full_name, avatar_url, phone)')
      .eq('elderly_user_id', me);

  return rows.map((r) {
    final u = r['caretaker'] as Map<String, dynamic>?;
    return CaretakerInfo(
      userId: r['caretaker_id'] as String,
      fullName: u?['full_name'] as String? ?? 'Caretaker',
      avatarUrl: u?['avatar_url'] as String?,
      phone: u?['phone'] as String?,
    );
  }).toList();
});

/// Caretakers whose name matches [query] (ILIKE search). Empty for blank query.
final caretakerSearchProvider =
    FutureProvider.family<List<CaretakerInfo>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  final client = Supabase.instance.client;
  final rows = await client
      .from('users')
      .select('id, full_name, avatar_url, phone')
      .eq('role', 'caretaker')
      .ilike('full_name', '%${query.trim()}%')
      .limit(10);

  return rows
      .map((r) => CaretakerInfo(
            userId: r['id'] as String,
            fullName: r['full_name'] as String? ?? 'Caretaker',
            avatarUrl: r['avatar_url'] as String?,
            phone: r['phone'] as String?,
          ))
      .toList();
});
