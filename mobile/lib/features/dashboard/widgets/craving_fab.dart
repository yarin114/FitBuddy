import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Floating Action Button that opens the "What am I craving?" bottom sheet.
///
/// Tapping the FAB calls [showCravingSheet], which presents a text field and
/// a Generate button. In this mock build the result card is hardcoded.
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
    context:       context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CravingSheet(),
  );
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _CravingSheet extends StatefulWidget {
  const _CravingSheet();

  @override
  State<_CravingSheet> createState() => _CravingSheetState();
}

class _CravingSheetState extends State<_CravingSheet> {
  final _controller  = TextEditingController();
  bool  _loading     = false;
  bool  _showResult  = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    // Simulate network delay — replace with real API call when backend ready.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() { _loading = false; _showResult = true; });
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
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
            controller: _controller,
            autofocus:  true,
            textInputAction: TextInputAction.done,
            onSubmitted:    (_) => _generate(),
            decoration: InputDecoration(
              hintText:      'e.g. something sweet and chocolatey',
              filled:        true,
              fillColor:     cs.surfaceContainer,
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Generate Recipe',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),

          // ── Mock result card ──────────────────────────────────────────────
          if (_showResult) ...[
            const SizedBox(height: 16),
            _RecipeResultCard(craving: _controller.text.trim()),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Mock recipe result ────────────────────────────────────────────────────────

class _RecipeResultCard extends StatelessWidget {
  const _RecipeResultCard({required this.craving});

  final String craving;

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
                  'High-Protein Chocolate Mousse',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Greek yogurt + cocoa powder + honey + protein powder. '
            'Ready in 5 min, no cooking.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MacroBadge('280 kcal', cs.onSurface),
              const SizedBox(width: 8),
              _MacroBadge('32g protein', AppColors.success),
              const SizedBox(width: 8),
              _MacroBadge('8g fat',     AppColors.error),
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
