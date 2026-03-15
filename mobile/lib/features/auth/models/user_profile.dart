/// Lightweight local representation of GET /api/v1/users/me.
/// Only the fields needed by [AuthGate] and the Dashboard.
class UserProfile {
  final String  id;
  final String  name;
  final String  email;
  final bool    onboardingCompleted;
  final int?    dailyCalorieTarget;
  final int?    dailyProteinG;
  final int?    dailyCarbsG;
  final int?    dailyFatG;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.onboardingCompleted,
    this.dailyCalorieTarget,
    this.dailyProteinG,
    this.dailyCarbsG,
    this.dailyFatG,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final targets = json['macro_targets'] as Map<String, dynamic>? ?? {};
    return UserProfile(
      id:                   json['id'] as String,
      name:                 json['name'] as String,
      email:                json['email'] as String,
      onboardingCompleted:  json['onboarding_completed'] as bool? ?? false,
      dailyCalorieTarget:   targets['daily_calorie_target'] as int?,
      dailyProteinG:        targets['daily_protein_g'] as int?,
      dailyCarbsG:          targets['daily_carbs_g'] as int?,
      dailyFatG:            targets['daily_fat_g'] as int?,
    );
  }
}
