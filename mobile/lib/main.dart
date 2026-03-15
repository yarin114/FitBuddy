import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_gate.dart';

/// FitBuddy — entry point.
///
/// Auth: Supabase
///   SUPABASE_URL  — Project Settings → API → Project URL
///   SUPABASE_ANON — Project Settings → API → anon / public key
///
/// FCM: google-services.json / GoogleService-Info.plist are required for push
/// notifications.  When those files are not present (UI testing), FCM is
/// simply inactive — all non-push features work normally.
///
/// TODO: move Supabase URL + key out of source once you have a build-time
/// env-var mechanism (e.g. --dart-define or flutter_dotenv).
const String _supabaseUrl  = 'https://ijtopsxgvrnmebcpenmy.supabase.co';
const String _supabaseAnon = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqdG9wc3hndnJubWViY3Blbm15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1NjQwNjMsImV4cCI6MjA4OTE0MDA2M30.gSrfhbCvhGNLbVykKfuTYIqYShUx751iot1cOTDyT4A';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     _supabaseUrl,
    anonKey: _supabaseAnon,
  );

  // TODO: uncomment once google-services.json / GoogleService-Info.plist are added:
  // import 'package:firebase_core/firebase_core.dart';
  // import 'firebase_options.dart';
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const ProviderScope(
      child: FitBuddyApp(),
    ),
  );
}

class FitBuddyApp extends StatelessWidget {
  const FitBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'FitBuddy',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.light,
      darkTheme:                  AppTheme.dark,
      themeMode:                  ThemeMode.dark,
      // AuthGate decides: DashboardScreen (logged in) or AuthScreen (logged out).
      home: const AuthGate(),
    );
  }
}
