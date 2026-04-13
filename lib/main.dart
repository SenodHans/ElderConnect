import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase — supply credentials via --dart-define at build time,
  // never commit real keys to version control.
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // TODO: Initialise Firebase for FCM once firebase_options.dart is generated
  // by the FlutterFire CLI (flutterfire configure).

  runApp(
    // ProviderScope wraps the entire app for Riverpod state management.
    const ProviderScope(
      child: ElderConnectApp(),
    ),
  );
}
