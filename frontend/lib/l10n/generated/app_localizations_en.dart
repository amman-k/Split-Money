// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SplitEase';

  @override
  String get welcomeTitle => 'Split expenses without the awkwardness';

  @override
  String get welcomeSubtitle =>
      'Track shared expenses, split bills fairly, and settle balances with friends, family, roommates, or travel groups—all in one place.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signUpHeaderTitle => 'Create your account';

  @override
  String get signUpHeaderSubtitle =>
      'Start splitting expenses with your friends in minutes.';

  @override
  String get signInHeaderTitle => 'Welcome back';

  @override
  String get signInHeaderSubtitle =>
      'Sign in to continue splitting expenses with your friends.';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNamePlaceholder => 'John Doe';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailPlaceholder => 'john@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordPlaceholder => '••••••••';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get signInButton => 'Sign In';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get fieldRequiredError => 'This field is required';

  @override
  String get invalidEmailError => 'Please enter a valid email address';

  @override
  String get passwordTooShortError => 'Password must be at least 8 characters';

  @override
  String get dashboardTitle => 'SplitEase';

  @override
  String get totalBalanceLabel => 'TOTAL BALANCE';

  @override
  String get totalBalanceAmount => '\$240.50';

  @override
  String get owedToYouLabel => 'owed to you';

  @override
  String get settleUpAction => 'Settle Up';

  @override
  String get addExpenseAction => 'Add Expense';

  @override
  String get groupsSectionTitle => 'Groups';

  @override
  String get createGroupAction => 'Create Group';

  @override
  String get youAreOwedLabel => 'YOU ARE OWED';

  @override
  String get youOweLabel => 'YOU OWE';

  @override
  String get groupSkiTripTitle => 'Ski Trip 2024';

  @override
  String get groupSkiTripSubtitle => 'Expenses for our annual winter getaway';

  @override
  String get groupRoommatesTitle => 'Roommates';

  @override
  String get groupRoommatesSubtitle => 'Shared household bills and groceries';

  @override
  String get groupDinnerClubTitle => 'Dinner Club';

  @override
  String get groupDinnerClubSubtitle =>
      'Weekly dinner rotation and shared wine';

  @override
  String get navActivity => 'Activity';

  @override
  String get navGroups => 'Groups';

  @override
  String get navFriends => 'Friends';

  @override
  String get navAccount => 'Account';

  @override
  String get menuTooltip => 'Open navigation menu';

  @override
  String get notificationsTooltip => 'View notifications';

  @override
  String get createGroupScreenTitle => 'Create Group';

  @override
  String get groupNameLabel => 'GROUP NAME';

  @override
  String get groupNamePlaceholder => 'e.g. Ski Trip 2024';

  @override
  String get groupDescriptionLabel => 'DESCRIPTION';

  @override
  String get groupDescriptionOptional => '(optional)';

  @override
  String get groupDescriptionPlaceholder => 'What\'s this group for?';

  @override
  String get addMembersLabel => 'ADD MEMBERS';

  @override
  String get typeANamePlaceholder => 'Type a name...';

  @override
  String get addMemberButton => 'Add';

  @override
  String groupMembersHeader(int count) {
    return 'Group Members ($count)';
  }

  @override
  String get ownerBadge => 'Owner';

  @override
  String get youMemberName => 'You';

  @override
  String get createGroupSubmitButton => 'Create Group';

  @override
  String get groupNameRequiredError => 'Please enter a group name';

  @override
  String get groupCreationSuccess => 'Group created successfully';

  @override
  String get groupCreationError => 'Failed to create group. Please try again.';

  @override
  String get noGroupsFoundTitle => 'No groups yet';

  @override
  String get noGroupsFoundSubtitle =>
      'Create your first group to start splitting expenses with friends!';

  @override
  String get retryAction => 'Retry';

  @override
  String get failedToLoadGroups => 'Failed to load groups';

  @override
  String get currentStanding => 'Current Standing';

  @override
  String get youAreOwedTitleCase => 'You are owed';

  @override
  String totalGroupBalance(String amount) {
    return 'TOTAL GROUP BALANCE: $amount';
  }

  @override
  String get recentExpenses => 'Recent Expenses';

  @override
  String get allExpenses => 'All Expenses';

  @override
  String get viewAll => 'View all';

  @override
  String get youLent => 'you lent';

  @override
  String get youOweLower => 'you owe';

  @override
  String participantsCount(int count) {
    return '$count Participants';
  }

  @override
  String get others => 'Others';

  @override
  String othersCount(int count) {
    return '+$count Others';
  }

  @override
  String paidBy(String name, String amount, String date) {
    return '$name paid $amount • $date';
  }
}
