import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:domino_venezolano/main.dart';
import 'package:domino_venezolano/screens/game_screen.dart';
import 'package:domino_venezolano/screens/team_setup_screen.dart';

Map<String, Object> _round(int losingTeamIndex, int points, int t1, int t2) => {
      'losingTeamIndex': losingTeamIndex,
      'points': points,
      'timestamp': '2026-11-07T10:00:00.000',
      'isTranca': false,
      'team1Total': t1,
      'team2Total': t2,
    };

/// A partida saved by a previous session, so the app opens straight into it.
Map<String, Object> _savedPrefs(
  List<Map<String, Object>> rounds, {
  int team1Wins = 0,
}) =>
    {
      'saved_team1_wins': team1Wins,
      'saved_game': jsonEncode({
        'team1Name': 'Los A',
        'team2Name': 'Los B',
        'team1Player1': 'Ana',
        'team1Player2': 'Alex',
        'team2Player1': 'Beto',
        'team2Player2': 'Bea',
        'rounds': rounds,
        'playingOrder': [0, 2, 1, 3],
        'currentTurnIndex': rounds.length % 4,
      }),
    };

Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(const DominoVenezolanoApp());
  await tester.pumpAndSettle();
}

/// Lets snackbars and delayed phrases expire so no timer outlives the test.
Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  testWidgets('starting a game leaves only the game on the stack',
      (tester) async {
    await _openApp(tester);

    final fields = find.byType(TextFormField);
    const names = ['Los A', 'Ana', 'Alex', 'Los B', 'Beto', 'Bea'];
    for (var i = 0; i < names.length; i++) {
      await tester.enterText(fields.at(i), names[i]);
    }
    await tester.ensureVisible(find.text('CONTINUAR →'));
    await tester.tap(find.text('CONTINUAR →'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('player-0')));
    await tester.tap(find.byKey(const Key('seat-0')));
    await tester.tap(find.byKey(const Key('player-2')));
    await tester.tap(find.byKey(const Key('seat-1')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('start-game')));
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();

    // Before the fix a second GameScreen (and later a stale setup screen)
    // sat underneath, so "back" could reopen setup and wipe the partida.
    expect(find.byType(GameScreen), findsOneWidget);
    final navigator = Navigator.of(tester.element(find.byType(GameScreen)));
    expect(navigator.canPop(), isFalse);

    await tester.tap(find.text('Nueva Partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Nueva Partida').last);
    await tester.pumpAndSettle();

    expect(find.byType(TeamSetupScreen), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(TeamSetupScreen))).canPop(),
      isFalse,
    );
  });

  testWidgets('a mano can be anotated as tranca', (tester) async {
    SharedPreferences.setMockInitialValues(_savedPrefs([]));
    await _openApp(tester);

    await tester.tap(find.byKey(const Key('team-panel-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('points-field')), '45');
    await tester.tap(find.byKey(const Key('tranca-switch')));
    await tester.pump();
    expect(find.text('(puntos que se anotan por la tranca)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('submit-mano')));
    await tester.pumpAndSettle();

    expect(find.text('+45'), findsOneWidget);
    expect(find.text('TRANCA'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('points above a full double-six set are rejected in the dialog',
      (tester) async {
    SharedPreferences.setMockInitialValues(_savedPrefs([]));
    await _openApp(tester);

    await tester.tap(find.byKey(const Key('team-panel-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('points-field')), '200');
    await tester.tap(find.byKey(const Key('submit-mano')));
    await tester.pumpAndSettle();

    expect(find.text('Los puntos deben estar entre 0 y 168'), findsOneWidget);
    expect(find.byKey(const Key('points-field')), findsOneWidget);

    // 99 used to be refused by the old 0-84 limit.
    await tester.enterText(find.byKey(const Key('points-field')), '99');
    await tester.tap(find.byKey(const Key('submit-mano')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('points-field')), findsNothing);
    expect(find.text('+99'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('deleting the last mano asks first', (tester) async {
    SharedPreferences.setMockInitialValues(_savedPrefs([_round(1, 60, 60, 0)]));
    await _openApp(tester);
    expect(find.text('+60'), findsOneWidget);

    await tester.tap(find.byKey(const Key('undo-mano')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('+60'), findsOneWidget);

    await tester.tap(find.byKey(const Key('undo-mano')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-undo')));
    await tester.pumpAndSettle();
    expect(find.text('+60'), findsNothing);
    expect(
      find.textContaining('Toca el equipo que ganó la mano'),
      findsOneWidget,
    );
  });

  testWidgets('backing out of a revancha brings the result back',
      (tester) async {
    SharedPreferences.setMockInitialValues(_savedPrefs(
      [_round(1, 60, 60, 0), _round(1, 45, 105, 0)],
      team1Wins: 1,
    ));
    await tester.pumpWidget(const DominoVenezolanoApp());
    // Confetti keeps animating, so step time instead of settling.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Revancha · elegir salida'), findsOneWidget);

    await tester.tap(find.text('Revancha · elegir salida'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('COMENZAR REVANCHA'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Revancha · elegir salida'), findsOneWidget);

    await tester.tap(find.text('Revancha · elegir salida'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const Key('start-game')));
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Partidas: 1 - 0'), findsOneWidget);
    expect(
      find.textContaining('Toca el equipo que ganó la mano'),
      findsOneWidget,
    );
    expect(
      Navigator.of(tester.element(find.byType(GameScreen))).canPop(),
      isFalse,
    );
    await tester.pump(const Duration(seconds: 10));
  });

  for (final size in const [Size(800, 360), Size(320, 568), Size(1024, 768)]) {
    testWidgets('game screen lays out without overflow at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(_savedPrefs([
        for (var i = 0; i < 6; i++) _round(i % 2, 10, 0, 0),
      ]));

      await _openApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('LA LIBRETA'), findsOneWidget);
    });
  }

  testWidgets('theme follows the system until the user picks one',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _openApp(tester);
    final context = tester.element(find.byType(TeamSetupScreen));
    expect(Theme.of(context).brightness, Brightness.dark);

    await tester.tap(find.byTooltip('Usar tema claro'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(TeamSetupScreen))).brightness,
      Brightness.light,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });
}
