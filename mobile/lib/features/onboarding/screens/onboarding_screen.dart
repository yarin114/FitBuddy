import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _totalSteps = 6;

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // ── Form state ──────────────────────────────────────────────────────────────
  String _language       = 'en';   // step 0 — language must come first
  String _gender         = '';
  int    _age            = 25;
  double _weightKg       = 70;
  double _heightCm       = 170;
  String _activityLevel  = '';
  String _goal           = '';

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Initialise _language from the currently active locale.
    _language = ref.read(localeNotifierProvider).languageCode;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  String? _validateCurrent(AppLocalizations l10n) {
    switch (_page) {
      case 0: return null;   // language always valid (has a default)
      case 1: return _gender.isEmpty              ? l10n.validationGender        : null;
      case 2: return (_age < 13 || _age > 100)   ? l10n.validationAge           : null;
      case 3: return (_weightKg <= 0 || _heightCm <= 0) ? l10n.validationMeasurements : null;
      case 4: return _activityLevel.isEmpty       ? l10n.validationActivity      : null;
      case 5: return _goal.isEmpty                ? l10n.validationGoal          : null;
      default: return null;
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _next(AppLocalizations l10n) {
    final error = _validateCurrent(l10n);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_page < _totalSteps - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  // ── Language change ──────────────────────────────────────────────────────────

  Future<void> _onLanguageChanged(String code) async {
    setState(() => _language = code);
    await ref.read(localeNotifierProvider.notifier).setLocale(Locale(code));
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final dio = ref.read(apiClientProvider);
      await dio.put<void>(
        '/api/v1/users/profile',
        data: {
          'gender':             _gender,
          'age':                _age,
          'weight_kg':          _weightKg,
          'height_cm':          _heightCm,
          'activity_level':     _activityLevel,
          'goal':               _goal,
          'preferred_language': _language,
        },
      );
      // Invalidate profile cache → AuthGate re-fetches → routes to Dashboard.
      ref.invalidate(userProfileProvider);
    } on DioException catch (e) {
      final detail = (e.response?.data as Map?)?['detail'] as String?
          ?? AppLocalizations.of(context).unexpectedError;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(page: _page, total: _totalSteps, l10n: l10n),

            Expanded(
              child: PageView(
                controller:    _pageCtrl,
                physics:       const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  // Step 0: Language
                  _LanguagePage(
                    selected:  _language,
                    onChanged: _onLanguageChanged,
                    l10n:      l10n,
                  ),
                  // Step 1: Gender
                  _GenderPage(
                    selected:  _gender,
                    onChanged: (v) => setState(() => _gender = v),
                    l10n:      l10n,
                  ),
                  // Step 2: Age
                  _AgePage(
                    age:       _age,
                    onChanged: (v) => setState(() => _age = v),
                    l10n:      l10n,
                  ),
                  // Step 3: Body stats
                  _BodyStatsPage(
                    weightKg:        _weightKg,
                    heightCm:        _heightCm,
                    onWeightChanged: (v) => setState(() => _weightKg = v),
                    onHeightChanged: (v) => setState(() => _heightCm = v),
                    l10n:            l10n,
                  ),
                  // Step 4: Activity
                  _ActivityPage(
                    selected:  _activityLevel,
                    onChanged: (v) => setState(() => _activityLevel = v),
                    l10n:      l10n,
                  ),
                  // Step 5: Goal
                  _GoalPage(
                    selected:  _goal,
                    onChanged: (v) => setState(() => _goal = v),
                    l10n:      l10n,
                  ),
                ],
              ),
            ),

            _BottomNav(
              page:       _page,
              total:      _totalSteps,
              submitting: _submitting,
              onBack:     _back,
              onNext:     () => _next(l10n),
              l10n:       l10n,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress header ───────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.page, required this.total, required this.l10n});
  final int             page;
  final int             total;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final progress = (page + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.onboardingStepOf(page + 1, total),
                style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceMuted),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryLime, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           progress,
              minHeight:       6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor:      AlwaysStoppedAnimation<Color>(AppColors.primaryLime),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.page,
    required this.total,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.l10n,
  });
  final int             page;
  final int             total;
  final bool            submitting;
  final VoidCallback    onBack;
  final VoidCallback    onNext;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isLast = page == total - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          if (page > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: submitting ? null : onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: AppColors.onSurfaceMuted.withValues(alpha: 0.4)),
                ),
                child: Text(l10n.back),
              ),
            ),
          if (page > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: submitting ? null : onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLime,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                  : Text(
                      isLast ? l10n.startJourney : l10n.next,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 0: Language ──────────────────────────────────────────────────────────

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.selected, required this.onChanged, required this.l10n});
  final String                    selected;
  final ValueChanged<String>      onChanged;
  final AppLocalizations          l10n;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title:    l10n.languageTitle,
      subtitle: l10n.languageSubtitle,
      child: Column(
        children: [
          _LanguageCard('en', l10n.languageEnglish, '🇺🇸', selected, onChanged),
          const SizedBox(height: 12),
          _LanguageCard('he', l10n.languageHebrew,  '🇮🇱', selected, onChanged),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard(this.code, this.label, this.flag, this.selected, this.onChanged);
  final String              code;
  final String              label;
  final String              flag;
  final String              selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final isActive = selected == code;
    return GestureDetector(
      onTap: () => onChanged(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color:        isActive ? AppColors.primaryLime.withValues(alpha: 0.12) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primaryLime : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (isActive) Icon(Icons.check_circle_rounded, color: AppColors.primaryLime),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Gender ────────────────────────────────────────────────────────────

class _GenderPage extends StatelessWidget {
  const _GenderPage({required this.selected, required this.onChanged, required this.l10n});
  final String              selected;
  final ValueChanged<String> onChanged;
  final AppLocalizations    l10n;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title:    l10n.genderTitle,
      subtitle: l10n.genderSubtitle,
      child: Column(
        children: [
          _GenderCard('male',   l10n.genderMale,   '👨', selected, onChanged),
          const SizedBox(height: 12),
          _GenderCard('female', l10n.genderFemale, '👩', selected, onChanged),
          const SizedBox(height: 12),
          _GenderCard('other',  l10n.genderOther,  '🧑', selected, onChanged),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard(this.value, this.label, this.emoji, this.selected, this.onChanged);
  final String              value;
  final String              label;
  final String              emoji;
  final String              selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final isActive = selected == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color:        isActive ? AppColors.primaryLime.withValues(alpha: 0.12) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? AppColors.primaryLime : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (isActive) Icon(Icons.check_circle_rounded, color: AppColors.primaryLime),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Age ───────────────────────────────────────────────────────────────

class _AgePage extends StatefulWidget {
  const _AgePage({required this.age, required this.onChanged, required this.l10n});
  final int                age;
  final ValueChanged<int>  onChanged;
  final AppLocalizations   l10n;

  @override
  State<_AgePage> createState() => _AgePageState();
}

class _AgePageState extends State<_AgePage> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.age.toString());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PageScaffold(
      title:    widget.l10n.ageTitle,
      subtitle: widget.l10n.ageSubtitle,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(Icons.remove_rounded, () {
                final v = (widget.age - 1).clamp(13, 100);
                _ctrl.text = v.toString();
                widget.onChanged(v);
              }),
              const SizedBox(width: 24),
              SizedBox(
                width: 100,
                child: TextField(
                  controller:   _ctrl,
                  textAlign:    TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLime,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) widget.onChanged(parsed.clamp(13, 100));
                  },
                ),
              ),
              const SizedBox(width: 24),
              _StepButton(Icons.add_rounded, () {
                final v = (widget.age + 1).clamp(13, 100);
                _ctrl.text = v.toString();
                widget.onChanged(v);
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.l10n.yearsOld, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton(this.icon, this.onTap);
  final IconData     icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: cs.surfaceContainer, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primaryLime),
      ),
    );
  }
}

// ── Step 3: Body stats ────────────────────────────────────────────────────────

class _BodyStatsPage extends StatefulWidget {
  const _BodyStatsPage({
    required this.weightKg,
    required this.heightCm,
    required this.onWeightChanged,
    required this.onHeightChanged,
    required this.l10n,
  });
  final double               weightKg;
  final double               heightCm;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onHeightChanged;
  final AppLocalizations     l10n;

  @override
  State<_BodyStatsPage> createState() => _BodyStatsPageState();
}

class _BodyStatsPageState extends State<_BodyStatsPage> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.weightKg.toStringAsFixed(1));
    _heightCtrl = TextEditingController(text: widget.heightCm.toStringAsFixed(1));
  }

  @override
  void dispose() { _weightCtrl.dispose(); _heightCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title:    widget.l10n.bodyStatsTitle,
      subtitle: widget.l10n.bodyStatsSubtitle,
      child: Column(
        children: [
          _MeasurementField(
            controller: _weightCtrl,
            label:      widget.l10n.bodyWeightLabel,
            unit:       'kg',
            onChanged:  (v) { if (v != null) widget.onWeightChanged(v); },
          ),
          const SizedBox(height: 16),
          _MeasurementField(
            controller: _heightCtrl,
            label:      widget.l10n.heightLabel,
            unit:       'cm',
            onChanged:  (v) { if (v != null) widget.onHeightChanged(v); },
          ),
        ],
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String                label;
  final String                unit;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller:      controller,
      keyboardType:    const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
      decoration: InputDecoration(
        labelText:  label,
        suffixText: unit,
        filled:     true,
        fillColor:  cs.surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryLime, width: 2),
        ),
      ),
      onChanged: (v) => onChanged(double.tryParse(v)),
    );
  }
}

// ── Step 4: Activity level ────────────────────────────────────────────────────

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({required this.selected, required this.onChanged, required this.l10n});
  final String              selected;
  final ValueChanged<String> onChanged;
  final AppLocalizations    l10n;

  @override
  Widget build(BuildContext context) {
    final options = [
      _ActivityOption('sedentary',   l10n.activitySedentary,   l10n.activitySedentaryDesc,   Icons.weekend_outlined),
      _ActivityOption('light',       l10n.activityLight,       l10n.activityLightDesc,       Icons.directions_walk_outlined),
      _ActivityOption('moderate',    l10n.activityModerate,    l10n.activityModerateDesc,    Icons.directions_bike_outlined),
      _ActivityOption('active',      l10n.activityActive,      l10n.activityActiveDesc,      Icons.fitness_center_outlined),
      _ActivityOption('very_active', l10n.activityVeryActive,  l10n.activityVeryActiveDesc,  Icons.bolt_outlined),
    ];

    return _PageScaffold(
      title:    l10n.activityTitle,
      subtitle: l10n.activitySubtitle,
      child: Column(
        children: options.map((opt) {
          final isActive = selected == opt.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryLime.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isActive ? AppColors.primaryLime : Colors.transparent, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(opt.icon, color: isActive ? AppColors.primaryLime : AppColors.onSurfaceMuted, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(opt.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted)),
                        ],
                      ),
                    ),
                    if (isActive) Icon(Icons.check_circle_rounded, color: AppColors.primaryLime, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Step 5: Goal ──────────────────────────────────────────────────────────────

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.selected, required this.onChanged, required this.l10n});
  final String              selected;
  final ValueChanged<String> onChanged;
  final AppLocalizations    l10n;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title:    l10n.goalTitle,
      subtitle: l10n.goalSubtitle,
      child: Column(
        children: [
          _GoalCard('lose_weight', l10n.goalLose,     '🔥', l10n.goalLoseSubtitle,     selected, onChanged),
          const SizedBox(height: 12),
          _GoalCard('maintain',    l10n.goalMaintain, '🎯', l10n.goalMaintainSubtitle, selected, onChanged),
          const SizedBox(height: 12),
          _GoalCard('gain_muscle', l10n.goalGain,     '💪', l10n.goalGainSubtitle,     selected, onChanged),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard(this.value, this.label, this.emoji, this.subtitle, this.selected, this.onChanged);
  final String              value;
  final String              label;
  final String              emoji;
  final String              subtitle;
  final String              selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final isActive = selected == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color:        isActive ? AppColors.primaryLime.withValues(alpha: 0.12) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? AppColors.primaryLime : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            if (isActive) Icon(Icons.check_circle_rounded, color: AppColors.primaryLime),
          ],
        ),
      ),
    );
  }
}

// ── Shared page scaffold ──────────────────────────────────────────────────────

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

// ── Activity option data ──────────────────────────────────────────────────────

class _ActivityOption {
  const _ActivityOption(this.value, this.label, this.description, this.icon);
  final String   value;
  final String   label;
  final String   description;
  final IconData icon;
}
