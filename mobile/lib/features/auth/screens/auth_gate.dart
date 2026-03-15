import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/fcm_service.dart';
import '../../../core/network/api_client.dart';
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

    final hasSession = authAsync.valueOrNull?.session != null ||
        (authAsync.isLoading && currentSession != null);

    if (!hasSession) {
      return authAsync.isLoading
          ? _splash(context)
          : const AuthScreen();
    }

    // Authenticated — register FCM token once per session.
    _syncFcmToken(ref);

    // Check onboarding completion.
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => _splash(context),
      error:   (_, __) => const DashboardScreen(),
      data: (profile) {
        if (profile == null || !profile.onboardingCompleted) {
          return const OnboardingScreen();
        }
        return const DashboardScreen();
      },
    );
  }

  /// Register the FCM token with the backend after login.
  /// Uses a flag in the provider to ensure it only runs once per session.
  void _syncFcmToken(WidgetRef ref) {
    // Fire-and-forget; errors are caught inside FcmService.
    final dio = ref.read(apiClientProvider);
    FcmService.registerAndSync(dio);
  }

  Widget _splash(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
}
