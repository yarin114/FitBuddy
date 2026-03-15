// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$macroSummaryHash() => r'436911fdfb44aae440564cba50945653e2b7206d';

/// Today's macro summary — fetched from GET /api/v1/macros/today.
///
/// Falls back to mock data when the user has no active Supabase session
/// (development / UI testing without auth).
///
/// Copied from [macroSummary].
@ProviderFor(macroSummary)
final macroSummaryProvider = AutoDisposeFutureProvider<MacroSummary>.internal(
  macroSummary,
  name: r'macroSummaryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$macroSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MacroSummaryRef = AutoDisposeFutureProviderRef<MacroSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
