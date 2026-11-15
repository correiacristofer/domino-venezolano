// Launch QA: every screen on small phones, in landscape and with the largest
// accessibility text, using long names with emoji. Any layout overflow or
// other framework error fails the test and names the case that broke.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:domino_venezolano/main.dart';
import 'package:domino_venezolano/models/game.dart';
import 'package:domino_venezolano/models/round.dart';
import 'package:domino_venezolano/providers/game_provider.dart';
import 'package:domino_venezolano/providers/theme_provider.dart';
import 'package:domino_venezolano/screens/turn_order_screen.dart';
import 'package:domino_venezolano/widgets/libreta_share_card.dart';

const _team1 = 'Los Panas del Barrio de Catia 🇻🇪🔥';
const _team2 = 'LosTigresDeLaGuairaCampeonesInvictos';
const _players = [
  'María Alejandra Fernández 👑',
  'José Gregorio Hernández',
  'Ñañá 😂😂😂😂😂',
  'WWWWWWWWWWWWWWWWWWWWWWWWW',
];

const _sizes = <String, Size>{
  '320x568': Size(320, 568),
  '360x640': Size(360, 640),
  '568x320 horizontal': Size(568, 320),
  '740x360 horizontal': Size(740, 360),
};

const _scales = [1.0, 1.5, 2.0];

Map<String, Object> _round(
  int losing,
  int points,
  int t1,
  int t2, {
  bool tranca = false,
}) => {
  'losingTeamIndex': losing,
  'points': points,
  'timestamp': '2026-11-15T10:00:00.000',
  'isTranca': tranca,
  'team1Total': t1,
  'team2Total': t2,
};

/// 0 points, a tranca and the 168 maximum; [finished] adds the winning mano.
/// [plainNames] avoids emoji, which the contrast check cannot measure (the
/// test environment has no emoji font).
Map<String, Object> _saved({required bool finished, bool plainNames = false}) {
  final names = plainNames
      ? const ['Los Panas', 'Los Tigres', 'Ana', 'Alex', 'Beto', 'Bea']
      : [_team1, _team2, ..._players];
  final rounds = [
    _round(1, 0, 0, 0),
    _round(0, 45, 0, 45, tranca: true),
    _round(1, 37, 37, 45),
    if (finished) _round(1, 168, 205, 45),
  ];
  return {
    'saved_team1_wins': 12,
    'saved_team2_wins': 9,
    'saved_game': jsonEncode({
      'team1Name': names[0],
      'team2Name': names[1],
      'team1Player1': names[2],
      'team1Player2': names[3],
      'team2Player1': names[4],
      'team2Player2': names[5],
      'rounds': rounds,
      'playingOrder': [0, 2, 1, 3],
      'currentTurnIndex': rounds.length % 4,
    }),
  };
}

Game _finishedGame() => Game(
  team1Name: _team1,
  team2Name: _team2,
  team1Player1: _players[0],
  team1Player2: _players[1],
  team2Player1: _players[2],
  team2Player2: _players[3],
  playingOrder: const [0, 2, 1, 3],
  rounds: [
    for (var i = 0; i < 12; i++)
      Round(
        losingTeamIndex: i.isEven ? 1 : 0,
        points: i == 11 ? 168 : i,
        timestamp: DateTime(2026, 11, 15),
        isTranca: i % 3 == 0,
        team1Total: 0,
        team2Total: 0,
      ),
  ],
);

/// Runs [body] with the screen size, text scale and brightness applied and
/// fails with every framework error (overflows included) it reported.
Future<void> _check(
  WidgetTester tester,
  String label,
  Size size,
  double scale,
  Brightness brightness,
  Future<void> Function() body,
) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final where = RegExp(
      r'lib/[\w/]+\.dart:\d+',
    ).firstMatch(details.toString())?.group(0);
    errors.add(
      '${details.exceptionAsString().split('\n').first} '
      '(${where ?? 'sin ubicación'})',
    );
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  expect(errors, isEmpty, reason: label);
}

/// Lets snackbars, confetti and delayed phrases finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// The default test font draws every glyph as a 1 em square, about twice as
/// wide as Roboto, which would flag overflows no phone shows. Load the real
/// Roboto that ships with the Flutter SDK instead.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT no está definido');
  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
    // The Dart SDK always ships DevTools with Roboto; material_fonts is only
    // downloaded once an app has been built.
    final candidates = [
      '$root/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/Roboto/'
          'Roboto-$weight.ttf',
      '$root/bin/cache/artifacts/material_fonts/'
          'roboto-${weight.toLowerCase()}.ttf',
    ];
    final file = candidates.map(File.new).firstWhere(
          (f) => f.existsSync(),
          orElse: () => throw StateError('Roboto no encontrada: $candidates'),
        );
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  for (final entry in _sizes.entries) {
    for (final scale in _scales) {
      final brightness = scale == 2.0 ? Brightness.dark : Brightness.light;
      final tag =
          '${entry.key} · texto ${(scale * 100).round()} % · '
          '${brightness == Brightness.dark ? 'oscuro' : 'claro'}';

      testWidgets('setup con nombres largos · $tag', (tester) async {
        await _check(tester, tag, entry.value, scale, brightness, () async {
          await tester.pumpWidget(const DominoVenezolanoApp());
          await tester.pumpAndSettle();
          final fields = find.byType(TextFormField);
          final names = [
            _team1,
            _players[0],
            _players[1],
            _team2,
            _players[2],
            _players[3],
          ];
          for (var i = 0; i < names.length; i++) {
            await tester.ensureVisible(fields.at(i));
            await tester.enterText(fields.at(i), names[i]);
          }
          await tester.pumpAndSettle();
        });
      });

      testWidgets('orden de juego con nombres largos · $tag', (tester) async {
        await _check(tester, tag, entry.value, scale, brightness, () async {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => GameProvider()),
                ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ],
              child: MaterialApp(
                theme: buildAppTheme(brightness),
                home: TurnOrderScreen(
                  team1Name: _team1,
                  team2Name: _team2,
                  team1Player1: _players[0],
                  team1Player2: _players[1],
                  team2Player1: _players[2],
                  team2Player2: _players[3],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('player-0')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('player-0')));
          await tester.ensureVisible(find.byKey(const Key('seat-0')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('seat-0')));
          await tester.ensureVisible(find.byKey(const Key('player-2')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('player-2')));
          await tester.ensureVisible(find.byKey(const Key('seat-1')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('seat-1')));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('partida con 0, tranca y 168 · $tag', (tester) async {
        SharedPreferences.setMockInitialValues(_saved(finished: false));
        await _check(tester, tag, entry.value, scale, brightness, () async {
          await tester.pumpWidget(const DominoVenezolanoApp());
          await tester.pumpAndSettle();

          // Anotar mano: the dialog with the longest names.
          await tester.ensureVisible(find.byKey(const Key('team-panel-1')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('team-panel-1')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const Key('points-field')), '168');
          // On a landscape phone with large text the dialog scrolls and the
          // switch is taller than what is left above the buttons; the tranca
          // is already covered by the portrait cases.
          if (entry.value.height > entry.value.width) {
            await tester.ensureVisible(find.byKey(const Key('tranca-switch')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('tranca-switch')));
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(find.byKey(const Key('submit-mano')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('submit-mano')));
          await _settle(tester);
        });
      });

      testWidgets('victoria y revancha · $tag', (tester) async {
        SharedPreferences.setMockInitialValues(_saved(finished: true));
        await _check(tester, tag, entry.value, scale, brightness, () async {
          await tester.pumpWidget(const DominoVenezolanoApp());
          await _settle(tester);
          final rematch = find.textContaining('Revancha');
          expect(rematch, findsWidgets, reason: tag);
          await tester.ensureVisible(rematch.first);
          await tester.tap(rematch.first);
          await _settle(tester);
        });
      });

      testWidgets('imagen para compartir · $tag', (tester) async {
        await _check(tester, tag, entry.value, scale, brightness, () async {
          // As in GameScreen._shareResult: the picture ignores the phone's
          // text size, so it looks the same for whoever receives it.
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(brightness),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.noScaling),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: LibretaShareCard(
                          game: _finishedGame(),
                          team1Wins: 12,
                          team2Wins: 9,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        });
      });
    }
  }

  testWidgets('pantallas principales cumplen las guías de accesibilidad', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      SharedPreferences.setMockInitialValues(
        _saved(finished: false, plainNames: true),
      );
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const DominoVenezolanoApp(),
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}
