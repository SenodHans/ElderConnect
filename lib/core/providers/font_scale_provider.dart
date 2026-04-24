import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global text scale factor for the elder portal.
/// Cycles: 1.0 (Normal) → 1.2 (Large) → 1.4 (Extra Large) → 1.0
final fontScaleProvider = StateProvider<double>((ref) => 1.0);

extension FontScaleX on double {
  double get next => this == 1.0 ? 1.2 : this == 1.2 ? 1.4 : 1.0;
  String get aaLabel => this == 1.4 ? 'XL' : this == 1.2 ? 'Lg' : 'A';
}
