import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/macro_summary.dart';

/// A single row in the "Today's Meals" list.
///
/// Layout: [time badge 48×48] | [meal name + macros subtitle] | [kcal]
class MealListTile extends StatelessWidget {
  const MealListTile({super.key, required this.meal});

  final LoggedMeal meal;

  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // ── Time badge ─────────────────────────────────────────────────────
          Container(
            width:  52,
            height: 52,
            decoration: BoxDecoration(
              color:        cs.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _timeFmt.format(meal.loggedAt),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color:      AppColors.onSurfaceMuted,
                height:     1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Name + macros ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'P ${meal.proteinG.round()}g · '
                  'C ${meal.carbsG.round()}g · '
                  'F ${meal.fatG.round()}g',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Calories ───────────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${meal.calories}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      cs.onSurface,
                ),
              ),
              Text(
                'kcal',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
