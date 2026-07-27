import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SplitEase'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Split expenses without the awkwardness'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track shared expenses, split bills fairly, and settle balances with friends, family, roommates, or travel groups—all in one place.'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signUpHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpHeaderTitle;

  /// No description provided for @signUpHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start splitting expenses with your friends in minutes.'**
  String get signUpHeaderSubtitle;

  /// No description provided for @signInHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInHeaderTitle;

  /// No description provided for @signInHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue splitting expenses with your friends.'**
  String get signInHeaderSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNamePlaceholder;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'john@example.com'**
  String get emailPlaceholder;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordPlaceholder;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @fieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequiredError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailError;

  /// No description provided for @passwordTooShortError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShortError;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'SplitEase'**
  String get dashboardTitle;

  /// No description provided for @totalBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL BALANCE'**
  String get totalBalanceLabel;

  /// No description provided for @totalBalanceAmount.
  ///
  /// In en, this message translates to:
  /// **'\$240.50'**
  String get totalBalanceAmount;

  /// No description provided for @owedToYouLabel.
  ///
  /// In en, this message translates to:
  /// **'owed to you'**
  String get owedToYouLabel;

  /// No description provided for @settleUpAction.
  ///
  /// In en, this message translates to:
  /// **'Settle Up'**
  String get settleUpAction;

  /// No description provided for @addExpenseAction.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpenseAction;

  /// No description provided for @groupsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsSectionTitle;

  /// No description provided for @createGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupAction;

  /// No description provided for @youAreOwedLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU ARE OWED'**
  String get youAreOwedLabel;

  /// No description provided for @youOweLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU OWE'**
  String get youOweLabel;

  /// No description provided for @groupSkiTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Ski Trip 2024'**
  String get groupSkiTripTitle;

  /// No description provided for @groupSkiTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses for our annual winter getaway'**
  String get groupSkiTripSubtitle;

  /// No description provided for @groupRoommatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roommates'**
  String get groupRoommatesTitle;

  /// No description provided for @groupRoommatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared household bills and groceries'**
  String get groupRoommatesSubtitle;

  /// No description provided for @groupDinnerClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Dinner Club'**
  String get groupDinnerClubTitle;

  /// No description provided for @groupDinnerClubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly dinner rotation and shared wine'**
  String get groupDinnerClubSubtitle;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @menuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open navigation menu'**
  String get menuTooltip;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View notifications'**
  String get notificationsTooltip;

  /// No description provided for @createGroupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupScreenTitle;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'GROUP NAME'**
  String get groupNameLabel;

  /// No description provided for @groupNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ski Trip 2024'**
  String get groupNamePlaceholder;

  /// No description provided for @groupDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get groupDescriptionLabel;

  /// No description provided for @groupDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get groupDescriptionOptional;

  /// No description provided for @groupDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'What\'s this group for?'**
  String get groupDescriptionPlaceholder;

  /// No description provided for @addMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'ADD MEMBERS'**
  String get addMembersLabel;

  /// No description provided for @typeANamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a name...'**
  String get typeANamePlaceholder;

  /// No description provided for @addMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addMemberButton;

  /// No description provided for @groupMembersHeader.
  ///
  /// In en, this message translates to:
  /// **'Group Members ({count})'**
  String groupMembersHeader(int count);

  /// No description provided for @ownerBadge.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerBadge;

  /// No description provided for @youMemberName.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youMemberName;

  /// No description provided for @createGroupSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupSubmitButton;

  /// No description provided for @groupNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a group name'**
  String get groupNameRequiredError;

  /// No description provided for @groupCreationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreationSuccess;

  /// No description provided for @groupCreationError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group. Please try again.'**
  String get groupCreationError;

  /// No description provided for @noGroupsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsFoundTitle;

  /// No description provided for @noGroupsFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first group to start splitting expenses with friends!'**
  String get noGroupsFoundSubtitle;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @failedToLoadGroups.
  ///
  /// In en, this message translates to:
  /// **'Failed to load groups'**
  String get failedToLoadGroups;

  /// No description provided for @currentStanding.
  ///
  /// In en, this message translates to:
  /// **'Current Standing'**
  String get currentStanding;

  /// No description provided for @youAreOwedTitleCase.
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get youAreOwedTitleCase;

  /// No description provided for @totalGroupBalance.
  ///
  /// In en, this message translates to:
  /// **'TOTAL GROUP BALANCE: {amount}'**
  String totalGroupBalance(String amount);

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get recentExpenses;

  /// No description provided for @allExpenses.
  ///
  /// In en, this message translates to:
  /// **'All Expenses'**
  String get allExpenses;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @youLent.
  ///
  /// In en, this message translates to:
  /// **'you lent'**
  String get youLent;

  /// No description provided for @youOweLower.
  ///
  /// In en, this message translates to:
  /// **'you owe'**
  String get youOweLower;

  /// No description provided for @participantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Participants'**
  String participantsCount(int count);

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @othersCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} Others'**
  String othersCount(int count);

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'{name} paid {amount} • {date}'**
  String paidBy(String name, String amount, String date);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
