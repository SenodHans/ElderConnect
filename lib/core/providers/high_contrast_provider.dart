/// Global state for the elder's high-contrast accessibility preference.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, the app renders with a higher-contrast theme variant.
/// Persisted locally for the session; written to DB in future sprint.
final highContrastProvider = StateProvider<bool>((ref) => false);
