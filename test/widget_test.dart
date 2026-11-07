import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:domino_venezolano/main.dart';
import 'package:domino_venezolano/providers/game_provider.dart';
import 'package:domino_venezolano/providers/theme_provider.dart';
import 'package:domino_venezolano/screens/team_setup_screen.dart';
import 'package:domino_venezolano/screens/turn_order_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts with team setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DominoVenezolanoApp());
    await tester.pumpAndSettle();

    expect(find.text('EQUIPO 1'), findsOneWidget);
    expect(find.text('EQUIPO 2'), findsOneWidget);
  });

  testWidgets('Saved light theme is applied to the setup screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'theme_mode_dark': false});

    await tester.pumpWidget(const DominoVenezolanoApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TeamSetupScreen));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('Placing a player automatically seats their partner opposite',
      (WidgetTester tester) async {
    final gameProvider = GameProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: TurnOrderScreen(
            team1Name: 'Los A',
            team2Name: 'Los B',
            team1Player1: 'Ana',
            team1Player2: 'Alex',
            team2Player1: 'Beto',
            team2Player2: 'Bea',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('player-0')));
    await tester.tap(find.byKey(const Key('seat-0')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('seat-0')),
        matching: find.text('Ana'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('seat-2')),
        matching: find.text('Alex'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('player-2')));
    await tester.tap(find.byKey(const Key('seat-1')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('start-game')));
    await tester.tap(find.byKey(const Key('start-game')));
    // The screen is the home route here, so it stays up with its spinner;
    // just let the async start finish.
    await tester.pump();
    await tester.pump();

    expect(gameProvider.currentGame?.playingOrder, [0, 2, 1, 3]);
  });
}
