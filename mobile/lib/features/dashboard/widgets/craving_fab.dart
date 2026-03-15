import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Floating Action Button that opens the "What am I craving?" bottom sheet.
class CravingFab extends StatelessWidget {
  const CravingFab({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  64,
      height: 64,
      child: FloatingActionButton(
        onPressed:       () => showCravingSheet(context),
        backgroundColor: AppColors.primaryLime,
        foregroundColor: Colors.black,
        elevation:       4,
        shape: const CircleBorder(),
        child: const Icon(Icons.restaurant_menu_rounded, size: 28),
      ),
    );
  }
}

/// Opens the craving bottom sheet modal.
void showCravingSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder: (_) => const _CravingSheet(),
  );
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _CravingSheet extends ConsumerStatefulWidget {
  const _CravingSheet();

  @override
  ConsumerState<_CravingSheet> createState() => _CravingSheetState();
}

class _CravingSheetState extends ConsumerState<_CravingSheet> {
  final _controller = TextEditingController();
  bool          _loading    = false;
  _GeneratedMeal? _meal;
  String?       _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final craving = _controller.text.trim();
    if (craving.isEmpty) return;

    setState(() { _loading = true; _error = null; _meal = null; });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/meals/generate',
        data: {'craving_input': craving},
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _meal    = _GeneratedMeal.fromJson(response.data!);
        });
      }
    } on DioException catch (e) {
      final detail = (e.response?.data as Map?)?['detail'] as String?
          ?? 'Could not generate a recipe. Please try again.';
      if (mounted) setState(() { _loading = false; _error = detail; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Unexpected error. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final cs         = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            "What are you craving?",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "Describe your craving and we'll find a macro-friendly recipe.",
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),

          // ── Text field ────────────────────────────────────────────────────
          TextField(
            controller:      _controller,
            autofocus:       true,
            textInputAction: TextInputAction.done,
            onSubmitted:     (_) => _generate(),
            decoration: InputDecoration(
              hintText: 'e.g. something sweet and chocolatey',
              filled:   true,
              fillColor: cs.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:   BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // ── Generate button ───────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLime,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Text(
                      'Generate Recipe',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),

          // ── Error banner ──────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
          ],

          // ── Result card ───────────────────────────────────────────────────
          if (_meal != null) ...[
            const SizedBox(height: 16),
            _RecipeResultCard(meal: _meal!),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Data model (API response subset) ─────────────────────────────────────────

class _GeneratedMeal {
  final String name;
  final int    totalCalories;
  final int    totalProteinG;
  final int    totalCarbsG;
  final int    totalFatG;
  final String instructions;

  const _GeneratedMeal({
    required this.name,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.instructions,
  });

  factory _GeneratedMeal.fromJson(Map<String, dynamic> json) => _GeneratedMeal(
    name:          json['name'] as String,
    totalCalories: json['total_calories'] as int,
    totalProteinG: json['total_protein_g'] as int,
    totalCarbsG:   json['total_carbs_g'] as int,
    totalFatG:     json['total_fat_g'] as int,
    instructions:  json['instructions'] as String,
  );
}

// ── Recipe result card ────────────────────────────────────────────────────────

class _RecipeResultCard extends StatelessWidget {
  const _RecipeResultCard({required this.meal});

  final _GeneratedMeal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        cs.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryLime.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        AppColors.primaryLime.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AI Pick',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:      AppColors.primaryLime,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meal.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            meal.instructions,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MacroBadge('${meal.totalCalories} kcal', cs.onSurface),
              const SizedBox(width: 8),
              _MacroBadge('${meal.totalProteinG}g protein', AppColors.success),
              const SizedBox(width: 8),
              _MacroBadge('${meal.totalFatG}g fat', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  const _MacroBadge(this.label, this.color);
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color:      color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
