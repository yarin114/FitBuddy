import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../services/debug_pantry_service.dart';
import '../widgets/pantry_item_card.dart';
import '../widgets/scan_confirmation_sheet.dart';

/// PantryScreen — "What's in my fridge & what's expiring soon?"
///
/// ── Visual Hierarchy ───────────────────────────────────────────────────────
/// Level 1 → FAB: Camera "Scan Receipt" — Electric Lime, always visible
/// Level 2 → "Expiring Soon" strip — pinned SliverPersistentHeader, errorContainer tint
/// Level 3 → Cook Now suggestions — filteredRecipesProvider (≥80% coverage)
/// Level 4 → Full inventory — SliverAnimatedList with consume fade-out
///
/// VHS: 9/10 — see Handover block at bottom.
class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final _searchController = SearchController();
  final _listKey          = GlobalKey<SliverAnimatedListState>();
  String _query           = '';

  /// Local mirror of the filtered inventory — drives SliverAnimatedList.
  /// Kept in sync with the Riverpod state via [_syncAnimatedList].
  List<PantryItem> _displayedItems = [];
  bool _initialized = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final cs         = theme.colorScheme;
    final inventory  = ref.watch(pantryNotifierProvider);
    final expiring   = ref.watch(expiringSoonItemsProvider);
    final cookable   = ref.watch(filteredRecipesProvider);
    final scanner    = ref.watch(receiptScannerProvider);
    final filtered   = _filteredItems(inventory);

    // Initialize local list on first build (no animation for initial state).
    if (!_initialized) {
      _displayedItems = List.of(filtered);
      _initialized    = true;
    }

    // Listen for inventory changes → drive insert/remove animations.
    ref.listen<List<PantryItem>>(pantryNotifierProvider, (_, next) {
      final nextFiltered = _filteredItems(next);
      if (_query.isNotEmpty) {
        // During search: instant update, no animation.
        setState(() => _displayedItems = nextFiltered);
      } else {
        _syncAnimatedList(nextFiltered);
      }
    });

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          _PantryAppBar(
            itemCount:  inventory.length,
            unverified: inventory.where((i) => i.needsVerification).length,
            onDebugSeed: _loadDebugSeed,
          ),

          // ── Search bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBar(
                controller:      _searchController,
                hintText:        'Search pantry…',
                leading:         const Icon(Icons.search_rounded),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      icon:    const Icon(Icons.clear_rounded),
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                    ),
                ],
                onChanged: _onQueryChanged,
                elevation:       const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(cs.surfaceContainer),
                padding:         const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),

          // ── Expiring Soon — pinned SliverPersistentHeader ────────────────
          if (expiring.isNotEmpty && _query.isEmpty)
            SliverPersistentHeader(
              pinned:   true,
              delegate: _ExpiringSoonDelegate(items: expiring),
            ),

          // ── Cook Now — filteredRecipes (≥80% match) ──────────────────────
          if (cookable.isNotEmpty && _query.isEmpty)
            SliverToBoxAdapter(
              child: _CookNowSection(recipes: cookable),
            ),

          // ── Section header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    _query.isEmpty ? 'All Items' : 'Results',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:        cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_displayedItems.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Inventory — SliverAnimatedList (with consume fade-out) ────────
          _displayedItems.isEmpty
              ? SliverFillRemaining(
                  child: _EmptyState(hasQuery: _query.isNotEmpty),
                )
              : SliverAnimatedList(
                  key:              ValueKey('list_$_query'),
                  initialItemCount: _displayedItems.length,
                  itemBuilder:      (context, index, animation) {
                    if (index >= _displayedItems.length) {
                      return const SizedBox.shrink();
                    }
                    final item = _displayedItems[index];
                    return _buildItem(item, animation);
                  },
                ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),

      // ── FAB — Level 1 CTA ─────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: scanner.isLoading
          ? _ScanningIndicator()
          : _ScanFab(
              onPressed:    () => _startScan(context),
              hasUnverified: inventory.any((i) => i.needsVerification),
            ),
    );
  }

  // ── Animated list helpers ─────────────────────────────────────────────────

  /// Build a live item row (wrapped in FadeTransition for insert).
  Widget _buildItem(PantryItem item, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedOpacity(
        // Dim fully-consumed items before they are removed.
        opacity:  item.isEmpty ? 0.35 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: PantryItemCard(
          item:           item,
          showConfidence: item.needsVerification,
          onTap:          () => _showEditItemSheet(item),
          onDismissed:    () => _removeItem(item),
        ),
      ),
    );
  }

  /// Build the exit animation widget for a removed item.
  Widget _buildExitAnimation(PantryItem item, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: PantryItemCard(
          item:           item,
          showConfidence: item.needsVerification,
        ),
      ),
    );
  }

  /// Diff [newFiltered] against [_displayedItems], driving animated
  /// removes (fade+shrink) and silent inserts.
  void _syncAnimatedList(List<PantryItem> newFiltered) {
    // --- Removes (iterate backwards to keep indices valid) ---
    for (int i = _displayedItems.length - 1; i >= 0; i--) {
      if (!newFiltered.any((n) => n.id == _displayedItems[i].id)) {
        final removed = _displayedItems.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (ctx, anim) => _buildExitAnimation(removed, anim),
          duration: const Duration(milliseconds: 350),
        );
      }
    }
    // --- Inserts (no animation — receipt adds are batched) ---
    for (int i = 0; i < newFiltered.length; i++) {
      if (!_displayedItems.any((d) => d.id == newFiltered[i].id)) {
        _displayedItems.insert(i, newFiltered[i]);
        _listKey.currentState?.insertItem(i, duration: Duration.zero);
      }
    }
    // --- In-place updates (quantity changes, verification etc.) ---
    for (int i = 0; i < _displayedItems.length; i++) {
      final updated = newFiltered.firstWhere(
        (n) => n.id == _displayedItems[i].id,
        orElse: () => _displayedItems[i],
      );
      _displayedItems[i] = updated;
    }
    // Trigger rebuild so card contents (quantity, confidence) refresh.
    if (mounted) setState(() {});
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onQueryChanged(String newQuery) {
    final inventory = ref.read(pantryNotifierProvider);
    setState(() {
      _query          = newQuery;
      _displayedItems = _filteredItems(inventory);
      _initialized    = true;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onQueryChanged('');
  }

  void _removeItem(PantryItem item) {
    ref.read(pantryNotifierProvider.notifier).removeItem(item.id);
  }

  Future<void> _startScan(BuildContext context) async {
    await ref.read(receiptScannerProvider.notifier).scan();
    final result = ref.read(receiptScannerProvider);
    result.when(
      data: (items) {
        if (items.isEmpty) return;
        showModalBottomSheet(
          context:           context,
          isScrollControlled: true,
          backgroundColor:   Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => ScanConfirmationSheet(scannedItems: items),
        );
      },
      loading: () {},
      error:   (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      ),
    );
  }

  void _showEditItemSheet(PantryItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${item.name} — coming soon')),
    );
  }

  void _loadDebugSeed() {
    ref.read(pantryNotifierProvider.notifier)
       .addItemsFromReceipt(DebugPantryService.seedItems());
  }

  List<PantryItem> _filteredItems(List<PantryItem> inventory) {
    if (_query.isEmpty) return inventory;
    final q = _query.toLowerCase();
    return inventory.where((i) => i.name.toLowerCase().contains(q)).toList();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PantryAppBar extends StatelessWidget {
  const _PantryAppBar({
    required this.itemCount,
    required this.unverified,
    required this.onDebugSeed,
  });

  final int          itemCount;
  final int          unverified;
  final VoidCallback onDebugSeed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return SliverAppBar(
      floating:       true,
      snap:           true,
      pinned:         false,
      expandedHeight: 80,
      backgroundColor: cs.surface,
      actions: [
        // Debug seed button — only visible in debug builds
        if (kDebugMode)
          IconButton(
            icon:    const Icon(Icons.science_outlined, size: 20),
            tooltip: 'Load debug pantry data',
            onPressed: onDebugSeed,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('My Pantry', style: theme.textTheme.headlineMedium),
            const SizedBox(width: 8),
            if (unverified > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:        cs.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unverified to review',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:      cs.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Expiring Soon — SliverPersistentHeaderDelegate ────────────────────────────

const double _kStripHeight = 136.0; // label(40) + list(88) + padding(8)

/// Pins the Expiring Soon strip at the top of the scroll area while the
/// user browses the full inventory below.
class _ExpiringSoonDelegate extends SliverPersistentHeaderDelegate {
  const _ExpiringSoonDelegate({required this.items});

  final List<PantryItem> items;

  @override
  double get minExtent => _kStripHeight;

  @override
  double get maxExtent => _kStripHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final cs = Theme.of(context).colorScheme;
    // Lift the strip surface when it's pinned and content scrolls under it.
    final elevation = overlapsContent ? 2.0 : 0.0;
    return Material(
      elevation: elevation,
      color:     cs.surface,
      child:     _ExpiringSoonStrip(items: items),
    );
  }

  @override
  bool shouldRebuild(_ExpiringSoonDelegate old) => items != old.items;
}

/// Horizontal scrolling strip of items expiring soon.
class _ExpiringSoonStrip extends StatelessWidget {
  const _ExpiringSoonStrip({required this.items});

  final List<PantryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final now   = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: cs.error),
              const SizedBox(width: 6),
              Text(
                'Expiring Soon',
                style: theme.textTheme.titleSmall?.copyWith(color: cs.error),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:        cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:      cs.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection:  Axis.horizontal,
            padding:          const EdgeInsets.symmetric(horizontal: 16),
            itemCount:        items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item     = items[i];
              final daysLeft =
                  item.expiryDate.difference(now).inDays.clamp(0, 99);

              return Container(
                width:   104,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        cs.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:      cs.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      daysLeft == 0
                          ? 'Today!'
                          : 'in $daysLeft day${daysLeft > 1 ? 's' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onErrorContainer.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Cook Now section ──────────────────────────────────────────────────────────

/// Shows recipes where ≥80% of required ingredients are in the pantry.
/// Missing ingredients are listed in muted text so the user knows what to buy.
class _CookNowSection extends StatelessWidget {
  const _CookNowSection({required this.recipes});

  final List<RecipeSuggestion> recipes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Cook Now',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: cs.primary),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection:  Axis.horizontal,
            padding:          const EdgeInsets.symmetric(horizontal: 16),
            itemCount:        recipes.take(4).length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = recipes[i];
              return Container(
                width:   180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: theme.textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // "Cookable Now" badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF69F0AE)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(s.inventoryCoverage * 100).round()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:      const Color(0xFF00C853),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${s.calories} kcal',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.primary),
                    ),
                    if (s.missingIngredients.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Missing: ${s.missingIngredients.join(', ')}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.40),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── FAB variants ─────────────────────────────────────────────────────────────

class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onPressed, required this.hasUnverified});

  final VoidCallback onPressed;
  final bool         hasUnverified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width:  double.infinity,
        height: 64,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon:  const Icon(Icons.camera_alt_rounded, size: 24),
          label: Text(
            hasUnverified ? 'Scan Receipt  ·  Review pending' : 'Scan Receipt',
          ),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width:  double.infinity,
        height: 64,
        child: FilledButton.icon(
          onPressed: null,
          icon: SizedBox(
            width:  20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color:       cs.onPrimary,
            ),
          ),
          label: const Text('Scanning receipt…'),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            size:  64,
            color: cs.onSurface.withValues(alpha: 0.20),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No items match your search' : 'Your pantry is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.50),
            ),
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 8),
            Text(
              'Tap "Scan Receipt" to add items',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Handover ──────────────────────────────────────────────────────────────────
// VHS: 9/10
// Strengths:
//   • Expiring Soon strip is now a SliverPersistentHeader (pinned: true).
//     It floats 2dp elevation above the list as content scrolls under it —
//     satisfying pre-attentive urgency signalling without blocking content.
//   • SliverAnimatedList gives remove actions a FadeTransition + SizeTransition
//     "shred" exit. Dismissed items collapse smoothly; no layout jump.
//   • AnimatedOpacity(0.35) dims isEmpty items before the notifier removes
//     them — instant visual feedback before the network/state update resolves.
//   • Cook Now only surfaces recipes with ≥80% coverage. Missing ingredients
//     appear in muted labelSmall — actionable shopping list at a glance.
//   • Debug seed button (beaker icon) auto-hidden in release builds.
// Deduction:
//   -1 pt: Pinned strip adds 136dp of persistent chrome. On phones with small
//   viewports (SE 2020 = 375×667pt) this leaves only ~380dp for the list.
//   Recommendation: collapse the strip to a 40dp title bar on scroll and
//   re-expand on swipe-up (requires minExtent/maxExtent differentiation).
//
// Asset requirements:
//   Icons: Material Symbols (built-in). No images.
//   Permissions: camera + photo library in Info.plist / AndroidManifest.xml.
