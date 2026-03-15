// Run after adding this file:
//   flutter pub run build_runner build --delete-conflicting-outputs
// Generates: auth_provider.g.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

/// Streams every [AuthState] change from Supabase.
///
/// Used by [AuthGate] to switch between [AuthScreen] and [DashboardScreen].
/// The stream always emits the current session state on first subscription,
/// so there is no delay in deciding which screen to show.
@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}
