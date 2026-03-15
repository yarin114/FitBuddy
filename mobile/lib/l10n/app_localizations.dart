import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FitBuddy'**
  String get appName;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unexpectedError;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @todaysMeals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meals'**
  String get todaysMeals;

  /// No description provided for @addMeal.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get addMeal;

  /// No description provided for @noMealsToday.
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet today.'**
  String get noMealsToday;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get tabPantry;

  /// No description provided for @tabSOS.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get tabSOS;

  /// No description provided for @couldNotLoadMacros.
  ///
  /// In en, this message translates to:
  /// **'Could not load macros'**
  String get couldNotLoadMacros;

  /// No description provided for @sosComing.
  ///
  /// In en, this message translates to:
  /// **'Real-time coaching — coming soon'**
  String get sosComing;

  /// No description provided for @logMealTitle.
  ///
  /// In en, this message translates to:
  /// **'What did you eat?'**
  String get logMealTitle;

  /// No description provided for @logMealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your meal and the AI will estimate the macros.'**
  String get logMealSubtitle;

  /// No description provided for @logMealHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 eggs and 100g grilled chicken'**
  String get logMealHint;

  /// No description provided for @logMealButton.
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get logMealButton;

  /// No description provided for @mealLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get mealLogged;

  /// No description provided for @couldNotLogMeal.
  ///
  /// In en, this message translates to:
  /// **'Could not log your meal. Please try again.'**
  String get couldNotLogMeal;

  /// No description provided for @cravingTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you craving?'**
  String get cravingTitle;

  /// No description provided for @cravingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your craving and we\'ll find a macro-friendly recipe.'**
  String get cravingSubtitle;

  /// No description provided for @cravingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. something sweet and chocolatey'**
  String get cravingHint;

  /// No description provided for @generateRecipe.
  ///
  /// In en, this message translates to:
  /// **'Generate Recipe'**
  String get generateRecipe;

  /// No description provided for @aiPick.
  ///
  /// In en, this message translates to:
  /// **'AI Pick'**
  String get aiPick;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @logInButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logInButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @switchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get switchToSignUp;

  /// No description provided for @switchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get switchToLogin;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @logInLink.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logInLink;

  /// No description provided for @checkEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then log in.'**
  String get checkEmailMessage;

  /// No description provided for @couldNotCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not create your profile. Please try again.'**
  String get couldNotCreateProfile;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepOf(int step, int total);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית (Hebrew)'**
  String get languageHebrew;

  /// No description provided for @genderTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your gender?'**
  String get genderTitle;

  /// No description provided for @genderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us calculate your metabolic rate accurately.'**
  String get genderSubtitle;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @ageTitle.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get ageTitle;

  /// No description provided for @ageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Age is used to fine-tune your calorie calculations.'**
  String get ageSubtitle;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'years old'**
  String get yearsOld;

  /// No description provided for @bodyStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your measurements'**
  String get bodyStatsTitle;

  /// No description provided for @bodyStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to calculate your Total Daily Energy Expenditure (TDEE).'**
  String get bodyStatsSubtitle;

  /// No description provided for @bodyWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get bodyWeightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'How active are you?'**
  String get activityTitle;

  /// No description provided for @activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the level that best matches your typical week.'**
  String get activitySubtitle;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activitySedentaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Desk job, little or no exercise'**
  String get activitySedentaryDesc;

  /// No description provided for @activityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get activityLight;

  /// No description provided for @activityLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercise 1–3× per week'**
  String get activityLightDesc;

  /// No description provided for @activityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get activityModerate;

  /// No description provided for @activityModerateDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercise 3–5× per week'**
  String get activityModerateDesc;

  /// No description provided for @activityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activityActive;

  /// No description provided for @activityActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Hard exercise 6–7× per week'**
  String get activityActiveDesc;

  /// No description provided for @activityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very Active'**
  String get activityVeryActive;

  /// No description provided for @activityVeryActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Athlete or physically demanding job'**
  String get activityVeryActiveDesc;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get goalTitle;

  /// No description provided for @goalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This determines your calorie target and macro split.'**
  String get goalSubtitle;

  /// No description provided for @goalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose Weight'**
  String get goalLose;

  /// No description provided for @goalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goalMaintain;

  /// No description provided for @goalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain Muscle'**
  String get goalGain;

  /// No description provided for @goalLoseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'-500 kcal/day deficit'**
  String get goalLoseSubtitle;

  /// No description provided for @goalMaintainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay at your current weight'**
  String get goalMaintainSubtitle;

  /// No description provided for @goalGainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'+500 kcal/day surplus'**
  String get goalGainSubtitle;

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Start My Journey 🚀'**
  String get startJourney;

  /// No description provided for @validationGender.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get validationGender;

  /// No description provided for @validationAge.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age (13–100)'**
  String get validationAge;

  /// No description provided for @validationMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Enter valid measurements'**
  String get validationMeasurements;

  /// No description provided for @validationActivity.
  ///
  /// In en, this message translates to:
  /// **'Please select your activity level'**
  String get validationActivity;

  /// No description provided for @validationGoal.
  ///
  /// In en, this message translates to:
  /// **'Please select your goal'**
  String get validationGoal;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
