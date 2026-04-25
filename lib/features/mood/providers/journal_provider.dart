import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/mood_service.dart';
import 'mood_service_provider.dart';

enum JournalStatus { idle, submitting, submitted, error }

class JournalState {
  final JournalStatus status;
  final String? selectedEmoji;
  final String text;
  final String? moodLabel;
  final String? errorMessage;

  const JournalState({
    this.status = JournalStatus.idle,
    this.selectedEmoji,
    this.text = '',
    this.moodLabel,
    this.errorMessage,
  });

  JournalState copyWith({
    JournalStatus? status,
    // Nullable setter pattern: pass () => null to explicitly clear.
    String? Function()? selectedEmoji,
    String? text,
    String? Function()? moodLabel,
    String? errorMessage,
  }) {
    return JournalState(
      status: status ?? this.status,
      selectedEmoji:
          selectedEmoji != null ? selectedEmoji() : this.selectedEmoji,
      text: text ?? this.text,
      moodLabel: moodLabel != null ? moodLabel() : this.moodLabel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class JournalNotifier extends AutoDisposeNotifier<JournalState> {
  @override
  JournalState build() => const JournalState();

  /// Toggles the selected emoji — tapping the active one deselects it.
  void selectEmoji(String emoji) {
    final next = state.selectedEmoji == emoji ? null : emoji;
    state = state.copyWith(selectedEmoji: () => next);
  }

  Future<void> submit({required String text}) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(status: JournalStatus.submitting, text: text);

    try {
      final service = ref.read(moodServiceProvider);
      MoodResult result = await service.analyseJournalEntry(
        text: text.trim(),
        emojiSelfReport: state.selectedEmoji,
      );

      // One retry on HuggingFace cold-start loading response.
      if (result.status == MoodStatus.loading) {
        await Future.delayed(const Duration(seconds: 25));
        result = await service.analyseJournalEntry(
          text: text.trim(),
          emojiSelfReport: state.selectedEmoji,
        );
      }

      state = state.copyWith(
        status: JournalStatus.submitted,
        moodLabel: () => result.label,
      );
    } catch (_) {
      state = state.copyWith(
        status: JournalStatus.error,
        errorMessage: 'Could not save your entry. Please try again.',
      );
    }
  }

  void reset() => state = const JournalState();
}

final journalNotifierProvider =
    NotifierProvider.autoDispose<JournalNotifier, JournalState>(JournalNotifier.new);

/// Fetches today's rotating question from daily_prompt_questions.
/// Index = dayOfYear % totalQuestions. Falls back to hardcoded question on error.
final dailyPromptQuestionProvider = FutureProvider<String>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('daily_prompt_questions')
        .select('question')
        .order('id');
    final questions =
        (data as List).map((e) => e['question'] as String).toList();
    if (questions.isEmpty) return _kFallbackQuestion;
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return questions[dayOfYear % questions.length];
  } catch (_) {
    return _kFallbackQuestion;
  }
});

const _kFallbackQuestion = 'What is one thing that made you smile today?';
