import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/l10n/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_gate.dart';
import 'l10n/app_localizations.dart';

/// FitBuddy — entry point.
///
/// Auth:   Supabase
/// Push:   Firebase Cloud Messaging
/// i18n:   flutter_localizations (en + he / RTL support)
const String _supabaseUrl  = 'https://ijtopsxgvrnmebcpenmy.supabase.co';
const String _supabaseAnon = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqdG9wc3hndnJubWViY3Blbm15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1NjQwNjMsImV4cCI6MjA4OTE0MDA2M30.gSrfhbCvhGNLbVykKfuTYIqYShUx751iot1cOTDyT4A';

/// Background FCM message handler — must be top-level.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // No UI work here — just logging. Foreground handling is in AuthGate.
  debugPrint('FCM background: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnon);

  // Firebase — required for FCM push notifications.
  // google-services.json must be present at android/app/google-services.json.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  } catch (e) {
    // Fail gracefully — all non-push features still work.
    debugPrint('Firebase init skipped: $e');
  }

  // Load the persisted locale before rendering to avoid a one-frame flicker.
  final container = ProviderContainer();
  await container.read(localeNotifierProvider.notifier).loadSaved();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FitBuddyApp(),
    ),
  );
}

class FitBuddyApp extends ConsumerWidget {
  const FitBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp(
      title:                      'FitBuddy',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.light,
      darkTheme:                  AppTheme.dark,
      themeMode:                  ThemeMode.dark,

      // ── i18n ────────────────────────────────────────────────────────────────
      locale:             locale,
      supportedLocales:   supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // AuthGate decides: DashboardScreen, OnboardingScreen, or AuthScreen.
      home: const AuthGate(),
    );
  }
}
