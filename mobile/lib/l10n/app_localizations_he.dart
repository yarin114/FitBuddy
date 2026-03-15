// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'פיטבאדי';

  @override
  String get next => 'הבא';

  @override
  String get back => 'חזרה';

  @override
  String get done => 'סיום';

  @override
  String get cancel => 'ביטול';

  @override
  String get save => 'שמירה';

  @override
  String get loading => 'טוען…';

  @override
  String get unexpectedError => 'משהו השתבש. אנא נסה שוב.';

  @override
  String get calories => 'קלוריות';

  @override
  String get protein => 'חלבון';

  @override
  String get carbs => 'פחמימות';

  @override
  String get fat => 'שומן';

  @override
  String get kcal => 'קל׳';

  @override
  String get today => 'היום';

  @override
  String get notifications => 'התראות';

  @override
  String get todaysMeals => 'ארוחות היום';

  @override
  String get addMeal => 'הוסף ארוחה';

  @override
  String get noMealsToday => 'עוד לא תועדו ארוחות היום.';

  @override
  String get tabDashboard => 'דשבורד';

  @override
  String get tabPantry => 'מזווה';

  @override
  String get tabSOS => 'SOS';

  @override
  String get couldNotLoadMacros => 'לא ניתן לטעון את הנתונים';

  @override
  String get sosComing => 'אימון בזמן אמת — בקרוב';

  @override
  String get logMealTitle => 'מה אכלת?';

  @override
  String get logMealSubtitle =>
      'תאר את הארוחה שלך והבינה המלאכותית תחשב את המאקרו.';

  @override
  String get logMealHint => 'למשל: 2 ביצים ו-100 גרם חזה עוף';

  @override
  String get logMealButton => 'תיעוד ארוחה';

  @override
  String get mealLogged => 'תועד';

  @override
  String get couldNotLogMeal => 'לא ניתן לתעד את הארוחה. אנא נסה שוב.';

  @override
  String get cravingTitle => 'מה בא לך לאכול?';

  @override
  String get cravingSubtitle =>
      'תאר את התשוקה שלך ונמצא לך מתכון שמתאים למאקרו.';

  @override
  String get cravingHint => 'למשל: משהו מתוק ושוקולדי';

  @override
  String get generateRecipe => 'צור מתכון';

  @override
  String get aiPick => 'המלצת AI';

  @override
  String get loginTitle => 'ברוך שובך';

  @override
  String get signUpTitle => 'צור חשבון';

  @override
  String get emailLabel => 'אימייל';

  @override
  String get passwordLabel => 'סיסמה';

  @override
  String get fullNameLabel => 'שם מלא';

  @override
  String get logInButton => 'כניסה';

  @override
  String get createAccountButton => 'יצירת חשבון';

  @override
  String get switchToSignUp => 'אין לך חשבון?';

  @override
  String get switchToLogin => 'כבר יש לך חשבון?';

  @override
  String get signUpLink => 'הרשמה';

  @override
  String get logInLink => 'כניסה';

  @override
  String get checkEmailMessage =>
      'בדוק את האימייל שלך לאישור החשבון, ואז התחבר.';

  @override
  String get couldNotCreateProfile => 'לא ניתן ליצור את הפרופיל. אנא נסה שוב.';

  @override
  String get enterName => 'הכנס את שמך';

  @override
  String get enterEmail => 'הכנס את האימייל שלך';

  @override
  String get enterValidEmail => 'הכנס אימייל תקין';

  @override
  String get enterPassword => 'הכנס סיסמה';

  @override
  String get passwordMinLength => 'הסיסמה חייבת להכיל לפחות 6 תווים';

  @override
  String onboardingStepOf(int step, int total) {
    return 'שלב $step מתוך $total';
  }

  @override
  String get languageTitle => 'בחר שפה';

  @override
  String get languageSubtitle => 'ניתן לשנות זאת בהגדרות בהמשך.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get genderTitle => 'מה המין שלך?';

  @override
  String get genderSubtitle => 'זה עוזר לנו לחשב את קצב חילוף החומרים שלך.';

  @override
  String get genderMale => 'זכר';

  @override
  String get genderFemale => 'נקבה';

  @override
  String get genderOther => 'אחר';

  @override
  String get ageTitle => 'בן/בת כמה אתה?';

  @override
  String get ageSubtitle => 'הגיל משמש לכוונון חישוב הקלוריות שלך.';

  @override
  String get yearsOld => 'שנים';

  @override
  String get bodyStatsTitle => 'המדידות שלך';

  @override
  String get bodyStatsSubtitle =>
      'משמש לחישוב ההוצאה הקלורית היומית הכוללת (TDEE).';

  @override
  String get bodyWeightLabel => 'משקל גוף';

  @override
  String get heightLabel => 'גובה';

  @override
  String get activityTitle => 'כמה אתה פעיל?';

  @override
  String get activitySubtitle => 'בחר את הרמה המתאימה ביותר לשבוע הטיפוסי שלך.';

  @override
  String get activitySedentary => 'יושבני';

  @override
  String get activitySedentaryDesc => 'עבודת משרד, מעט פעילות גופנית';

  @override
  String get activityLight => 'קל';

  @override
  String get activityLightDesc => 'פעילות גופנית 1–3 פעמים בשבוע';

  @override
  String get activityModerate => 'בינוני';

  @override
  String get activityModerateDesc => 'פעילות גופנית 3–5 פעמים בשבוע';

  @override
  String get activityActive => 'פעיל';

  @override
  String get activityActiveDesc => 'אימונים עצימים 6–7 פעמים בשבוע';

  @override
  String get activityVeryActive => 'פעיל מאוד';

  @override
  String get activityVeryActiveDesc => 'ספורטאי או עבודה פיזית מאומצת';

  @override
  String get goalTitle => 'מה המטרה שלך?';

  @override
  String get goalSubtitle => 'זה קובע את יעד הקלוריות והפיצול המאקרו שלך.';

  @override
  String get goalLose => 'ירידה במשקל';

  @override
  String get goalMaintain => 'שמירה על הקיים';

  @override
  String get goalGain => 'עלייה במסה';

  @override
  String get goalLoseSubtitle => 'גרעון של 500 קל׳ ביום';

  @override
  String get goalMaintainSubtitle => 'שמור על המשקל הנוכחי שלך';

  @override
  String get goalGainSubtitle => 'עודף של 500 קל׳ ביום';

  @override
  String get startJourney => '!בוא נתחיל 🚀';

  @override
  String get validationGender => 'אנא בחר מין';

  @override
  String get validationAge => 'הכנס גיל תקין (13–100)';

  @override
  String get validationMeasurements => 'הכנס מדידות תקינות';

  @override
  String get validationActivity => 'אנא בחר רמת פעילות';

  @override
  String get validationGoal => 'אנא בחר מטרה';

  @override
  String get settingsLanguage => 'שפה';
}
