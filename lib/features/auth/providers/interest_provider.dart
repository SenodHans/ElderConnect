/// Riverpod provider for the elder's selected news interest categories.
///
/// Holds the in-memory selection during onboarding. Supabase write is
/// deferred to the registration completion sprint — only the local
/// `Set<String>` is managed here for now.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the set of selected NewsAPI category keys and a [toggle] method.
///
/// Categories are stored as lowercase strings that map directly to the
/// NewsAPI `category` query parameter:
/// `'health'`, `'sports'`, `'technology'`, `'entertainment'`, `'science'`, `'business'`
final selectedInterestsProvider =
    NotifierProvider<SelectedInterestsNotifier, Set<String>>(
  SelectedInterestsNotifier.new,
);

/// Notifier that manages the set of selected interest categories.
class SelectedInterestsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  /// Adds [category] if not already selected; removes it if it is.
  void toggle(String category) {
    if (state.contains(category)) {
      state = Set.of(state)..remove(category);
    } else {
      state = {...state, category};
    }
  }
}
