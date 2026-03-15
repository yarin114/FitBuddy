import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

/// Listens to Supabase auth state and routes to the correct screen.
///
/// - Authenticated  → [DashboardScreen]
/// - Unauthenticated → [AuthScreen]
///
/// Uses the synchronous [currentSession] for the loading state so there is
/// no flash of the wrong screen on hot-restart or cold start.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState     = ref.watch(authStateChangesProvider);
    final currentSession = Supabase.instance.client.auth.currentSession;

    return asyncState.when(
      // Stream has emitted: use the real session from the event.
      data: (state) => state.session != null
          ? const DashboardScreen()
          : const AuthScreen(),

      // Stream not yet emitted: fall back to the synchronous session check
      // so the user never sees a spinner if they're already logged in.
      loading: () => currentSession != null
          ? const DashboardScreen()
          : const AuthScreen(),

      error: (_, __) => const AuthScreen(),
    );
  }
}
