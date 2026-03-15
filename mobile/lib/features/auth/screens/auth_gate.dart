import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

/// Three-way router:
///   No session                     → [AuthScreen]
///   Session + onboarding incomplete → [OnboardingScreen]
///   Session + onboarding complete   → [DashboardScreen]
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync      = ref.watch(authStateChangesProvider);
    final currentSession = Supabase.instance.client.auth.currentSession;

    // Determine if there is an active session — use synchronous check as
    // fallback so there is no flicker on cold start.
    final hasSession = authAsync.valueOrNull?.session != null ||
        (authAsync.isLoading && currentSession != null);

    if (!hasSession) {
      return authAsync.isLoading
          ? _splash(context)   // brief spinner on very first frame
          : const AuthScreen();
    }

    // Authenticated — check onboarding completion.
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => _splash(context),
      error:   (_, __) => const DashboardScreen(), // fail open
      data: (profile) {
        if (profile == null || !profile.onboardingCompleted) {
          return const OnboardingScreen();
        }
        return const DashboardScreen();
      },
    );
  }

  Widget _splash(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
}
