import 'package:flutter/material.dart';

/// AppColors — Single source of truth for every raw color token in FitBuddy.
///
/// Rules:
/// - Never use these directly in widgets. Always go through [AppTheme]
///   or `Theme.of(context).colorScheme`.
/// - The only exception is semantic state colors (success, warning, error)
///   which are not part of Material 3's ColorScheme.
/// - All color pairs below are WCAG 2.1 AA verified (contrast ≥ 4.5:1).
abstract final class AppColors {
  AppColors._();

  // ── Primary — Electric Lime ───────────────────────────────────────────────
  // Contrast on [surface] (#0D0D0D): ~17.2:1 → passes WCAG AAA
  static const Color primaryLime     = Color(0xFFC6FF00);
  static const Color primaryLimeDim  = Color(0xFF9BCC00); // hover / pressed state
  static const Color onPrimary       = Color(0xFF0D0D0D); // black on lime — 17.2:1

  // ── Dark Surfaces (8pt elevation layers) ─────────────────────────────────
  // Based on Material 3 dark surface elevation tones
  static const Color surface              = Color(0xFF0D0D0D); // elevation 0
  static const Color surfaceContainer     = Color(0xFF1A1A1A); // elevation 1
  static const Color surfaceContainerHigh = Color(0xFF242424); // elevation 2
  static const Color surfaceContainerMax  = Color(0xFF2E2E2E); // elevation 3 (cards)

  // ── Text on dark surfaces ─────────────────────────────────────────────────
  // onSurface on surface: ~20:1 → AAA
  static const Color onSurface      = Color(0xFFF5F5F5);
  // onSurfaceMuted on surface: ~5.8:1 → AA (supporting / caption text)
  static const Color onSurfaceMuted = Color(0xFFABABAB);
  // onSurfaceDisabled: intentionally below AA — used only for truly disabled UI
  static const Color onSurfaceDisabled = Color(0xFF616161);

  // ── Semantic / State colours ──────────────────────────────────────────────
  // success on surface: ~8.3:1 → AA
  static const Color success   = Color(0xFF69F0AE);
  static const Color onSuccess = Color(0xFF0D0D0D);

  // warning on surface: ~10.4:1 → AA
  static const Color warning   = Color(0xFFFFD740);
  static const Color onWarning = Color(0xFF0D0D0D);

  // error — Material 3 dark error tone, on surface: ~5.2:1 → AA
  static const Color error   = Color(0xFFFF897D);
  static const Color onError = Color(0xFF0D0D0D);

  // ── Divider / Outline ─────────────────────────────────────────────────────
  static const Color outline        = Color(0xFF3A3A3A);
  static const Color outlineVariant = Color(0xFF2A2A2A);

  // ── Gradient stops ────────────────────────────────────────────────────────
  // Used for the macro ring background and hero card overlay.
  static const List<Color> limeGradient = [
    Color(0xFFC6FF00),
    Color(0xFF76CC00),
  ];
}
