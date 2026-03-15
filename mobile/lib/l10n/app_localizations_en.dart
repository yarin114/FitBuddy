// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FitBuddy';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get loading => 'Loading…';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get kcal => 'kcal';

  @override
  String get today => 'Today';

  @override
  String get notifications => 'Notifications';

  @override
  String get todaysMeals => 'Today\'s Meals';

  @override
  String get addMeal => 'Add meal';

  @override
  String get noMealsToday => 'No meals logged yet today.';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabPantry => 'Pantry';

  @override
  String get tabSOS => 'SOS';

  @override
  String get couldNotLoadMacros => 'Could not load macros';

  @override
  String get sosComing => 'Real-time coaching — coming soon';

  @override
  String get logMealTitle => 'What did you eat?';

  @override
  String get logMealSubtitle =>
      'Describe your meal and the AI will estimate the macros.';

  @override
  String get logMealHint => 'e.g. 2 eggs and 100g grilled chicken';

  @override
  String get logMealButton => 'Log Meal';

  @override
  String get mealLogged => 'Logged';

  @override
  String get couldNotLogMeal => 'Could not log your meal. Please try again.';

  @override
  String get cravingTitle => 'What are you craving?';

  @override
  String get cravingSubtitle =>
      'Describe your craving and we\'ll find a macro-friendly recipe.';

  @override
  String get cravingHint => 'e.g. something sweet and chocolatey';

  @override
  String get generateRecipe => 'Generate Recipe';

  @override
  String get aiPick => 'AI Pick';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get logInButton => 'Log In';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get switchToSignUp => 'Don\'t have an account?';

  @override
  String get switchToLogin => 'Already have an account?';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get logInLink => 'Log In';

  @override
  String get checkEmailMessage =>
      'Check your email to confirm your account, then log in.';

  @override
  String get couldNotCreateProfile =>
      'Could not create your profile. Please try again.';

  @override
  String get enterName => 'Enter your name';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String onboardingStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this later in Settings.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית (Hebrew)';

  @override
  String get genderTitle => 'What\'s your gender?';

  @override
  String get genderSubtitle =>
      'This helps us calculate your metabolic rate accurately.';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get ageTitle => 'How old are you?';

  @override
  String get ageSubtitle =>
      'Age is used to fine-tune your calorie calculations.';

  @override
  String get yearsOld => 'years old';

  @override
  String get bodyStatsTitle => 'Your measurements';

  @override
  String get bodyStatsSubtitle =>
      'Used to calculate your Total Daily Energy Expenditure (TDEE).';

  @override
  String get bodyWeightLabel => 'Body weight';

  @override
  String get heightLabel => 'Height';

  @override
  String get activityTitle => 'How active are you?';

  @override
  String get activitySubtitle =>
      'Choose the level that best matches your typical week.';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activitySedentaryDesc => 'Desk job, little or no exercise';

  @override
  String get activityLight => 'Light';

  @override
  String get activityLightDesc => 'Exercise 1–3× per week';

  @override
  String get activityModerate => 'Moderate';

  @override
  String get activityModerateDesc => 'Exercise 3–5× per week';

  @override
  String get activityActive => 'Active';

  @override
  String get activityActiveDesc => 'Hard exercise 6–7× per week';

  @override
  String get activityVeryActive => 'Very Active';

  @override
  String get activityVeryActiveDesc => 'Athlete or physically demanding job';

  @override
  String get goalTitle => 'What\'s your goal?';

  @override
  String get goalSubtitle =>
      'This determines your calorie target and macro split.';

  @override
  String get goalLose => 'Lose Weight';

  @override
  String get goalMaintain => 'Maintain';

  @override
  String get goalGain => 'Gain Muscle';

  @override
  String get goalLoseSubtitle => '-500 kcal/day deficit';

  @override
  String get goalMaintainSubtitle => 'Stay at your current weight';

  @override
  String get goalGainSubtitle => '+500 kcal/day surplus';

  @override
  String get startJourney => 'Start My Journey 🚀';

  @override
  String get validationGender => 'Please select your gender';

  @override
  String get validationAge => 'Enter a valid age (13–100)';

  @override
  String get validationMeasurements => 'Enter valid measurements';

  @override
  String get validationActivity => 'Please select your activity level';

  @override
  String get validationGoal => 'Please select your goal';

  @override
  String get settingsLanguage => 'Language';
}
