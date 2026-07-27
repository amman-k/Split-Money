import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_frontend/features/groups/presentation/screens/create_group_screen.dart';
import 'package:split_frontend/l10n/generated/app_localizations.dart';

void main() {
  Widget createSubject() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateGroupScreen(),
      ),
    );
  }

  group('CreateGroupScreen Widget Tests', () {
    testWidgets(
      'renders initial members (You, Alex, Sarah) and form elements',
      (WidgetTester tester) async {
        await tester.pumpWidget(createSubject());
        await tester.pumpAndSettle();

        // Title in AppBar + Button label at bottom = 2 occurrences
        expect(find.text('Create Group'), findsNWidgets(2));
        expect(find.text('GROUP NAME'), findsOneWidget);
        expect(find.text('DESCRIPTION'), findsOneWidget);
        expect(find.text('ADD MEMBERS'), findsOneWidget);
        expect(find.text('You'), findsOneWidget);
        expect(find.text('Alex'), findsOneWidget);
        expect(find.text('Sarah'), findsOneWidget);
      },
    );

    testWidgets('adds a new member when Add button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final addMemberInput = find.byType(TextField).at(2);
      await tester.ensureVisible(addMemberInput);
      await tester.pumpAndSettle();
      await tester.enterText(addMemberInput, 'David');
      await tester.pump();

      // Find the specific tonal Add icon/button next to the add member textfield
      final addButton = find.byIcon(Icons.add);
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('David'), findsOneWidget);
    });

    testWidgets('removes a member when close icon button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsOneWidget);

      final removeAlexBtn = find.bySemanticsLabel('Remove Alex');
      await tester.ensureVisible(removeAlexBtn);
      await tester.pumpAndSettle();
      await tester.tap(removeAlexBtn);
      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsNothing);
      expect(find.text('Sarah'), findsOneWidget);
    });

    testWidgets('shows snackbar validation error when group name is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final submitBtn = find.byType(FilledButton).last;
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please enter a group name'), findsOneWidget);
    });

    testWidgets('matches golden file for UI visual drift verification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CreateGroupScreen),
        matchesGoldenFile('goldens/create_group_screen.png'),
      );
    });
  });
}
