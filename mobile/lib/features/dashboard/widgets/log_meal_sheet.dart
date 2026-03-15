import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/dashboard_provider.dart';

/// Opens the "What did you eat?" bottom sheet modal.
void showLogMealSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder: (_) => const _LogMealSheet(),
  );
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _LogMealSheet extends ConsumerStatefulWidget {
  const _LogMealSheet();

  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet> {
  final _controller = TextEditingController();
  bool          _loading = false;
  _ParsedMeal?  _result;
  String?       _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() { _loading = true; _error = null; _result = null; });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/meals/log-text',
        data: {'text': text},
      );
      if (mounted) {
        setState(() {
          _loading = true;
          _result  = _ParsedMeal.fromJson(response.data!);
        });
        ref.invalidate(macroSummaryProvider);
        if (mounted) setState(() => _loading = false);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data as Map?)?['detail'] as String?
          ?? AppLocalizations.of(context).couldNotLogMeal;
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
      margin:  const EdgeInsets.only(top: 60),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize:        MainAxisSize.min,
        crossAxisAlignment:  CrossAxisAlignment.stretch,
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
            AppLocalizations.of(context).logMealTitle,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).logMealSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),

          // ── Text field ────────────────────────────────────────────────────
          TextField(
            controller:      _controller,
            autofocus:       true,
            textInputAction: TextInputAction.done,
            onSubmitted:     (_) => _submit(),
            enabled:         !_loading && _result == null,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:  AppLocalizations.of(context).logMealHint,
              filled:    true,
              fillColor: cs.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:   BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // ── Action button ─────────────────────────────────────────────────
          if (_result == null)
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:       Colors.black,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).logMealButton,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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

          // ── Success card ──────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 16),
            _LoggedMealCard(meal: _result!),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLime,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(AppLocalizations.of(context).done, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Parsed meal data (API response subset) ────────────────────────────────────

class _ParsedMeal {
  final String name;
  final int    calories;
  final int    proteinG;
  final int    carbsG;
  final int    fatG;

  const _ParsedMeal({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory _ParsedMeal.fromJson(Map<String, dynamic> json) => _ParsedMeal(
    name:     json['name'] as String,
    calories: json['total_calories'] as int,
    proteinG: json['total_protein_g'] as int,
    carbsG:   json['total_carbs_g'] as int,
    fatG:     json['total_fat_g'] as int,
  );
}

// ── Success card ──────────────────────────────────────────────────────────────

class _LoggedMealCard extends StatelessWidget {
  const _LoggedMealCard({required this.meal});
  final _ParsedMeal meal;

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
          color: AppColors.primaryLime.withValues(alpha: 0.35),
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
                  color:        AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppLocalizations.of(context).mealLogged,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:      AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meal.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MacroBadge('${meal.calories} kcal', cs.onSurface),
              const SizedBox(width: 10),
              _MacroBadge('${meal.proteinG}g P', AppColors.success),
              const SizedBox(width: 10),
              _MacroBadge('${meal.carbsG}g C', AppColors.warning),
              const SizedBox(width: 10),
              _MacroBadge('${meal.fatG}g F', AppColors.error),
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
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color:      color,
      fontWeight: FontWeight.w600,
    ),
  );
}
