// Unit tests for MedicationModel and MedicationLogModel.
//
// MedicationModel — covers field parsing including the PostgreSQL time[]
// reminder_times array and the nextReminderFormatted computed getter.
//
// MedicationLogModel — covers field parsing including the joined
// medications!medication_id(pill_name, dosage) embed, status flags,
// and the timestampFormatted computed getter.

import 'package:flutter_test/flutter_test.dart';
import 'package:elder_connect/shared/models/medication_model.dart';

void main() {
  // ── MedicationModel ─────────────────────────────────────────────────────────

  group('MedicationModel.fromJson', () {
    final Map<String, dynamic> fullRow = {
      'id': 'med-001',
      'elderly_user_id': 'elder-001',
      'pill_name': 'Lisinopril',
      'pill_colour': 'White',
      'dosage': '10mg',
      'reminder_times': ['08:00:00', '20:00:00'],
      'is_active': true,
      'created_at': '2024-03-01T00:00:00.000Z',
    };

    test('parses all required fields', () {
      final med = MedicationModel.fromJson(fullRow);
      expect(med.id, 'med-001');
      expect(med.elderlyUserId, 'elder-001');
      expect(med.pillName, 'Lisinopril');
      expect(med.pillColour, 'White');
      expect(med.dosage, '10mg');
      expect(med.isActive, isTrue);
    });

    test('parses reminder_times array', () {
      final med = MedicationModel.fromJson(fullRow);
      expect(med.reminderTimes, ['08:00:00', '20:00:00']);
    });

    test('reminderTimes defaults to empty when null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['reminder_times'] = null;
      final med = MedicationModel.fromJson(row);
      expect(med.reminderTimes, isEmpty);
    });

    test('pillColour defaults to empty string when null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['pill_colour'] = null;
      final med = MedicationModel.fromJson(row);
      expect(med.pillColour, '');
    });

    test('dosage defaults to empty string when null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['dosage'] = null;
      final med = MedicationModel.fromJson(row);
      expect(med.dosage, '');
    });

    test('is_active defaults to true when null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['is_active'] = null;
      final med = MedicationModel.fromJson(row);
      expect(med.isActive, isTrue);
    });
  });

  group('MedicationModel.nextReminderFormatted', () {
    test('formats 08:00:00 as 8:00 AM', () {
      final med = MedicationModel.fromJson({
        'id': 'm1',
        'elderly_user_id': 'e1',
        'pill_name': 'Test',
        'pill_colour': 'Blue',
        'dosage': '5mg',
        'reminder_times': ['08:00:00'],
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(med.nextReminderFormatted, '8:00 AM');
    });

    test('formats 20:30:00 as 8:30 PM', () {
      final med = MedicationModel.fromJson({
        'id': 'm2',
        'elderly_user_id': 'e1',
        'pill_name': 'Test',
        'pill_colour': 'Blue',
        'dosage': '5mg',
        'reminder_times': ['20:30:00'],
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(med.nextReminderFormatted, '8:30 PM');
    });

    test('returns empty string when reminder_times is empty', () {
      final med = MedicationModel.fromJson({
        'id': 'm3',
        'elderly_user_id': 'e1',
        'pill_name': 'Test',
        'pill_colour': 'Blue',
        'dosage': '5mg',
        'reminder_times': <dynamic>[],
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(med.nextReminderFormatted, '');
    });
  });

  // ── MedicationLogModel ──────────────────────────────────────────────────────

  group('MedicationLogModel.fromJson', () {
    final now = DateTime.now();
    final Map<String, dynamic> fullRow = {
      'id': 'log-001',
      'medication_id': 'med-001',
      'scheduled_time': now.toIso8601String(),
      'taken_at': null,
      'status': 'pending',
      'medications': {'pill_name': 'Metformin', 'dosage': '500mg'},
    };

    test('parses required fields', () {
      final log = MedicationLogModel.fromJson(fullRow);
      expect(log.id, 'log-001');
      expect(log.medicationId, 'med-001');
      expect(log.status, 'pending');
    });

    test('resolves pill name from join', () {
      final log = MedicationLogModel.fromJson(fullRow);
      expect(log.pillName, 'Metformin');
    });

    test('resolves dosage from join', () {
      final log = MedicationLogModel.fromJson(fullRow);
      expect(log.dosage, '500mg');
    });

    test('pillName defaults to "Medication" when join is null', () {
      final row = Map<String, dynamic>.from(fullRow)
        ..['medications'] = null;
      final log = MedicationLogModel.fromJson(row);
      expect(log.pillName, 'Medication');
    });

    test('takenAt is null when field is absent', () {
      final log = MedicationLogModel.fromJson(fullRow);
      expect(log.takenAt, isNull);
    });

    test('takenAt is parsed when present', () {
      final takenTime = DateTime(2024, 6, 1, 9, 5);
      final row = Map<String, dynamic>.from(fullRow)
        ..['taken_at'] = takenTime.toIso8601String();
      final log = MedicationLogModel.fromJson(row);
      expect(log.takenAt, isNotNull);
    });
  });

  group('MedicationLogModel status flags', () {
    MedicationLogModel makeLog(String status) => MedicationLogModel.fromJson({
          'id': 'l1',
          'medication_id': 'm1',
          'scheduled_time': DateTime.now().toIso8601String(),
          'taken_at': null,
          'status': status,
          'medications': {'pill_name': 'Test', 'dosage': '10mg'},
        });

    test('isPending is true for pending status', () {
      expect(makeLog('pending').isPending, isTrue);
      expect(makeLog('pending').isTaken, isFalse);
      expect(makeLog('pending').isMissed, isFalse);
    });

    test('isTaken is true for taken status', () {
      expect(makeLog('taken').isTaken, isTrue);
      expect(makeLog('taken').isPending, isFalse);
    });

    test('isMissed is true for missed status', () {
      expect(makeLog('missed').isMissed, isTrue);
      expect(makeLog('missed').isPending, isFalse);
    });
  });

  group('MedicationLogModel.timestampFormatted', () {
    test('returns "Today, ..." for today\'s scheduled time', () {
      final now = DateTime.now();
      final log = MedicationLogModel.fromJson({
        'id': 'l1',
        'medication_id': 'm1',
        'scheduled_time': now.toIso8601String(),
        'taken_at': null,
        'status': 'pending',
        'medications': {'pill_name': 'Test', 'dosage': '10mg'},
      });
      expect(log.timestampFormatted, startsWith('Today,'));
    });

    test('returns "Yesterday, ..." for yesterday\'s scheduled time', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final log = MedicationLogModel.fromJson({
        'id': 'l2',
        'medication_id': 'm1',
        'scheduled_time': yesterday.toIso8601String(),
        'taken_at': null,
        'status': 'missed',
        'medications': {'pill_name': 'Test', 'dosage': '10mg'},
      });
      expect(log.timestampFormatted, startsWith('Yesterday,'));
    });

    test('returns date string for older entries', () {
      final old = DateTime(2024, 3, 15, 8, 0);
      final log = MedicationLogModel.fromJson({
        'id': 'l3',
        'medication_id': 'm1',
        'scheduled_time': old.toIso8601String(),
        'taken_at': null,
        'status': 'missed',
        'medications': {'pill_name': 'Test', 'dosage': '10mg'},
      });
      expect(log.timestampFormatted, contains('Mar 15'));
    });
  });
}
