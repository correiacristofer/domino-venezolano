import 'package:flutter_test/flutter_test.dart';

import 'package:domino_duel/main.dart';

void main() {
  testWidgets('App starts with team setup screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DominoDuelApp());

    // Verify that team setup screen is shown
    expect(find.text('DOMINO DUEL'), findsOneWidget);
    expect(find.text('EQUIPO 1'), findsOneWidget);
    expect(find.text('EQUIPO 2'), findsOneWidget);
  });
}
