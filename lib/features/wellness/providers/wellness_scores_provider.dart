/// Wellness score providers for the leaderboard and personal best sections
/// on the post-game score screen, and score history on the games screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.score,
    required this.isMe,
  });

  final String userId;
  final String name;
  final int score;
  final bool isMe;
}

class WellnessLog {
  const WellnessLog({
    required this.gameName,
    required this.createdAt,
    this.score,
    this.total,
  });

  final String gameName;
  final int? score;
  final int? total;
  final DateTime createdAt;

  String get displayScore {
    if (score != null && total != null) return '$score / $total';
    if (score != null) return '$score pts';
    return 'Complete';
  }

  factory WellnessLog.fromJson(Map<String, dynamic> json) => WellnessLog(
        gameName: json['game_name'] as String,
        score: json['score'] as int?,
        total: json['total'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

/// Top 5 unique players by best score for [gameName].
/// Requires wellness_logs to have a public SELECT policy.
final gameLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, gameName) async {
  final client = Supabase.instance.client;
  final me = client.auth.currentUser?.id;

  final rows = await client
      .from('wellness_logs')
      .select('user_id, score, users!user_id(full_name)')
      .eq('game_name', gameName)
      .not('score', 'is', null)
      .order('score', ascending: false)
      .limit(50);

  // Group by userId, keep best score per player
  final Map<String, LeaderboardEntry> best = {};
  for (final row in rows) {
    final uid = row['user_id'] as String;
    final score = row['score'] as int;
    final name = (row['users'] as Map<String, dynamic>?)?['full_name']
            as String? ??
        'Someone';
    if (!best.containsKey(uid) || best[uid]!.score < score) {
      best[uid] = LeaderboardEntry(
        userId: uid,
        name: uid == me ? 'You' : name,
        score: score,
        isMe: uid == me,
      );
    }
  }

  final sorted = best.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return sorted.take(5).toList();
});

/// Elder's personal best score for [gameName] (null if never played).
final personalBestProvider =
    FutureProvider.family<int?, String>((ref, gameName) async {
  final client = Supabase.instance.client;
  final me = client.auth.currentUser?.id;
  if (me == null) return null;

  final rows = await client
      .from('wellness_logs')
      .select('score')
      .eq('user_id', me)
      .eq('game_name', gameName)
      .not('score', 'is', null)
      .order('score', ascending: false)
      .limit(1);

  return rows.isNotEmpty ? rows.first['score'] as int? : null;
});

/// Elder's 10 most recent game plays across all games.
final myRecentScoresProvider =
    FutureProvider<List<WellnessLog>>((ref) async {
  final client = Supabase.instance.client;
  final me = client.auth.currentUser?.id;
  if (me == null) return [];

  final rows = await client
      .from('wellness_logs')
      .select('game_name, score, total, created_at')
      .eq('user_id', me)
      .order('created_at', ascending: false)
      .limit(10);

  return rows.map(WellnessLog.fromJson).toList();
});
