import 'package:flutter/material.dart';

/// ConfidenceBadge — displays a colour-coded OCR confidence score.
///
/// Colour tiers (Rule 7 + WCAG 2.1 AA):
///   ≥ 0.85 → success green  — "High confidence"
///   0.70–0.85 → warning amber — "Review recommended"
///   < 0.70  → error red     — "Needs verification" (A11y: icon + colour)
///
/// Accessibility: never uses colour alone. Each tier also has a distinct
/// icon so colour-blind users can distinguish confidence levels.
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.score,
    this.showLabel = true,
  });

  final double score;

  /// Show the percentage label alongside the icon. Set false in dense lists.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final tier = _tier(score);
    final cs   = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        tier.bgColor(cs),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tier.icon, size: 12, color: tier.fgColor(cs)),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              '${(score * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:      tier.fgColor(cs),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  _ConfidenceTier _tier(double score) {
    if (score >= 0.85) return _ConfidenceTier.high;
    if (score >= 0.70) return _ConfidenceTier.medium;
    return _ConfidenceTier.low;
  }
}

enum _ConfidenceTier { high, medium, low }

extension _ConfidenceTierStyle on _ConfidenceTier {
  IconData get icon => switch (this) {
        _ConfidenceTier.high   => Icons.check_circle_rounded,
        _ConfidenceTier.medium => Icons.info_rounded,
        _ConfidenceTier.low    => Icons.warning_rounded,
      };

  Color bgColor(ColorScheme cs) => switch (this) {
        _ConfidenceTier.high   => const Color(0xFF69F0AE).withValues(alpha: 0.16),
        _ConfidenceTier.medium => const Color(0xFFFFD740).withValues(alpha: 0.16),
        _ConfidenceTier.low    => cs.errorContainer,
      };

  Color fgColor(ColorScheme cs) => switch (this) {
        _ConfidenceTier.high   => const Color(0xFF00C853),
        _ConfidenceTier.medium => const Color(0xFFFFAB00),
        _ConfidenceTier.low    => cs.onErrorContainer,
      };
}
