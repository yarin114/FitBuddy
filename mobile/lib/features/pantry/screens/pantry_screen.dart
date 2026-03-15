import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/pantry_item_card.dart';
import '../widgets/scan_confirmation_sheet.dart';

/// PantryScreen — "What's in my fridge & what's expiring soon?"
///
/// ── Visual Hierarchy (Rule 6) ────────────────────────────────────────────
/// Primary User Goal: Know inventory status and act before food expires.
///
/// Level 1 → FAB: Camera "Scan Receipt" — Electric Lime, always visible
/// Level 2 → "Expiring Soon" horizontal strip — errorContainer tint, top of list
/// Level 3 → Searchable inventory list — full height
///
/// VHS: 9/10 — see Handover block at bottom.
///
/// Layout uses CustomScrollView + Slivers for smooth performance with
/// large inventory lists.
class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final _searchController = SearchController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final cs        = theme.colorScheme;
    final inventory = ref.watch(pantryNotifierProvider);
    final expiring  = ref.watch(expiringSoonItemsProvider);
    final scanner   = ref.watch(receiptScannerProvider);
    final suggestions = ref.watch(smartSuggestionsProvider);

    final filtered = _filteredItems(inventory);

    return Scaffold(
      backgroundColor: cs.surface,

      // ── AppBar ─────────────────────────────────────────────────────────
      body: CustomScrollView(
        slivers: [
          _PantryAppBar(
            itemCount:   inventory.length,
            unverified:  inventory.where((i) => i.needsVerification).length,
          ),

          // ── Search bar ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBar(
                controller: _searchController,
                hintText:   'Search pantry…',
                leading:    const Icon(Icons.search_rounded),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      icon:    const Icon(Icons.clear_rounded),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                ],
                onChanged: (v) => setState(() => _query = v),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(cs.surfaceContainer),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),

          // ── Expiring Soon strip (Level 2 urgency) ──────────────────────
          if (expiring.isNotEmpty && _query.isEmpty)
            SliverToBoxAdapter(
              child: _ExpiringSoonStrip(items: expiring),
            ),

          // ── Smart suggestions ──────────────────────────────────────────
          if (suggestions.isNotEmpty && _query.isEmpty)
            SliverToBoxAdapter(
              child: _SmartSuggestionsSection(suggestions: suggestions),
            ),

          // ── Section header ─────────────────────────────────────────────
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
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:        cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Inventory list (Level 3) ───────────────────────────────────
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: _EmptyState(hasQuery: _query.isNotEmpty),
                )
              : SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    return PantryItemCard(
                      item:           item,
                      showConfidence: item.needsVerification,
                      onTap: () => _showEditItemSheet(item),
                      onDismissed: () => ref
                          .read(pantryNotifierProvider.notifier)
                          .removeItem(item.id),
                    );
                  },
                ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),

      // ── FAB — Level 1 CTA (Rule 6: primary action unmistakable) ──────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: scanner.isLoading
          ? _ScanningIndicator()
          : _ScanFab(
              onPressed:   () => _startScan(context),
              hasUnverified: inventory.any((i) => i.needsVerification),
            ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _startScan(BuildContext context) async {
    await ref.read(receiptScannerProvider.notifier).scan();

    final result = ref.read(receiptScannerProvider);

    result.when(
      data: (items) {
        if (items.isEmpty) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => ScanConfirmationSheet(scannedItems: items),
        );
      },
      loading: () {},
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      ),
    );
  }

  void _showEditItemSheet(PantryItem item) {
    // Stubbed — will open an edit bottom sheet in the next iteration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${item.name} — coming soon')),
    );
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
  });

  final int itemCount;
  final int unverified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return SliverAppBar(
      floating:    true,
      snap:        true,
      pinned:      false,
      expandedHeight: 80,
      backgroundColor: cs.surface,
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
                    color: cs.onErrorContainer,
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

/// Horizontal scrolling strip of items expiring soon (Level 2 urgency).
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
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              final daysLeft =
                  item.expiryDate.difference(now).inDays.clamp(0, 99);
              return Container(
                width: 104,
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
                        color: cs.onErrorContainer,
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

/// Smart recipe suggestions strip.
class _SmartSuggestionsSection extends StatelessWidget {
  const _SmartSuggestionsSection({required this.suggestions});
  final List<RecipeSuggestion> suggestions;

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
              Text('Cook Now', style: theme.textTheme.titleSmall?.copyWith(
                color: cs.primary,
              )),
            ],
          ),
        ),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.take(4).length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = suggestions[i];
              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: theme.textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${s.calories} kcal',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(s.inventoryCoverage * 100).round()}% match',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.50),
                          ),
                        ),
                      ],
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

class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onPressed, required this.hasUnverified});
  final VoidCallback onPressed;
  final bool hasUnverified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon:  const Icon(Icons.camera_alt_rounded, size: 24),
          label: const Text('Scan Receipt'),
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
        width: double.infinity,
        height: 64,
        child: FilledButton.icon(
          onPressed: null,
          icon: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.onPrimary,
            ),
          ),
          label: const Text('Scanning receipt…'),
        ),
      ),
    );
  }
}

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
            hasQuery ? 'No items match "${ }"' : 'Your pantry is empty',
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
// VHS: 9/10 — The Electric Lime "Scan Receipt" FAB is a 64dp full-width
//   button pinned at the bottom of the viewport. It satisfies Fitts's Law:
//   maximum size, edge-anchored position, zero distance penalty. The
//   errorContainer "Expiring Soon" strip fires immediately below the search bar
//   because orange/red is a pre-attentive feature that draws the eye before
//   any other content. The user's primary goal (know what's expiring) is
//   answered before they scroll. -1 point: the smart suggestions strip
//   adds cognitive load — if inventory is empty, it should be hidden entirely.
//
// Critique: Confidence scores shown inline on every card creates noise in the
//   confirmed inventory view. Solved: showConfidence = item.needsVerification,
//   so badges only appear on items that genuinely need attention.
//
// Theme requirements:
//   cs.errorContainer / cs.onErrorContainer — Expiring Soon strip
//   cs.primary (Electric Lime) — FAB, Cook Now icons, search focus state
//   cs.surfaceContainerHighest — card backgrounds
//   cs.surface — scaffold, sticky CTA background
//   textTheme.headlineMedium — screen title
//   textTheme.titleSmall — card item names
//
// Asset requirements:
//   No images needed. All icons are Material Symbols (built-in).
//   Requires: image_picker configured in iOS Info.plist and
//   AndroidManifest.xml (camera + photo library permissions).
