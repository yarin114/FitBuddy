import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pantry_item.dart';
import 'confidence_badge.dart';

/// PantryItemCard — a single row in the inventory list.
///
/// Visual states:
///   Normal         — standard card with category icon
///   NeedsVerification — amber left border + info icon (A11y: not colour-only)
///   Expiring soon  — error tint on quantity text
///   Empty          — 50% opacity, struck-through quantity
///
/// Interaction:
///   Tap            → [onTap] (open edit sheet)
///   Swipe-left     → [onDismissed] (remove from inventory)
///   Long-press     → (reserved for multi-select)
class PantryItemCard extends StatelessWidget {
  const PantryItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDismissed,
    this.showConfidence = true,
  });

  final PantryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  /// Show confidence badge — false in confirmed inventory, true in scan review.
  final bool showConfidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(),
      onDismissed: (_) => onDismissed?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            // Amber left accent border for items needing verification (A11y)
            border: item.needsVerification
                ? Border(
                    left: BorderSide(
                      color: const Color(0xFFFFD740),
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Category icon ──────────────────────────────────────────
                _CategoryIcon(category: item.category),
                const SizedBox(width: 12),

                // ── Name + meta ────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: item.isEmpty
                              ? cs.onSurface.withValues(alpha: 0.38)
                              : cs.onSurface,
                          decoration: item.isEmpty
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: item.isExpiringSoon
                                  ? cs.error
                                  : cs.onSurface.withValues(alpha: 0.60),
                              fontWeight: item.isExpiringSoon
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Exp ${DateFormat('d MMM').format(item.expiryDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: item.isExpiringSoon
                                  ? cs.error
                                  : cs.onSurface.withValues(alpha: 0.40),
                            ),
                          ),
                          if (item.needsVerification) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: const Color(0xFFFFAB00),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Confidence badge ───────────────────────────────────────
                if (showConfidence)
                  ConfidenceBadge(score: item.confidenceScore),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});
  final PantryCategory category;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_icon, size: 20, color: cs.primary),
    );
  }

  IconData get _icon => switch (category) {
        PantryCategory.meat      => Icons.set_meal_rounded,
        PantryCategory.dairy     => Icons.egg_rounded,
        PantryCategory.vegetable => Icons.eco_rounded,
        PantryCategory.fruit     => Icons.apple_rounded,
        PantryCategory.grain     => Icons.grain_rounded,
        PantryCategory.beverage  => Icons.local_drink_rounded,
        PantryCategory.other     => Icons.inventory_2_rounded,
      };
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        Icons.delete_rounded,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}
