import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import 'confidence_badge.dart';

/// ScanConfirmationSheet — full-screen bottom sheet shown after OCR scan.
///
/// High-Motion UX (Rule 7):
/// - Confirmation button is 80dp height minimum for one-thumb kitchen use.
/// - Low-confidence items are visually prominent and have inline text fields.
/// - "Confirm All" and "Add to Pantry" are the only primary actions.
///
/// VHS contribution: The sheet's CTA buttons use the full screen width and
/// 80dp height — the biggest possible touch target for greasy/wet hands.
class ScanConfirmationSheet extends ConsumerStatefulWidget {
  const ScanConfirmationSheet({
    super.key,
    required this.scannedItems,
  });

  final List<PantryItem> scannedItems;

  @override
  ConsumerState<ScanConfirmationSheet> createState() =>
      _ScanConfirmationSheetState();
}

class _ScanConfirmationSheetState
    extends ConsumerState<ScanConfirmationSheet> {
  late List<PantryItem> _items;

  // Inline edit controllers for unverified items
  late final Map<String, TextEditingController> _nameControllers;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.scannedItems);
    _nameControllers = {
      for (final item in _items.where((i) => i.needsVerification))
        item.id: TextEditingController(text: item.name),
    };
  }

  @override
  void dispose() {
    for (final c in _nameControllers.values) c.dispose();
    super.dispose();
  }

  void _confirmAll() {
    // Apply any renamed items
    final confirmed = _items.map((item) {
      final controller = _nameControllers[item.id];
      if (controller != null) {
        return item.copyWith(
          name: controller.text.trim(),
          needsVerification: false,
          confidenceScore: 1.0,
        );
      }
      return item;
    }).toList();

    ref.read(pantryNotifierProvider.notifier).addItemsFromReceipt(confirmed);
    ref.read(receiptScannerProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((i) => i.id == id);
      _nameControllers.remove(id)?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final unverifiedCount = _items.where((i) => i.needsVerification).length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize:     0.60,
      maxChildSize:     0.95,
      builder: (context, scrollController) => Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Scanned Items',
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (unverifiedCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$unverifiedCount item${unverifiedCount > 1 ? 's' : ''} need your review',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFFAB00),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${_items.length} items',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Item list ────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller:  scrollController,
              padding:     const EdgeInsets.symmetric(horizontal: 16),
              itemCount:   _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _ScanItemRow(
                  item:           item,
                  nameController: _nameControllers[item.id],
                  onRemove:       () => _removeItem(item.id),
                );
              },
            ),
          ),

          // ── Sticky CTA area (High-Motion UX — 80dp buttons) ──────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              24, 16, 24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary: Add to Pantry — MINIMUM 80dp (Rule 7 High-Motion UX)
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: FilledButton.icon(
                    onPressed: _items.isEmpty ? null : _confirmAll,
                    icon:  const Icon(Icons.check_rounded, size: 24),
                    label: Text(
                      'Add ${_items.length} Items to Pantry',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary: discard
                SizedBox(
                  width:  double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(receiptScannerProvider.notifier).reset();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Discard Scan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single row in the scan review list.
/// Unverified items show an inline [TextField] for name correction.
class _ScanItemRow extends StatelessWidget {
  const _ScanItemRow({
    required this.item,
    this.nameController,
    this.onRemove,
  });

  final PantryItem           item;
  final TextEditingController? nameController;
  final VoidCallback?        onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.needsVerification
            ? const Color(0xFFFFD740).withValues(alpha: 0.08)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: item.needsVerification
            ? Border.all(color: const Color(0xFFFFD740), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editable name for low-confidence items
                if (nameController != null)
                  TextField(
                    controller: nameController,
                    style: theme.textTheme.titleSmall,
                    decoration: InputDecoration(
                      isDense:     true,
                      filled:      false,
                      border:      InputBorder.none,
                      hintText:    'Enter correct name',
                      prefixIcon:  const Icon(Icons.edit_rounded, size: 16),
                      prefixIconColor: const Color(0xFFFFAB00),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                else
                  Text(item.name, style: theme.textTheme.titleSmall),

                const SizedBox(height: 4),
                Text(
                  '${item.quantity.toInt()} ${item.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConfidenceBadge(score: item.confidenceScore),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            color: cs.onSurface.withValues(alpha: 0.50),
            tooltip: 'Remove item',
          ),
        ],
      ),
    );
  }
}
