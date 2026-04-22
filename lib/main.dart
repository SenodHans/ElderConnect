import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/auth/services/fcm_token_service.dart';
import 'firebase_options.dart';

// Top-level handler for FCM messages received when the app is in the background
// or terminated. Must be a top-level function — cannot be a class method.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Android notification channel for medication reminders.
const AndroidNotificationChannel _medicationChannel = AndroidNotificationChannel(
  'medication_reminders',
  'Medication Reminders',
  description: 'Reminders for your scheduled medications.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler before runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create the Android notification channel — no-op on iOS.
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_medicationChannel);

  // Initialise flutter_local_notifications for both platforms.
  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  runApp(const ProviderScope(child: ElderConnectApp()));

  // Register FCM token on every sign-in (caretaker login, elder session restore, token refresh).
  Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.event == AuthChangeEvent.signedIn) {
      FcmTokenService.registerToken();
    }
  });

  // Show a local notification when a FCM message arrives while the app is in the foreground.
  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _medicationChannel.id,
          _medicationChannel.name,
          channelDescription: _medicationChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  });
}
