import 'package:flutter_test/flutter_test.dart';
import 'package:split_frontend/app.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitApp());
    expect(find.byType(SplitApp), findsOneWidget);
  });
}
