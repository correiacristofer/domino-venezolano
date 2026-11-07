// Store screenshots and the Play feature graphic, rendered from the real app
// with sample data:
//
//   flutter test tool/store/render_store_assets_test.dart
//
// Output: store/screenshots/{appstore,play}/NN_*.png and
// store/play/feature_graphic.png.

// It is a test run by `flutter test`, just kept outside test/ so the normal
// suite does not regenerate store assets.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';

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

import '../brand/brand_mark.dart';
import '../brand/render_helpers.dart';

/// Logical size of the phone the app is drawn on inside each frame.
const _phone = Size(390, 844);

/// Store canvases: logical size and pixel ratio giving the exact pixels each
/// store asks for (App Store 6.9" iPhone 1320x2868, Play phone 1080x1920).
const _targets = {
  'appstore': (Size(440, 956), 3.0),
  'play': (Size(360, 640), 3.0),
};

const _yellow = Color(0xFFFFCC00);

// ---------------------------------------------------------------- sample data

Map<String, Object> _round(int losing, int points, int t1, int t2,
        {bool tranca = false}) =>
    {
      'losingTeamIndex': losing,
      'points': points,
      'timestamp': '2026-11-07T21:00:00.000',
      'isTranca': tranca,
      'team1Total': t1,
      'team2Total': t2,
    };

final _midGame = [
  _round(1, 18, 18, 0),
  _round(0, 25, 18, 25),
  _round(1, 31, 49, 25, tranca: true),
  _round(0, 22, 49, 47),
  _round(1, 29, 78, 47),
  _round(0, 17, 78, 64),
];

final _finished = [..._midGame, _round(1, 26, 104, 64)];

Map<String, Object> _prefs(List<Map<String, Object>> rounds,
        {int wins1 = 2, int wins2 = 1, String theme = 'light'}) =>
    {
      'theme_mode': theme,
      'saved_team1_wins': wins1,
      'saved_team2_wins': wins2,
      'saved_game': jsonEncode({
        'team1Name': 'Los Panas',
        'team2Name': 'Los Chamos',
        'team1Player1': 'Ana',
        'team1Player2': 'Luis',
        'team2Player1': 'Beto',
        'team2Player2': 'Mari',
        'rounds': rounds,
        'playingOrder': [0, 2, 1, 3],
        'currentTurnIndex': rounds.length % 4,
      }),
    };

Game _gameFrom(List<Map<String, Object>> rounds) => Game(
      team1Name: 'Los Panas',
      team2Name: 'Los Chamos',
      team1Player1: 'Ana',
      team1Player2: 'Luis',
      team2Player1: 'Beto',
      team2Player2: 'Mari',
      rounds: rounds.map(Round.fromJson).toList(),
      playingOrder: const [0, 2, 1, 3],
    );

// ---------------------------------------------------------------- frame

/// Marketing frame: headline on top, the app drawn on a phone-shaped panel.
class _Frame extends StatelessWidget {
  final String headline;
  final Widget screen;

  const _Frame({required this.headline, required this.screen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1712), Color(0xFF050505)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(w * 0.07, w * 0.09, w * 0.07, 0),
        child: Column(
          children: [
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.078,
                height: 1.15,
                color: Colors.white,
              ),
            ),
            SizedBox(height: w * 0.04),
            Container(
              width: w * 0.28,
              height: w * 0.012,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(w),
                gradient: const LinearGradient(
                  colors: [
                    BrandMarkPainter.yellow,
                    BrandMarkPainter.yellow,
                    BrandMarkPainter.blue,
                    BrandMarkPainter.blue,
                    BrandMarkPainter.red,
                    BrandMarkPainter.red,
                  ],
                  stops: [0, 1 / 3, 1 / 3, 2 / 3, 2 / 3, 1],
                ),
              ),
            ),
            SizedBox(height: w * 0.06),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: AspectRatio(
                  aspectRatio: _phone.width / _phone.height,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(w * 0.07),
                      border: Border.all(
                        color: const Color(0xFF3A352C),
                        width: w * 0.012,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(w * 0.058),
                      child: FittedBox(
                        child: SizedBox.fromSize(
                          size: _phone,
                          child: MediaQuery(
                            data: const MediaQueryData(size: _phone),
                            child: screen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------- shots

typedef _Setup = Future<void> Function(WidgetTester tester);

class _Shot {
  final String file;
  final String headline;
  final Map<String, Object> prefs;
  final Widget Function() screen;
  final _Setup? setup;

  const _Shot(this.file, this.headline, this.prefs, this.screen, [this.setup]);
}

Widget _turnOrderScreen() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        home: const TurnOrderScreen(
          team1Name: 'Los Panas',
          team2Name: 'Los Chamos',
          team1Player1: 'Ana',
          team1Player2: 'Luis',
          team2Player1: 'Beto',
          team2Player2: 'Mari',
          initialPlayingOrder: [0, 2, 1, 3],
        ),
      ),
    );

Widget _shareCard() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(
        backgroundColor: const Color(0xFFEDE6DA),
        body: Center(
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: FittedBox(
              child: LibretaShareCard(
                game: _gameFrom(_finished),
                team1Wins: 3,
                team2Wins: 1,
              ),
            ),
          ),
        ),
      ),
    );

final _shots = [
  _Shot('01_libreta', 'Anota cada mano\nen segundos', _prefs(_midGame),
      () => const DominoVenezolanoApp()),
  _Shot(
    '02_tranca',
    '¿Se trancó?\nMárcalo y sigue',
    _prefs(_midGame, theme: 'dark'),
    () => const DominoVenezolanoApp(),
    (tester) async {
      await tester.tap(find.byKey(const Key('team-panel-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('points-field')), '23');
      await tester.tap(find.byKey(const Key('tranca-switch')));
      await tester.pumpAndSettle();
    },
  ),
  _Shot('03_mesa', 'Sienta a cada uno\ncomo en la mesa', const {},
      _turnOrderScreen),
  _Shot(
    '04_victoria',
    '¡Dominó!\nY a pedir la revancha',
    _prefs(_finished, wins1: 3, wins2: 1),
    () => const DominoVenezolanoApp(),
    (tester) async {
      // Let the confetti spread a bit before taking the picture.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    },
  ),
  _Shot('05_compartir', 'Comparte la libreta\ncon tu grupo', const {},
      _shareCard),
];

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  for (final target in _targets.entries) {
    for (final shot in _shots) {
      testWidgets('${target.key} ${shot.file}', (tester) async {
        SharedPreferences.setMockInitialValues(shot.prefs);
        final (size, ratio) = target.value;
        setSurface(tester, size, pixelRatio: ratio);
        addTearDown(tester.view.reset);

        final key = GlobalKey();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: _Frame(headline: shot.headline, screen: shot.screen()),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        if (shot.setup != null) {
          await shot.setup!(tester);
        } else {
          await tester.pumpAndSettle();
        }

        await capturePng(
          tester,
          key,
          'store/screenshots/${target.key}/${shot.file}.png',
          pixelRatio: ratio,
        );
        // Drop the tree (and its timers) before the next shot.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  }

  testWidgets('play feature graphic', (tester) async {
    await renderPng(
      tester,
      Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 380,
              child: CustomPaint(painter: BrandMarkPainter()),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dominó\nVenezolano',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w900,
                      fontSize: 66,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'La libreta del dominó criollo',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 30,
                      color: _yellow,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 220,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          BrandMarkPainter.yellow,
                          BrandMarkPainter.yellow,
                          BrandMarkPainter.blue,
                          BrandMarkPainter.blue,
                          BrandMarkPainter.red,
                          BrandMarkPainter.red,
                        ],
                        stops: [0, 1 / 3, 1 / 3, 2 / 3, 2 / 3, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const Size(1024, 500),
      'store/play/feature_graphic.png',
    );
  });
}
