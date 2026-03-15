import 'package:freezed_annotation/freezed_annotation.dart';

part 'macro_summary.freezed.dart';

/// Daily macro snapshot — drives the calorie ring, macro pills, and meal list.
@freezed
abstract class MacroSummary with _$MacroSummary {
  const factory MacroSummary({
    required int    caloriesConsumed,
    required int    caloriesGoal,
    required double proteinConsumedG,
    required double proteinGoalG,
    required double carbsConsumedG,
    required double carbsGoalG,
    required double fatConsumedG,
    required double fatGoalG,
    @Default([]) List<LoggedMeal> todayMeals,
  }) = _MacroSummary;

  const MacroSummary._();

  int    get caloriesRemaining => (caloriesGoal - caloriesConsumed).clamp(0, caloriesGoal);
  double get caloriesProgress  => caloriesGoal == 0 ? 0 : (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0);
  double get proteinProgress   => proteinGoalG  == 0 ? 0 : (proteinConsumedG / proteinGoalG).clamp(0.0, 1.0);
  double get carbsProgress     => carbsGoalG    == 0 ? 0 : (carbsConsumedG   / carbsGoalG).clamp(0.0, 1.0);
  double get fatProgress       => fatGoalG      == 0 ? 0 : (fatConsumedG     / fatGoalG).clamp(0.0, 1.0);
}

/// A single meal entry in today's log.
@freezed
abstract class LoggedMeal with _$LoggedMeal {
  const factory LoggedMeal({
    required String   id,
    required String   name,
    required DateTime loggedAt,
    required int      calories,
    required double   proteinG,
    required double   carbsG,
    required double   fatG,
  }) = _LoggedMeal;
}
