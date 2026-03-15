// Run after adding this file:
//   flutter pub run build_runner build --delete-conflicting-outputs
// Generates: dashboard_provider.g.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/macro_summary.dart';

part 'dashboard_provider.g.dart';

/// Today's macro summary.
///
/// Currently returns mock data so the UI can be tested without a live backend.
/// Replace the body of this provider with a real API call when backend is ready:
///   final response = await ref.read(apiClientProvider).get('/api/v1/macros/today');
///   return MacroSummary.fromJson(response.data);
@riverpod
MacroSummary macroSummary(Ref ref) {
  return MacroSummary(
    caloriesConsumed: 1340,
    caloriesGoal:     2100,
    proteinConsumedG: 87,
    proteinGoalG:     157,
    carbsConsumedG:   134,
    carbsGoalG:       210,
    fatConsumedG:     44,
    fatGoalG:         70,
    todayMeals: [
      LoggedMeal(
        id:        '1',
        name:      'Oats & Banana Breakfast',
        calories:  420,
        proteinG:  18,
        carbsG:    74,
        fatG:      8,
        loggedAt:  DateTime.now().subtract(const Duration(hours: 4)),
      ),
      LoggedMeal(
        id:        '2',
        name:      'Grilled Chicken & Broccoli',
        calories:  380,
        proteinG:  42,
        carbsG:    28,
        fatG:      9,
        loggedAt:  DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      ),
      LoggedMeal(
        id:        '3',
        name:      'Greek Yogurt Protein Bowl',
        calories:  280,
        proteinG:  28,
        carbsG:    24,
        fatG:      6,
        loggedAt:  DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ],
  );
}
