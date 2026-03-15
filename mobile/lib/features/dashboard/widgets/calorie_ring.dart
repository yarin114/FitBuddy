import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/macro_summary.dart';

/// Animated calorie ring — the hero widget on the Dashboard.
///
/// Renders a single 220dp ring that sweeps from 0 → [summary.caloriesProgress]
/// over 1.4 s with an easeOutCubic curve. The center shows kcal remaining.
///
/// Pass [animation] from the parent's AnimationController so this widget
/// stays stateless and the parent manages the lifecycle.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.summary,
    required this.animation,
  });

  final MacroSummary     summary;
  final Animation<double> animation;

  static const double _size        = 220;
  static const double _strokeWidth = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final animatedProgress = summary.caloriesProgress * animation.value;

        return SizedBox(
          width:  _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Ring ───────────────────────────────────────────────────────
              CustomPaint(
                size: const Size(_size, _size),
                painter: _RingPainter(
                  progress:      animatedProgress,
                  trackColor:    cs.surfaceContainerHighest,
                  progressColor: AppColors.primaryLime,
                  strokeWidth:   _strokeWidth,
                ),
              ),

              // ── Center text ────────────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${summary.caloriesRemaining}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color:      AppColors.primaryLime,
                      fontWeight: FontWeight.w800,
                      height:     1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'kcal left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summary.caloriesConsumed} / ${summary.caloriesGoal}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceDisabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Ring CustomPainter ────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color  trackColor;
  final Color  progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color       = trackColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc (starts at 12 o'clock, sweeps clockwise)
    if (progress > 0.005) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color       = progressColor
          ..style       = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
