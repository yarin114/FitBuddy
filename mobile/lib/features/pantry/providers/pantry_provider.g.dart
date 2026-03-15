// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$expiringSoonItemsHash() => r'0d909126ba408d7bf88a506e7518bedaa59e5986';

/// Items expiring within the next 3 days, sorted soonest-first.
/// Drives the "Expiring Soon" urgency strip on PantryScreen.
///
/// Copied from [expiringSoonItems].
@ProviderFor(expiringSoonItems)
final expiringSoonItemsProvider =
    AutoDisposeProvider<List<PantryItem>>.internal(
  expiringSoonItems,
  name: r'expiringSoonItemsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$expiringSoonItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExpiringSoonItemsRef = AutoDisposeProviderRef<List<PantryItem>>;
String _$unverifiedItemsHash() => r'4fc115dbe5ed38d62af694cac9423ae42970bc8a';

/// Items flagged for manual verification (confidence < 0.70).
///
/// Copied from [unverifiedItems].
@ProviderFor(unverifiedItems)
final unverifiedItemsProvider = AutoDisposeProvider<List<PantryItem>>.internal(
  unverifiedItems,
  name: r'unverifiedItemsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unverifiedItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnverifiedItemsRef = AutoDisposeProviderRef<List<PantryItem>>;
String _$smartSuggestionsHash() => r'962662ac2e5dfe939bbe6a8a99452b23e8a8b221';

/// Smart recipe suggestions: recipes whose required ingredients are
/// (at least partially) covered by the current inventory.
///
/// [RecipeSuggestion] is a lightweight model — the full Meal model
/// lives in the meals feature and is mapped by the backend.
///
/// Copied from [smartSuggestions].
@ProviderFor(smartSuggestions)
final smartSuggestionsProvider =
    AutoDisposeProvider<List<RecipeSuggestion>>.internal(
  smartSuggestions,
  name: r'smartSuggestionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartSuggestionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SmartSuggestionsRef = AutoDisposeProviderRef<List<RecipeSuggestion>>;
String _$filteredRecipesHash() => r'5dcdcd0048307a78220639fe0e4e0790a871c168';

/// Filtered recipe suggestions — only recipes where >80% of ingredients
/// are in the current inventory ("Cookable Now").
///
/// Threshold: 0.8 — user has at least 4 out of 5 required ingredients.
///
/// Copied from [filteredRecipes].
@ProviderFor(filteredRecipes)
final filteredRecipesProvider =
    AutoDisposeProvider<List<RecipeSuggestion>>.internal(
  filteredRecipes,
  name: r'filteredRecipesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredRecipesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredRecipesRef = AutoDisposeProviderRef<List<RecipeSuggestion>>;
String _$pantryNotifierHash() => r'ec35c5df90c1dc04fe5a09bf1ce715dc837b4ab0';

/// The single source of truth for the user's current pantry inventory.
///
/// NOTE: Rule 7 specifies StateProvider — this uses the modern NotifierProvider
/// API (StateProvider is legacy in Riverpod 2.x / deprecated in 3.0).
/// The public API is identical to what Rule 7 describes.
///
/// Copied from [PantryNotifier].
@ProviderFor(PantryNotifier)
final pantryNotifierProvider =
    AutoDisposeNotifierProvider<PantryNotifier, List<PantryItem>>.internal(
  PantryNotifier.new,
  name: r'pantryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pantryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PantryNotifier = AutoDisposeNotifier<List<PantryItem>>;
String _$receiptScannerHash() => r'e0695ab5d7ab80cb8b2a07d70f0a1d56be93230d';

/// Handles the async OCR scan flow.
/// State: AsyncValue<List<PantryItem>> — Loading / Data / Error.
///
/// Copied from [ReceiptScanner].
@ProviderFor(ReceiptScanner)
final receiptScannerProvider = AutoDisposeNotifierProvider<ReceiptScanner,
    AsyncValue<List<PantryItem>>>.internal(
  ReceiptScanner.new,
  name: r'receiptScannerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$receiptScannerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReceiptScanner = AutoDisposeNotifier<AsyncValue<List<PantryItem>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
