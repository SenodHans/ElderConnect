import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/elder_colors.dart';
import '../../../core/constants/elder_spacing.dart';
import '../providers/journal_provider.dart';

const _kEmojis = ['😄', '🙂', '😐', '😔', '😢'];

Color _moodColour(String? label) {
  switch (label) {
    case 'POSITIVE':
      return const Color(0xFFE8F5E9);
    case 'NEGATIVE':
      return const Color(0xFFFFF3E0);
    default:
      return ElderColors.surfaceContainerLow;
  }
}

String _moodMessage(String? label) {
  switch (label) {
    case 'POSITIVE':
      return 'You seem to be in a good place today. Keep it up!';
    case 'NEGATIVE':
      return 'Thank you for sharing. Your caretaker cares about you.';
    default:
      return 'Thank you for sharing how you feel today.';
  }
}

/// Daily Journal Prompt screen — route /mood/journal.
///
/// Warm rotating question from daily_prompt_questions, 5-emoji self-report row
/// (discrepancy signal only), large text input, and a full-width CTA.
class DailyJournalScreen extends ConsumerStatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  ConsumerState<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends ConsumerState<DailyJournalScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please write something before sharing.',
            style: GoogleFonts.lexend(fontSize: 16)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    await ref.read(journalNotifierProvider.notifier).submit(text: text);
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalNotifierProvider);
    final question = ref.watch(dailyPromptQuestionProvider);

    ref.listen<JournalState>(journalNotifierProvider, (_, next) {
      if (next.status == JournalStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            next.errorMessage ?? 'Could not save. Please try again.',
            style: GoogleFonts.lexend(fontSize: 16),
          ),
          action: SnackBarAction(label: 'Retry', onPressed: _submit),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });

    return Scaffold(
      backgroundColor: ElderColors.surface,
      appBar: AppBar(
        backgroundColor: ElderColors.background,
        elevation: 0,
        leading: Semantics(
          label: 'Go back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 28,
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Daily Check-In',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ElderColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: journal.status == JournalStatus.submitted
            ? _ConfirmationView(moodLabel: journal.moodLabel)
            : _FormView(
                question: question,
                controller: _controller,
                journal: journal,
                onEmojiTap: (e) =>
                    ref.read(journalNotifierProvider.notifier).selectEmoji(e),
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// ── Form view ─────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final AsyncValue<String> question;
  final TextEditingController controller;
  final JournalState journal;
  final ValueChanged<String> onEmojiTap;
  final VoidCallback onSubmit;

  const _FormView({
    required this.question,
    required this.controller,
    required this.journal,
    required this.onEmojiTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ElderSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ElderSpacing.sm),
          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ElderSpacing.lg),
            decoration: BoxDecoration(
              color: ElderColors.primaryFixed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: question.when(
              data: (q) => Text(
                q,
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ElderColors.onPrimaryFixed,
                  height: 1.4,
                ),
              ),
              loading: () => const SizedBox(
                height: 32,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Text(
                'What is one thing that made you smile today?',
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ElderColors.onPrimaryFixed,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: ElderSpacing.xl),

          Text(
            'How are you feeling right now?',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ElderColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ElderSpacing.md),

          // Emoji row — 64×64 tap targets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _kEmojis.map((emoji) {
              final isSelected = journal.selectedEmoji == emoji;
              return Semantics(
                label: _emojiSemanticLabel(emoji),
                button: true,
                selected: isSelected,
                child: GestureDetector(
                  onTap: () => onEmojiTap(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ElderColors.primaryContainer
                          : ElderColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: ElderColors.primary, width: 2.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: ElderSpacing.xl),

          Text(
            'Write a few words\u2026',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ElderColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ElderSpacing.sm),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 10,
            style:
                GoogleFonts.lexend(fontSize: 18, color: ElderColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Share what is on your mind\u2026',
              hintStyle: GoogleFonts.lexend(
                  fontSize: 18, color: ElderColors.onSurfaceVariant),
              filled: true,
              fillColor: ElderColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: ElderColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: ElderColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: ElderColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(ElderSpacing.md),
            ),
          ),
          const SizedBox(height: ElderSpacing.xl),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  journal.status == JournalStatus.submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ElderColors.primary,
                foregroundColor: ElderColors.onPrimary,
                disabledBackgroundColor:
                    ElderColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: journal.status == JournalStatus.submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Share how I feel',
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: ElderSpacing.lg),
        ],
      ),
    );
  }

  String _emojiSemanticLabel(String emoji) {
    const labels = {
      '😄': 'Very happy',
      '🙂': 'Happy',
      '😐': 'Neutral',
      '😔': 'Sad',
      '😢': 'Very sad',
    };
    return labels[emoji] ?? emoji;
  }
}

// ── Confirmation view ─────────────────────────────────────────────────────────

class _ConfirmationView extends ConsumerWidget {
  final String? moodLabel;

  const _ConfirmationView({this.moodLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ElderSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ElderSpacing.xl),
              decoration: BoxDecoration(
                color: _moodColour(moodLabel),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite_rounded,
                      size: 64, color: ElderColors.primary),
                  const SizedBox(height: ElderSpacing.md),
                  Text(
                    'Entry saved!',
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: ElderSpacing.sm),
                  Text(
                    _moodMessage(moodLabel),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      color: ElderColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ElderSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(journalNotifierProvider.notifier).reset();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElderColors.primary,
                  foregroundColor: ElderColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ACCESSIBILITY AUDIT ─────────────────────────────────────────────────────
// ✅ Tap targets ≥ 48×48px (emoji circles 64×64, back button 48×48)
// ✅ Font sizes ≥ 16sp (question 24sp, body 18sp, button 20sp)
// ✅ Colour contrast WCAG AA (primary on white, onPrimaryFixed on primaryFixed)
// ✅ Semantic labels on emoji buttons and back icon
// ✅ No colour as sole differentiator (border + bg change on selected emoji)
// ✅ Touch targets separated ≥ 8px (spaceEvenly in emoji Row)
