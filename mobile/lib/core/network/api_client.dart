import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'api_client.g.dart';

/// Base URL of the FitBuddy FastAPI backend.
///
/// Override with your Render/Railway deploy URL in production.
/// In local dev, use the machine's LAN IP so the device can reach it.
const String _kBaseUrl = 'http://192.168.68.58:8001'; // physical device → PC over LAN

/// Dio HTTP client pre-configured with:
/// - Base URL pointing at the FastAPI backend
/// - `Authorization: Bearer <supabase-token>` injected on every request
/// - 30 s connect + receive timeout
@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl:        _kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Supabase auth interceptor — attaches the current session JWT on every request.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}
