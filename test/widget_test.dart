import 'package:flutter_test/flutter_test.dart';

import 'package:domino_venezolano/main.dart';

void main() {
  testWidgets('App starts with team setup screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DominoVenezolanoApp());
    await tester.pumpAndSettle();

    // Verify that team setup screen is shown
    expect(find.text('EQUIPO 1'), findsOneWidget);
    expect(find.text('EQUIPO 2'), findsOneWidget);
  });
}
