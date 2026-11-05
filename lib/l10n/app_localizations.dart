import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kalm Corner'**
  String get appTitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night.'**
  String get goodNight;

  /// No description provided for @calmMinutesToday.
  ///
  /// In en, this message translates to:
  /// **'{count} calm minutes today'**
  String calmMinutesToday(Object count);

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @windDown.
  ///
  /// In en, this message translates to:
  /// **'Wind down'**
  String get windDown;

  /// No description provided for @calmPlus.
  ///
  /// In en, this message translates to:
  /// **'Calm Plus'**
  String get calmPlus;

  /// No description provided for @windowWipe.
  ///
  /// In en, this message translates to:
  /// **'Window Wipe'**
  String get windowWipe;

  /// No description provided for @bubblePop.
  ///
  /// In en, this message translates to:
  /// **'Bubble Pop'**
  String get bubblePop;

  /// No description provided for @sandGarden.
  ///
  /// In en, this message translates to:
  /// **'Sand Garden'**
  String get sandGarden;

  /// No description provided for @colorSort.
  ///
  /// In en, this message translates to:
  /// **'Color Sort'**
  String get colorSort;

  /// No description provided for @growPlant.
  ///
  /// In en, this message translates to:
  /// **'Grow a Plant'**
  String get growPlant;

  /// No description provided for @windowWipeTagline.
  ///
  /// In en, this message translates to:
  /// **'Clear the glass, bring the world back'**
  String get windowWipeTagline;

  /// No description provided for @bubblePopTagline.
  ///
  /// In en, this message translates to:
  /// **'Soft little pops'**
  String get bubblePopTagline;

  /// No description provided for @sandGardenTagline.
  ///
  /// In en, this message translates to:
  /// **'Rake, place, breathe'**
  String get sandGardenTagline;

  /// No description provided for @colorSortTagline.
  ///
  /// In en, this message translates to:
  /// **'Pour until each tube is one color'**
  String get colorSortTagline;

  /// No description provided for @growPlantTagline.
  ///
  /// In en, this message translates to:
  /// **'Water it, catch the light'**
  String get growPlantTagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'A little pocket of calm'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Short, gentle games for whenever you need a breath.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'No scores. No timers. No rush.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Nothing to win or lose. Just something nice to do with your hands.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Sound and touch can be changed any time.'**
  String get onboardingBody3;

  /// No description provided for @begin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get begin;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @again.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get again;

  /// No description provided for @nextScene.
  ///
  /// In en, this message translates to:
  /// **'Next scene'**
  String get nextScene;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @nextPlant.
  ///
  /// In en, this message translates to:
  /// **'Next plant'**
  String get nextPlant;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @ofCalm.
  ///
  /// In en, this message translates to:
  /// **'of calm'**
  String get ofCalm;

  /// No description provided for @windDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Wind down'**
  String get windDownTitle;

  /// No description provided for @windDown10min.
  ///
  /// In en, this message translates to:
  /// **'10 min'**
  String get windDown10min;

  /// No description provided for @windDown20min.
  ///
  /// In en, this message translates to:
  /// **'20 min'**
  String get windDown20min;

  /// No description provided for @windDown30min.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get windDown30min;

  /// No description provided for @windDown45min.
  ///
  /// In en, this message translates to:
  /// **'45 min'**
  String get windDown45min;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get settingsMaster;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusic;

  /// No description provided for @settingsEffects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get settingsEffects;

  /// No description provided for @settingsMixWithOthers.
  ///
  /// In en, this message translates to:
  /// **'Mix with other apps\' audio'**
  String get settingsMixWithOthers;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsHapticsOff;

  /// No description provided for @settingsHapticsSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get settingsHapticsSoft;

  /// No description provided for @settingsHapticsNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settingsHapticsNormal;

  /// No description provided for @settingsLook.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get settingsLook;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeDawn.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get settingsThemeDawn;

  /// No description provided for @settingsThemeDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get settingsThemeDusk;

  /// No description provided for @settingsThemeMoonlit.
  ///
  /// In en, this message translates to:
  /// **'Moonlit'**
  String get settingsThemeMoonlit;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceMotionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsReduceMotionSystem;

  /// No description provided for @settingsReduceMotionOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsReduceMotionOn;

  /// No description provided for @settingsReduceMotionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsReduceMotionOff;

  /// No description provided for @settingsColorblind.
  ///
  /// In en, this message translates to:
  /// **'Colorblind assist'**
  String get settingsColorblind;

  /// No description provided for @settingsLeftHanded.
  ///
  /// In en, this message translates to:
  /// **'Left-handed layout'**
  String get settingsLeftHanded;

  /// No description provided for @settingsKeepAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep screen awake'**
  String get settingsKeepAwake;

  /// No description provided for @settingsFastPour.
  ///
  /// In en, this message translates to:
  /// **'Fast pour'**
  String get settingsFastPour;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get settingsCredits;

  /// No description provided for @settingsResetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress'**
  String get settingsResetProgress;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'This clears your progress and your sand garden. It cannot be undone.'**
  String get settingsResetConfirm;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Calm Plus'**
  String get premiumTitle;

  /// No description provided for @premiumFeature1.
  ///
  /// In en, this message translates to:
  /// **'Three more window scenes'**
  String get premiumFeature1;

  /// No description provided for @premiumFeature2.
  ///
  /// In en, this message translates to:
  /// **'More bubble skies and a night palette'**
  String get premiumFeature2;

  /// No description provided for @premiumFeature3.
  ///
  /// In en, this message translates to:
  /// **'Moon sand and more plants'**
  String get premiumFeature3;

  /// No description provided for @premiumFeature4.
  ///
  /// In en, this message translates to:
  /// **'Extra music'**
  String get premiumFeature4;

  /// No description provided for @premiumFeature5.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get premiumFeature5;

  /// No description provided for @premiumUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get premiumUnlock;

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get premiumRestore;

  /// No description provided for @premiumNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get premiumNotNow;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet minute is waiting.'**
  String get reminderTitle;

  /// No description provided for @hintWindowWipe.
  ///
  /// In en, this message translates to:
  /// **'Drag to wipe the glass'**
  String get hintWindowWipe;

  /// No description provided for @hintBubblePop.
  ///
  /// In en, this message translates to:
  /// **'Touch a bubble. Hold to blow more'**
  String get hintBubblePop;

  /// No description provided for @hintSandGarden.
  ///
  /// In en, this message translates to:
  /// **'Drag to rake. Drop a stone'**
  String get hintSandGarden;

  /// No description provided for @hintColorSort.
  ///
  /// In en, this message translates to:
  /// **'Tap a tube, then another'**
  String get hintColorSort;

  /// No description provided for @hintGrowPlant.
  ///
  /// In en, this message translates to:
  /// **'Drag the can over the pot'**
  String get hintGrowPlant;

  /// No description provided for @completionLine1.
  ///
  /// In en, this message translates to:
  /// **'Clear as morning.'**
  String get completionLine1;

  /// No description provided for @completionLine2.
  ///
  /// In en, this message translates to:
  /// **'Nicely done. Take a breath.'**
  String get completionLine2;

  /// No description provided for @completionLine3.
  ///
  /// In en, this message translates to:
  /// **'That felt good.'**
  String get completionLine3;

  /// No description provided for @completionLine4.
  ///
  /// In en, this message translates to:
  /// **'All settled.'**
  String get completionLine4;

  /// No description provided for @completionLine5.
  ///
  /// In en, this message translates to:
  /// **'Soft and still.'**
  String get completionLine5;

  /// No description provided for @completionLine6.
  ///
  /// In en, this message translates to:
  /// **'Lovely.'**
  String get completionLine6;

  /// No description provided for @completionLine7.
  ///
  /// In en, this message translates to:
  /// **'Calm, collected.'**
  String get completionLine7;

  /// No description provided for @completionLine8.
  ///
  /// In en, this message translates to:
  /// **'Ahh. There it is.'**
  String get completionLine8;

  /// No description provided for @completionLine9.
  ///
  /// In en, this message translates to:
  /// **'Well tended.'**
  String get completionLine9;

  /// No description provided for @completionLine10.
  ///
  /// In en, this message translates to:
  /// **'Peace, delivered.'**
  String get completionLine10;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
