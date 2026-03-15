import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

/// Handles FCM permission request and token registration with the backend.
///
/// Call [registerAndSync] once after the user is authenticated.
/// Safe to call multiple times — it no-ops when Firebase is unavailable.
class FcmService {
  const FcmService._();

  /// Request notification permission, get the device FCM token,
  /// and register it with the backend via PUT /api/v1/users/me/fcm-token.
  static Future<void> registerAndSync(Dio dio) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (shows system dialog on iOS; no-op on Android 12-).
      final settings = await messaging.requestPermission(
        alert:         true,
        badge:         true,
        sound:         true,
        announcement:  false,
        carPlay:       false,
        criticalAlert: false,
        provisional:   false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FcmService: notification permission denied');
        return;
      }

      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('FcmService: no FCM token (emulator / no Google Play Services?)');
        return;
      }

      debugPrint('FcmService: registering token (${token.substring(0, 12)}…)');

      await dio.put<void>(
        '/api/v1/users/me/fcm-token',
        queryParameters: {'fcm_token': token},
      );

      // Refresh the token whenever it rotates.
      messaging.onTokenRefresh.listen((newToken) async {
        try {
          await dio.put<void>(
            '/api/v1/users/me/fcm-token',
            queryParameters: {'fcm_token': newToken},
          );
        } catch (e) {
          debugPrint('FcmService: token refresh sync failed: $e');
        }
      });
    } catch (e) {
      // Firebase not initialised (e.g. missing google-services.json) — fail silently.
      debugPrint('FcmService: unavailable — $e');
    }
  }
}
