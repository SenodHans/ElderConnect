// FcmTokenService — registers the device FCM token with Supabase after sign-in.
//
// Called from main.dart on every signedIn auth event.
// Upserts to fcm_tokens table (one row per user, keyed on user_id).
// Entirely non-fatal — the app functions without FCM; push notifications
// simply won't be delivered until the token is registered.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenService {
  /// Requests notification permission, fetches the FCM token, and upserts
  /// it to the fcm_tokens table for the currently authenticated user.
  static Future<void> registerToken() async {
    try {
      // iOS requires explicit permission before a token is issued.
      await FirebaseMessaging.instance.requestPermission();

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('fcm_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (_) {
      // Non-fatal — push notifications won't work but the app will.
    }
  }
}
