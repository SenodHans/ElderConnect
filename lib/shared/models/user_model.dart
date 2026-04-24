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
    this.pinPlain,
    this.avatarUrl,
    this.emergencyContactName,
    this.emergencyContactPhone,
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

  /// bcrypt-hashed 4-digit PIN. Null until elder creates PIN at registration.
  final String? pinHash;

  /// Plain-text PIN — only readable by a linked caretaker via RLS.
  /// Stored so caretaker can remind elder of their PIN if forgotten.
  final String? pinPlain;

  /// Supabase Storage URL for the elder's profile photo.
  final String? avatarUrl;

  /// Display name of the elder's primary emergency contact.
  final String? emergencyContactName;

  /// Phone number of the elder's primary emergency contact.
  final String? emergencyContactPhone;

  final DateTime createdAt;

  /// Convenience getter — first word of [fullName].
  String get firstName => fullName.split(' ').first;

  /// Whether this user is an elderly portal user.
  bool get isElderly => role == 'elderly';

  /// Whether this user is a caretaker portal user.
  bool get isCaretaker => role == 'caretaker';

  /// Whether a primary emergency contact has been set.
  bool get hasEmergencyContact =>
      emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty;

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
      pinPlain: json['pin_plain'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  UserModel copyWith({
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      email: email,
      role: role,
      fullName: fullName,
      phone: phone,
      dateOfBirth: dateOfBirth,
      interests: interests,
      ttsEnabled: ttsEnabled,
      moodSharingConsent: moodSharingConsent,
      pinHash: pinHash,
      pinPlain: pinPlain,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      createdAt: createdAt,
    );
  }
}
