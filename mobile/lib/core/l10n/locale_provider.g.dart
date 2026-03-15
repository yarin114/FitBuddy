// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localeNotifierHash() => r'd028e8099b2c67abed997fb7ac73d9db66bd1170';

/// Persisted locale notifier.
///
/// - Defaults to English on first launch.
/// - Immediately applies when [setLocale] is called.
/// - Persists the choice to SharedPreferences so it survives restarts.
///
/// Copied from [LocaleNotifier].
@ProviderFor(LocaleNotifier)
final localeNotifierProvider =
    AutoDisposeNotifierProvider<LocaleNotifier, Locale>.internal(
  LocaleNotifier.new,
  name: r'localeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocaleNotifier = AutoDisposeNotifier<Locale>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
