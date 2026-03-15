// Run after adding this file:
//   flutter pub run build_runner build --delete-conflicting-outputs
// Generates: dashboard_provider.g.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_client.dart';
import '../models/macro_summary.dart';

part 'dashboard_provider.g.dart';

/// Today's macro summary — fetched from GET /api/v1/macros/today.
///
/// Falls back to mock data when the user has no active Supabase session
/// (development / UI testing without auth).
@riverpod
Future<MacroSummary> macroSummary(Ref ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    // No auth — return mock data so the UI is testable without a backend.
    return _mockSummary;
  }

  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get<Map<String, dynamic>>('/api/v1/macros/today');
    final data = response.data!;
    final budget = data['budget'] as Map<String, dynamic>;

    // GET /api/v1/macros/today returns a DailyLogResponse.
    // We map the budget fields onto MacroSummary.
    // todayMeals are fetched separately via GET /api/v1/meals/today.
    final mealsResponse = await dio.get<List<dynamic>>('/api/v1/meals/today');
    final meals = (mealsResponse.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mealFromJson)
        .toList();

    return MacroSummary(
      caloriesConsumed:  budget['calories_consumed'] as int,
      caloriesGoal:      budget['calories_target'] as int,
      proteinConsumedG:  (budget['protein_consumed_g'] as num).toDouble(),
      proteinGoalG:      (budget['protein_target_g'] as num).toDouble(),
      carbsConsumedG:    (budget['carbs_consumed_g'] as num).toDouble(),
      carbsGoalG:        (budget['carbs_target_g'] as num).toDouble(),
      fatConsumedG:      (budget['fat_consumed_g'] as num).toDouble(),
      fatGoalG:          (budget['fat_target_g'] as num).toDouble(),
      todayMeals:        meals,
    );
  } on DioException {
    // Network or 4xx/5xx — fall back to mock so the UI doesn't crash.
    return _mockSummary;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

LoggedMeal _mealFromJson(Map<String, dynamic> j) => LoggedMeal(
  id:        j['id'] as String,
  name:      j['name'] as String,
  calories:  j['total_calories'] as int,
  proteinG:  (j['total_protein_g'] as num).toDouble(),
  carbsG:    (j['total_carbs_g'] as num).toDouble(),
  fatG:      (j['total_fat_g'] as num).toDouble(),
  loggedAt:  DateTime.parse(j['logged_at'] as String),
);

// ── Mock data (no-auth fallback) ──────────────────────────────────────────────

final _mockSummary = MacroSummary(
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
      id:       '1',
      name:     'Oats & Banana Breakfast',
      calories: 420,
      proteinG: 18,
      carbsG:   74,
      fatG:     8,
      loggedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    LoggedMeal(
      id:       '2',
      name:     'Grilled Chicken & Broccoli',
      calories: 380,
      proteinG: 42,
      carbsG:   28,
      fatG:     9,
      loggedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    LoggedMeal(
      id:       '3',
      name:     'Greek Yogurt Protein Bowl',
      calories: 280,
      proteinG: 28,
      carbsG:   24,
      fatG:     6,
      loggedAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
  ],
);
