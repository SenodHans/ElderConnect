/// Providers for the medications and medication_logs tables.
///
/// [activeMedicationsProvider] — live stream of active medications for the
///   current elder. Used to derive [hasMedicationProvider].
///
/// [hasMedicationProvider] — bool; true when the elder has ≥ 1 active
///   medication. Drives the conditional Medication nav tab.
///
/// [nextMedicationProvider] — next pending medication log (scheduled_time
///   closest to now). Drives the "Up Next" card.
///
/// [medicationHistoryProvider] — recent taken/missed logs (last 7 days).
///   Drives the History section.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/medication_model.dart';

/// Live stream of active medications for the signed-in elder.
/// Re-fetches on any INSERT/UPDATE/DELETE to the medications table.
final activeMedicationsProvider = StreamProvider<List<MedicationModel>>((ref) {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return const Stream.empty();

  final controller = StreamController<List<MedicationModel>>();

  Future<void> fetch() async {
    try {
      final rows = await client
          .from('medications')
          .select()
          .eq('elderly_user_id', uid)
          .eq('is_active', true)
          .order('created_at', ascending: true);
      if (!controller.isClosed) {
        controller.add(rows.map(MedicationModel.fromJson).toList());
      }
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  fetch();

  final channel = client
      .channel('medications_channel_$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'medications',
        callback: (_) => fetch(),
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// True when the current elder has at least one active medication.
/// Drives the conditional Medication tab in the bottom nav.
final hasMedicationProvider = Provider<bool>((ref) {
  return ref.watch(activeMedicationsProvider).when(
        data: (meds) => meds.isNotEmpty,
        loading: () => false,
        error: (_, s) => false,
      );
});

/// The next pending medication log for the current elder
/// (scheduled_time ≥ now, status = 'pending', ordered ascending).
final nextMedicationProvider =
    FutureProvider<MedicationLogModel?>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;

  final rows = await Supabase.instance.client
      .from('medication_logs')
      .select('*, medications!medication_id(pill_name, dosage)')
      .eq('user_id', uid)
      .eq('status', 'pending')
      .gte('scheduled_time', DateTime.now().toIso8601String())
      .order('scheduled_time', ascending: true)
      .limit(1);

  if (rows.isEmpty) return null;
  return MedicationLogModel.fromJson(rows.first);
});

/// Recent medication history (last 7 days, taken or missed),
/// ordered newest-first. Used by the History section.
final medicationHistoryProvider =
    FutureProvider<List<MedicationLogModel>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];

  final since = DateTime.now()
      .subtract(const Duration(days: 7))
      .toIso8601String();

  final rows = await Supabase.instance.client
      .from('medication_logs')
      .select('*, medications!medication_id(pill_name, dosage)')
      .eq('user_id', uid)
      .inFilter('status', ['taken', 'missed'])
      .gte('scheduled_time', since)
      .order('scheduled_time', ascending: false)
      .limit(20);

  return rows.map(MedicationLogModel.fromJson).toList();
});
