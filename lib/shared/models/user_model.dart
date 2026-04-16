/// Data model representing a row in the [users] Supabase table.
///
/// Used by [userProvider] to expose the logged-in user's profile
/// across the entire app. Immutable — state updates come through
/// the Realtime stream, not mutations on this object.
library;

/// Maps a Supabase [users] row to a strongly-typed Dart model.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    required this.interests,
    required this.ttsEnabled,
    required this.moodSharingConsent,
    required this.createdAt,
    this.phone,
    this.dateOfBirth,
    this.pinHash,
  });

  final String id;
  final String email;

  /// 'elderly' or 'caretaker' — matches the user_role enum in the schema.
  final String role;

  final String fullName;

  /// Nullable — phone number is optional at registration time.
  final String? phone;

  /// Nullable — not all users supply a date of birth.
  final DateTime? dateOfBirth;

  /// NewsAPI category keys, e.g. ['health', 'sports', 'technology'].
  final List<String> interests;

  /// Whether text-to-speech is enabled for this elder.
  final bool ttsEnabled;

  /// Whether the caretaker is allowed to read this elder's mood logs.
  final bool moodSharingConsent;

  /// bcrypt-hashed 4-digit PIN. Null until set by a caretaker.
  final String? pinHash;

  final DateTime createdAt;

  /// Convenience getter — first word of [fullName].
  String get firstName => fullName.split(' ').first;

  /// Whether this user is an elderly portal user.
  bool get isElderly => role == 'elderly';

  /// Whether this user is a caretaker portal user.
  bool get isCaretaker => role == 'caretaker';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      ttsEnabled: json['tts_enabled'] as bool? ?? false,
      moodSharingConsent: json['mood_sharing_consent'] as bool? ?? false,
      pinHash: json['pin_hash'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
