// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$macroSummaryHash() => r'290344b806068d0a30398c240b4b977d9fb39b0c';

/// Today's macro summary.
///
/// Currently returns mock data so the UI can be tested without a live backend.
/// Replace the body of this provider with a real API call when backend is ready:
///   final response = await ref.read(apiClientProvider).get('/api/v1/macros/today');
///   return MacroSummary.fromJson(response.data);
///
/// Copied from [macroSummary].
@ProviderFor(macroSummary)
final macroSummaryProvider = AutoDisposeProvider<MacroSummary>.internal(
  macroSummary,
  name: r'macroSummaryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$macroSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MacroSummaryRef = AutoDisposeProviderRef<MacroSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
