import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

const _kLocaleKey = 'preferred_locale';

/// Supported locales in order of preference.
const supportedLocales = [
  Locale('en'),
  Locale('he'),
];

/// Persisted locale notifier.
///
/// - Defaults to English on first launch.
/// - Immediately applies when [setLocale] is called.
/// - Persists the choice to SharedPreferences so it survives restarts.
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() => const Locale('en'); // synchronous default

  /// Load the saved locale from SharedPreferences.
  /// Call this once during app startup (see main.dart).
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code  = prefs.getString(_kLocaleKey) ?? 'en';
    state = Locale(code);
  }

  /// Change the active locale and persist it.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  /// Convenience: toggle between en ↔ he.
  Future<void> toggle() async {
    final next = state.languageCode == 'en' ? const Locale('he') : const Locale('en');
    await setLocale(next);
  }
}
