/// Caretaker-side data providers for mood monitoring, activity tracking,
/// and MOSAIC alert display.
///
/// Feeds:
///   - MoodActivityLogsScreen  — chart, activity stream, journal entries
///   - CaretakerDashboardScreen — priority alerts, linked elder cards
///
/// All queries respect Supabase RLS — caretakers only read data for their
/// accepted-link elders. mood_logs are further gated by mood_sharing_consent.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/medication_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/post_model.dart';

// ── Enums & value objects ────────────────────────────────────────────────────

enum MoodBarStatus { stable, warning, urgent }

/// One day's aggregated mood data for the 7-day chart.
class DayMoodData {
  const DayMoodData({
    required this.dayLabel,
    required this.barHeight,
    required this.barStatus,
    this.annotation,
  });

  /// Three-letter day label: 'MON', 'TUE', … 'SUN'.
  final String dayLabel;

  /// Logical pixels — range [40, 208]. Higher = more negative mood intensity.
  final double barHeight;

  final MoodBarStatus barStatus;

  /// Optional label above the worst urgent bar (e.g. 'LOW MOOD').
  final String? annotation;
}

/// Summary data for the Activity Stream section.
class ElderActivitySummary {
  const ElderActivitySummary({
    required this.lastActiveLabel,
    required this.postCount,
    required this.gamesPlayed,
    this.latestGameName,
    required this.hasPendingMeds,
    required this.pendingMedLabel,
    required this.medicationAdherence,
  });

  final String lastActiveLabel;   // 'Active today', 'Active 2d ago', etc.
  final int postCount;
  final int gamesPlayed;
  final String? latestGameName;   // most recently played game, null if none
  final bool hasPendingMeds;
  final String pendingMedLabel;   // 'Pending: 1 dose(s) today' or 'All doses confirmed'
  final double medicationAdherence; // 0.0–1.0 — used for the adherence progress bar
}

/// MOSAIC alert state for one elder — read from the alert_states table.
class ElderAlertState {
  const ElderAlertState({
    required this.elderlyUserId,
    required this.status,
    required this.activityCount,
    required this.routineAdherence,
    required this.sentimentSlope,
    this.computedAt,
  });

  final String elderlyUserId;
  final String status; // 'stable' | 'warning' | 'urgent'
  final int activityCount;
  final double routineAdherence;
  final double sentimentSlope;
  final DateTime? computedAt;

  bool get isStable  => status == 'stable';
  bool get isWarning => status == 'warning';
  bool get isUrgent  => status == 'urgent';
}

/// Aggregated elder summary for the caretaker dashboard.
///
/// Bundles the user profile, MOSAIC alert state, latest mood label,
/// and weekly post count into a single object — fetched in one batch
/// to avoid N+1 queries as the caretaker's linked-elder list grows.
class ElderSummary {
  const ElderSummary({
    required this.elder,
    this.alert,
    this.latestMoodLabel,
    this.weeklyPostCount = 0,
  });

  final UserModel elder;

  /// Null if no MOSAIC computation has run yet (elder has never posted).
  final ElderAlertState? alert;

  /// Human-readable mood label: 'Positive', 'Low Mood', 'Stable', or null.
  final String? latestMoodLabel;

  final int weeklyPostCount;
}

// ── Providers ────────────────────────────────────────────────────────────────

/// All accepted-link elders for the currently signed-in caretaker.
final linkedEldersProvider = FutureProvider<List<UserModel>>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return [];

  final rows = await client
      .from('caretaker_links')
      .select(
        'users!elderly_user_id(id, email, role, full_name, phone, date_of_birth, '
        'interests, tts_enabled, mood_sharing_consent, created_at, pin_hash, '
        'pin_plain, avatar_url, emergency_contact_name, emergency_contact_phone)',
      )
      .eq('caretaker_id', uid)
      .eq('status', 'accepted');

  return rows
      .where((r) => r['users'] != null)
      .map((r) => UserModel.fromJson(r['users'] as Map<String, dynamic>))
      .toList();
});

/// Which linked elder is selected on the mood logs screen — index into
/// [linkedEldersProvider]. Resets to 0 when the caretaker navigates away.
final selectedElderIndexProvider = StateProvider<int>((_) => 0);

/// 7-day mood chart data for one elder.
///
/// Returns one [DayMoodData] entry per day for the last 7 days (oldest first).
/// Days without mood_logs entries get a minimal stable bar at 48 dp.
///
/// Bar height represents negative-mood intensity — a tall bar in the urgent
/// zone (top third) means high-confidence negative emotion was detected.
final elderMoodChartProvider =
    FutureProvider.family<List<DayMoodData>, String>((ref, elderId) async {
  if (elderId.isEmpty) return _emptySevenDays();

  final client = Supabase.instance.client;
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

  final rows = await client
      .from('mood_logs')
      .select('label, score, created_at')
      .eq('user_id', elderId)
      .gte('created_at', sevenDaysAgo.toUtc().toIso8601String())
      .order('created_at', ascending: true);

  // Group logs by local calendar date.
  final byDay = <String, List<({String label, double score})>>{};
  for (final row in rows) {
    final dt = DateTime.parse(row['created_at'] as String).toLocal();
    byDay.putIfAbsent(_dateKey(dt), () => []).add((
      label: row['label'] as String,
      score: (row['score'] as num).toDouble(),
    ));
  }

  const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final now = DateTime.now();
  final result = <DayMoodData>[];
  int worstIdx = -1;
  double worstHeight = 0;

  // Build entries oldest → newest (i=6 = six days ago, i=0 = today).
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dayName = dayNames[day.weekday - 1]; // weekday: 1=MON, 7=SUN
    final entries = byDay[_dateKey(day)];

    if (entries == null || entries.isEmpty) {
      result.add(DayMoodData(
        dayLabel: dayName,
        barHeight: 48.0,
        barStatus: MoodBarStatus.stable,
      ));
      continue;
    }

    // Intensity [0,1]: NEGATIVE score maps directly, POSITIVE is inverted,
    // NEUTRAL defaults to 0.35 (low-intensity neutral baseline).
    final avgIntensity = entries
            .map((e) => switch (e.label) {
                  'NEGATIVE' => e.score,
                  'POSITIVE' => 1.0 - e.score,
                  _          => 0.35,
                })
            .reduce((a, b) => a + b) /
        entries.length;

    // Scale to bar height: min 40 dp, max 208 dp.
    final barHeight = 40.0 + (168.0 * avgIntensity);
    final barStatus = avgIntensity >= 0.65
        ? MoodBarStatus.urgent
        : avgIntensity >= 0.40
            ? MoodBarStatus.warning
            : MoodBarStatus.stable;

    if (barStatus == MoodBarStatus.urgent && barHeight > worstHeight) {
      worstHeight = barHeight;
      worstIdx = result.length;
    }

    result.add(DayMoodData(
      dayLabel: dayName,
      barHeight: barHeight,
      barStatus: barStatus,
    ));
  }

  // Annotate the worst urgent day.
  if (worstIdx >= 0) {
    final w = result[worstIdx];
    result[worstIdx] = DayMoodData(
      dayLabel: w.dayLabel,
      barHeight: w.barHeight,
      barStatus: w.barStatus,
      annotation: 'LOW MOOD',
    );
  }

  return result;
});

/// Activity summary for the Activity Stream and wellness sections.
///
/// [days] is driven by the caretaker's time-range filter (7 or 30).
final elderActivitySummaryProvider = FutureProvider.family<
    ElderActivitySummary,
    ({String elderId, int days})>((ref, args) async {
  if (args.elderId.isEmpty) {
    return const ElderActivitySummary(
      lastActiveLabel: 'No elder linked',
      postCount: 0,
      gamesPlayed: 0,
      hasPendingMeds: false,
      pendingMedLabel: '—',
      medicationAdherence: 1.0,
    );
  }

  final client = Supabase.instance.client;
  final since = DateTime.now()
      .subtract(Duration(days: args.days))
      .toUtc()
      .toIso8601String();
  final dayAgo = DateTime.now()
      .subtract(const Duration(hours: 24))
      .toUtc()
      .toIso8601String();

  // Run all four queries concurrently.
  final results = await Future.wait<List<Map<String, dynamic>>>([
    // 1. Posts in window — ID + timestamp only.
    client
        .from('posts')
        .select('id, created_at')
        .eq('user_id', args.elderId)
        .gte('created_at', since),
    // 2. Games in window — name + timestamp, most recent first.
    client
        .from('wellness_logs')
        .select('game_name, created_at')
        .eq('user_id', args.elderId)
        .gte('created_at', since)
        .order('created_at', ascending: false),
    // 3. Medication logs in last 24 h — for today's pending check.
    client
        .from('medication_logs')
        .select('status')
        .eq('user_id', args.elderId)
        .gte('scheduled_time', dayAgo),
    // 4. Medication logs in full window — for adherence ratio.
    client
        .from('medication_logs')
        .select('status')
        .eq('user_id', args.elderId)
        .gte('scheduled_time', since),
  ]);

  final postRows   = results[0];
  final gameRows   = results[1];
  final todayMeds  = results[2];
  final windowMeds = results[3];

  // Derive last-active label from most recent post.
  String lastActiveLabel = 'No recent posts';
  if (postRows.isNotEmpty) {
    final sorted = [...postRows]
      ..sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
    final last = DateTime.parse(sorted.first['created_at'] as String).toLocal();
    final diff = DateTime.now().difference(last);
    lastActiveLabel = diff.inHours < 24
        ? 'Active today'
        : diff.inDays == 1
            ? 'Active yesterday'
            : 'Active ${diff.inDays}d ago';
  }

  final pendingToday = todayMeds.where((r) => r['status'] == 'pending').length;
  final taken        = windowMeds.where((r) => r['status'] == 'taken').length;
  final adherence    = windowMeds.isEmpty ? 1.0 : taken / windowMeds.length;

  return ElderActivitySummary(
    lastActiveLabel: lastActiveLabel,
    postCount: postRows.length,
    gamesPlayed: gameRows.length,
    latestGameName:
        gameRows.isNotEmpty ? gameRows.first['game_name'] as String? : null,
    hasPendingMeds: pendingToday > 0,
    pendingMedLabel: pendingToday > 0
        ? 'Pending: $pendingToday dose(s) today'
        : 'All doses confirmed',
    medicationAdherence: adherence,
  );
});

/// Most recent posts by one elder — displayed as journal entries.
final elderRecentPostsProvider =
    FutureProvider.family<List<PostModel>, String>((ref, elderId) async {
  if (elderId.isEmpty) return [];
  final rows = await Supabase.instance.client
      .from('posts')
      .select('*, users!user_id(full_name)')
      .eq('user_id', elderId)
      .order('created_at', ascending: false)
      .limit(3);
  return rows.map(PostModel.fromJson).toList();
});

/// Aggregated summaries for all accepted-link elders — used by the caretaker
/// dashboard to show alert tiles, elder cards, and status badges.
///
/// Executes three queries in parallel (alert_states, mood_logs, posts) to
/// avoid N queries as the linked-elder count grows.
final linkedElderSummariesProvider =
    FutureProvider<List<ElderSummary>>((ref) async {
  final elders = await ref.watch(linkedEldersProvider.future);
  if (elders.isEmpty) return [];

  final client     = Supabase.instance.client;
  final elderIds   = elders.map((e) => e.id).toList();
  final sevenDaysAgo = DateTime.now()
      .subtract(const Duration(days: 7))
      .toUtc()
      .toIso8601String();

  final results = await Future.wait<List<Map<String, dynamic>>>([
    // 1. MOSAIC alert states for all linked elders.
    client.from('alert_states').select().inFilter('elderly_user_id', elderIds),
    // 2. Mood logs last 7 days — pick latest per elder in Dart.
    client
        .from('mood_logs')
        .select('user_id, label, score, created_at')
        .inFilter('user_id', elderIds)
        .gte('created_at', sevenDaysAgo)
        .order('created_at', ascending: false),
    // 3. Post IDs last 7 days — count per elder in Dart.
    client
        .from('posts')
        .select('user_id, id')
        .inFilter('user_id', elderIds)
        .gte('created_at', sevenDaysAgo),
  ]);

  final alertRows = results[0];
  final moodRows  = results[1];
  final postRows  = results[2];

  // Build lookup maps.
  final alertMap = <String, ElderAlertState>{
    for (final r in alertRows)
      r['elderly_user_id'] as String: ElderAlertState(
        elderlyUserId: r['elderly_user_id'] as String,
        status: r['status'] as String,
        activityCount: r['activity_count'] as int,
        routineAdherence: (r['routine_adherence'] as num).toDouble(),
        sentimentSlope: (r['sentiment_slope'] as num).toDouble(),
        computedAt: r['computed_at'] != null
            ? DateTime.parse(r['computed_at'] as String)
            : null,
      ),
  };

  // Latest mood per elder (rows already newest-first — take first occurrence).
  final latestMoodMap = <String, String>{};
  for (final r in moodRows) {
    final uid = r['user_id'] as String;
    if (!latestMoodMap.containsKey(uid)) {
      final label = r['label'] as String;
      latestMoodMap[uid] = switch (label) {
        'POSITIVE' => 'Positive',
        'NEGATIVE' => 'Low Mood',
        _          => 'Stable',
      };
    }
  }

  // Weekly post count per elder.
  final postCountMap = <String, int>{};
  for (final r in postRows) {
    final uid = r['user_id'] as String;
    postCountMap[uid] = (postCountMap[uid] ?? 0) + 1;
  }

  return elders
      .map((elder) => ElderSummary(
            elder: elder,
            alert: alertMap[elder.id],
            latestMoodLabel: latestMoodMap[elder.id],
            weeklyPostCount: postCountMap[elder.id] ?? 0,
          ))
      .toList();
});

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Returns a list of 7 stable baseline [DayMoodData] entries for the
/// last 7 days — used as placeholder when no elder is linked.
List<DayMoodData> _emptySevenDays() {
  const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final now = DateTime.now();
  return List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    return DayMoodData(
      dayLabel: dayNames[day.weekday - 1],
      barHeight: 48.0,
      barStatus: MoodBarStatus.stable,
    );
  });
}

String _dateKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

/// Realtime stream of active medications for a specific elder — used by the
/// caretaker Elder tab to display and manage the elder's medication schedule.
final caretakerElderMedicationsProvider =
    StreamProvider.family<List<MedicationModel>, String>((ref, elderId) {
  if (elderId.isEmpty) return const Stream.empty();
  final client = Supabase.instance.client;
  final controller = StreamController<List<MedicationModel>>();

  Future<void> fetch() async {
    try {
      final rows = await client
          .from('medications')
          .select()
          .eq('elderly_user_id', elderId)
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
      .channel('caretaker_meds_$elderId')
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
