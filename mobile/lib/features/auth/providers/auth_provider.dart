// Run after modifying this file:
//   flutter pub run build_runner build --delete-conflicting-outputs
// Generates: auth_provider.g.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_client.dart';
import '../models/user_profile.dart';

part 'auth_provider.g.dart';

/// Streams every [AuthState] change from Supabase.
/// Used by [AuthGate] to react instantly to login / logout.
@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}

/// Fetches the current user's profile from GET /api/v1/users/me.
///
/// Returns null when there is no active session or on network error.
/// Invalidate via `ref.invalidate(userProfileProvider)` after onboarding
/// completes to force a re-fetch and trigger [AuthGate] re-routing.
@riverpod
Future<UserProfile?> userProfile(Ref ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;

  try {
    final dio      = ref.read(apiClientProvider);
    final response = await dio.get<Map<String, dynamic>>('/api/v1/users/me');
    return UserProfile.fromJson(response.data!);
  } on DioException {
    return null;
  }
}
