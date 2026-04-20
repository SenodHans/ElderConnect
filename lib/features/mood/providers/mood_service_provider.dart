import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/mood_service.dart';

/// Provides [MoodService] to any widget or notifier that needs to trigger
/// mood analysis after a post is submitted.
final moodServiceProvider = Provider<MoodService>((ref) {
  return MoodService(Supabase.instance.client);
});
