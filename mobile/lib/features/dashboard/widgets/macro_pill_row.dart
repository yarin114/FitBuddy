import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/macro_summary.dart';

/// Three macro pills in a Row: Protein · Carbs · Fat.
///
/// Each pill shows the macro name, consumed/goal, and a thin
/// [LinearProgressIndicator] coloured by macro type.
class MacroPillRow extends StatelessWidget {
  const MacroPillRow({super.key, required this.summary});

  final MacroSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroPill(
            label:    'Protein',
            consumed: summary.proteinConsumedG,
            goal:     summary.proteinGoalG,
            progress: summary.proteinProgress,
            color:    AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroPill(
            label:    'Carbs',
            consumed: summary.carbsConsumedG,
            goal:     summary.carbsGoalG,
            progress: summary.carbsProgress,
            color:    AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroPill(
            label:    'Fat',
            consumed: summary.fatConsumedG,
            goal:     summary.fatGoalG,
            progress: summary.fatProgress,
            color:    AppColors.error,
          ),
        ),
      ],
    );
  }
}

// ── Single macro pill ─────────────────────────────────────────────────────────

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.progress,
    required this.color,
  });

  final String label;
  final double consumed;
  final double goal;
  final double progress;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${consumed.round()}g',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color:      cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:            progress,
              minHeight:        4,
              backgroundColor:  cs.surfaceContainerHighest,
              valueColor:       AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ${goal.round()}g',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
