import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

/// FitBuddy — entry point.
///
/// Auth: Supabase (replace the placeholder values with your project credentials).
///   SUPABASE_URL  — Project Settings → API → Project URL
///   SUPABASE_ANON — Project Settings → API → anon / public key
///
/// FCM: google-services.json / GoogleService-Info.plist are required for push
/// notifications.  When those files are not present (UI testing), FCM is
/// simply inactive — all non-push features work normally.
///
/// TODO: move Supabase URL + key out of source once you have a build-time
/// env-var mechanism (e.g. --dart-define or flutter_dotenv).
const String _supabaseUrl  = 'YOUR_SUPABASE_URL';   // replace before first run
const String _supabaseAnon = 'YOUR_SUPABASE_ANON';  // replace before first run

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:    _supabaseUrl,
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
      title:                    'FitBuddy',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.light,
      darkTheme:                AppTheme.dark,
      themeMode:                ThemeMode.dark,
      home:                     const DashboardScreen(),
    );
  }
}
