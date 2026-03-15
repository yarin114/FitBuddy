import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/macro_summary.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/craving_fab.dart';
import '../widgets/log_meal_sheet.dart';
import '../widgets/macro_pill_row.dart';
import '../widgets/meal_list_tile.dart';

/// Tab 0 of [DashboardScreen] — the macro summary + meal log view.
///
/// Owns the [AnimationController] (1.4 s, easeOutCubic) that drives the
/// [CalorieRing] entrance animation. Passes a curved [Animation<double>]
/// down to [CalorieRing] so that widget stays stateless.
class MacroTab extends ConsumerStatefulWidget {
  const MacroTab({super.key});

  @override
  ConsumerState<MacroTab> createState() => _MacroTabState();
}

class _MacroTabState extends ConsumerState<MacroTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _ringAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSummary = ref.watch(macroSummaryProvider);
    final theme        = Theme.of(context);
    final cs           = theme.colorScheme;

    // While loading or on error, show a centered indicator/message.
    // The mock fallback in the provider means errors are rare in practice.
    return asyncSummary.when(
      loading: () => Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Text(
            AppLocalizations.of(context).couldNotLoadMacros,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
      data: (summary) => _buildContent(context, theme, cs, summary),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    MacroSummary summary,
  ) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned:          true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              AppLocalizations.of(context).today,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon:    const Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Calorie ring ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Center(
                child: CalorieRing(
                  summary:   summary,
                  animation: _ringAnim,
                ),
              ),
            ),
          ),

          // ── Macro pills ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MacroPillRow(summary: summary),
            ),
          ),

          // ── Section header: Today's meals ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).todaysMeals,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => showLogMealSheet(context),
                    child: Text(AppLocalizations.of(context).addMeal),
                  ),
                ],
              ),
            ),
          ),

          // ── Meal list ─────────────────────────────────────────────────────
          if (summary.todayMeals.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).noMealsToday,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList.separated(
              itemCount:    summary.todayMeals.length,
              separatorBuilder: (_, __) => const Divider(
                indent: 16, endIndent: 16, height: 1,
              ),
              itemBuilder: (context, i) =>
                  MealListTile(meal: summary.todayMeals[i]),
            ),

          // ── Bottom padding for FAB ────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize:       MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Secondary: craving / AI recipe generation
          FloatingActionButton.small(
            heroTag:         'fab_craving',
            onPressed:       () => showCravingSheet(context),
            backgroundColor: AppColors.primaryLime.withValues(alpha: 0.85),
            foregroundColor: Colors.black,
            elevation:       2,
            child: const Icon(Icons.restaurant_menu_rounded, size: 20),
          ),
          const SizedBox(height: 12),
          // Primary: log a meal you already ate
          SizedBox(
            width: 64, height: 64,
            child: FloatingActionButton(
              heroTag:         'fab_log_meal',
              onPressed:       () => showLogMealSheet(context),
              backgroundColor: AppColors.primaryLime,
              foregroundColor: Colors.black,
              elevation:       4,
              shape:           const CircleBorder(),
              child:           const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
