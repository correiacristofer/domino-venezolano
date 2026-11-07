import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:domino_venezolano/models/game.dart';
import 'package:domino_venezolano/providers/game_provider.dart';

Future<GameProvider> _newGame() async {
  final provider = GameProvider();
  await provider.startNewGame(
    team1Name: 'Los A',
    team2Name: 'Los B',
    team1Player1: 'Ana',
    team1Player2: 'Alex',
    team2Player1: 'Beto',
    team2Player2: 'Bea',
    playingOrder: [0, 2, 1, 3],
  );
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Haptics go through the platform channel; answer it like a device would.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  group('addMano', () {
    test('adds the points to the winning team and keeps running totals',
        () async {
      final provider = await _newGame();

      expect(provider.addMano(1, 30), isTrue); // Los A ganan 30
      expect(provider.addMano(0, 12), isTrue); // Los B ganan 12

      final game = provider.currentGame!;
      expect(game.team1Score, 30);
      expect(game.team2Score, 12);
      expect(game.rounds.map((r) => [r.team1Total, r.team2Total]), [
        [30, 0],
        [30, 12],
      ]);
    });

    test('passes the salida to the next player every mano', () async {
      final provider = await _newGame();

      for (final expected in [1, 2, 3, 0, 1]) {
        provider.addMano(1, 5);
        expect(provider.currentGame!.currentTurnIndex, expected);
      }
    });

    test('accepts any score a double-six set allows, tranca included',
        () async {
      final provider = await _newGame();

      // 107 is the highest score a mano closed by tranca can produce; the
      // old 0-84 limit rejected it.
      expect(provider.addMano(0, 107, isTranca: true), isTrue);
      expect(provider.currentGame!.rounds.last.isTranca, isTrue);
      expect(provider.currentGame!.team2Score, 107);

      final other = await _newGame();
      expect(other.addMano(1, Game.maxManoPoints), isTrue);
      expect(other.currentGame!.team1Score, 168);
    });

    test('rejects impossible input without touching the libreta', () async {
      final provider = await _newGame();

      expect(provider.addMano(1, Game.maxManoPoints + 1), isFalse);
      expect(provider.addMano(1, -1), isFalse);
      expect(provider.addMano(2, 10), isFalse);
      expect(provider.currentGame!.rounds, isEmpty);
    });

    test('closes the partida at 100 and counts the win once', () async {
      final provider = await _newGame();

      provider.addMano(1, 60);
      provider.addMano(1, 40);

      expect(provider.currentGame!.isGameOver, isTrue);
      expect(provider.currentGame!.winningTeamIndex, 0);
      expect(provider.currentGame!.winner, 'Los A');
      expect(provider.team1Wins, 1);
      expect(provider.team2Wins, 0);

      // Nothing else can be anotated on a finished partida.
      expect(provider.addMano(0, 20), isFalse);
      expect(provider.team1Wins, 1);
    });
  });

  group('undoLastMano', () {
    test('removes the last mano and gives the salida back', () async {
      final provider = await _newGame();
      provider.addMano(1, 25);
      provider.addMano(0, 10);

      provider.undoLastMano();

      final game = provider.currentGame!;
      expect(game.rounds, hasLength(1));
      expect(game.team2Score, 0);
      expect(game.currentTurnIndex, 1);
    });

    test('undoing the winning mano rolls back the revancha scoreboard',
        () async {
      final provider = await _newGame();
      provider.addMano(0, 70);
      provider.addMano(0, 30);
      expect(provider.team2Wins, 1);

      provider.undoLastMano();

      expect(provider.currentGame!.isGameOver, isFalse);
      expect(provider.team2Wins, 0);
    });

    test('does nothing on an empty libreta', () async {
      final provider = await _newGame();
      provider.undoLastMano();
      expect(provider.currentGame!.rounds, isEmpty);
      expect(provider.currentGame!.currentTurnIndex, 0);
    });
  });

  group('revanchas and new games', () {
    test('a revancha keeps the match scoreboard, a new game clears it',
        () async {
      final provider = await _newGame();
      provider.addMano(1, 100);
      expect(provider.team1Wins, 1);

      await provider.startRevancha();
      expect(provider.team1Wins, 1);
      expect(provider.currentGame!.rounds, isEmpty);

      await provider.startNewGame(
        team1Name: 'X',
        team2Name: 'Y',
        team1Player1: '1',
        team1Player2: '2',
        team2Player1: '3',
        team2Player2: '4',
        playingOrder: [0, 2, 1, 3],
      );
      expect(provider.team1Wins, 0);
      expect(provider.team2Wins, 0);
    });

    test('resetGame clears the saved partida', () async {
      final provider = await _newGame();
      provider.addMano(1, 20);

      await provider.resetGame();

      expect(provider.hasGame, isFalse);
      final restored = GameProvider();
      expect(await restored.tryRestoreGame(), isFalse);
    });
  });

  group('persistence', () {
    test('a restored partida keeps manos, trancas, turn and revanchas',
        () async {
      final provider = await _newGame();
      provider.addMano(1, 100);
      await provider.startRevancha(playingOrder: [2, 0, 3, 1]);
      provider.addMano(0, 33, isTranca: true);
      // addMano saves in the background; let it finish.
      await pumpEventQueue();

      final restored = GameProvider();
      expect(await restored.tryRestoreGame(), isTrue);

      final game = restored.currentGame!;
      expect(game.team2Score, 33);
      expect(game.rounds.single.isTranca, isTrue);
      expect(game.playingOrder, [2, 0, 3, 1]);
      expect(game.currentTurnIndex, 1);
      expect(restored.team1Wins, 1);
      expect(restored.isRestoring, isFalse);
    });

    test('a corrupt save is discarded instead of crashing', () async {
      SharedPreferences.setMockInitialValues({'saved_game': '{not json'});

      final provider = GameProvider();
      expect(await provider.tryRestoreGame(), isFalse);
      expect(provider.hasGame, isFalse);
      expect(provider.isRestoring, isFalse);
    });
  });
}
