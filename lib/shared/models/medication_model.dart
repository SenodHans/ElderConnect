/// Dart models for the `medications` and `medication_logs` tables.
/// Used by [medicationsProvider] to drive the medication list screen
/// and the conditional nav tab.
library;

import 'package:intl/intl.dart';

/// A medication row — created by a caretaker for a linked elder.
class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.elderlyUserId,
    required this.pillName,
    required this.pillColour,
    required this.dosage,
    required this.reminderTimes,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String elderlyUserId;
  final String pillName;
  final String pillColour;
  final String dosage;

  /// PostgreSQL time[] comes back as List of "HH:MM:SS" strings.
  final List<String> reminderTimes;
  final bool isActive;
  final DateTime createdAt;

  /// Returns the first reminder time formatted as "H:MM AM/PM", or empty string.
  String get nextReminderFormatted {
    if (reminderTimes.isEmpty) return '';
    final parts = reminderTimes.first.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    final times = (json['reminder_times'] as List<dynamic>? ?? [])
        .map((t) => t.toString())
        .toList();
    return MedicationModel(
      id: json['id'] as String,
      elderlyUserId: json['elderly_user_id'] as String,
      pillName: json['pill_name'] as String,
      pillColour: json['pill_colour'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      reminderTimes: times,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

/// A medication log entry — one scheduled dose with its status.
/// Joined with the parent medication for pill name and dosage.
class MedicationLogModel {
  const MedicationLogModel({
    required this.id,
    required this.medicationId,
    required this.pillName,
    required this.dosage,
    required this.scheduledTime,
    required this.status,
    this.takenAt,
  });

  final String id;
  final String medicationId;

  /// Resolved from `medications.pill_name` via join.
  final String pillName;

  /// Resolved from `medications.dosage` via join.
  final String dosage;

  final DateTime scheduledTime;
  final DateTime? takenAt;

  /// One of: 'pending' | 'taken' | 'missed'
  final String status;

  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';
  bool get isPending => status == 'pending';

  /// Formats scheduledTime as "Today, 8:05 AM" or "Yesterday, 8:00 AM" etc.
  String get timestampFormatted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    );
    final time = DateFormat('h:mm a').format(scheduledTime);
    if (day == today) return 'Today, $time';
    if (day == yesterday) return 'Yesterday, $time';
    return '${DateFormat('MMM d').format(scheduledTime)}, $time';
  }

  /// Parses a row from:
  ///   `medication_logs.select('*, medications!medication_id(pill_name, dosage)')`
  factory MedicationLogModel.fromJson(Map<String, dynamic> json) {
    final med = json['medications'] as Map<String, dynamic>?;
    return MedicationLogModel(
      id: json['id'] as String,
      medicationId: json['medication_id'] as String,
      pillName: med?['pill_name'] as String? ?? 'Medication',
      dosage: med?['dosage'] as String? ?? '',
      scheduledTime:
          DateTime.parse(json['scheduled_time'] as String).toLocal(),
      takenAt: json['taken_at'] != null
          ? DateTime.parse(json['taken_at'] as String).toLocal()
          : null,
      status: json['status'] as String,
    );
  }
}
