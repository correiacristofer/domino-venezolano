import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:domino_venezolano/models/game.dart';
import 'package:domino_venezolano/providers/game_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Invalid saved seating falls back to a valid alternating order', () {
    final game = Game.fromJson({
      'team1Name': 'Equipo 1',
      'team2Name': 'Equipo 2',
      'team1Player1': 'A',
      'team1Player2': 'B',
      'team2Player1': 'C',
      'team2Player2': 'D',
      'rounds': <Object>[],
      'playingOrder': [0, 1, 2, 3],
      'currentTurnIndex': 99,
    });

    expect(game.playingOrder, [0, 2, 1, 3]);
    expect(game.currentTurnIndex, 0);
  });

  test('Rematch keeps the teams but accepts a newly configured order',
      () async {
    final provider = GameProvider();
    await provider.startNewGame(
      team1Name: 'Equipo 1',
      team2Name: 'Equipo 2',
      team1Player1: 'A',
      team1Player2: 'B',
      team2Player1: 'C',
      team2Player2: 'D',
      playingOrder: [0, 2, 1, 3],
    );
    await provider.startRevancha(playingOrder: [2, 0, 3, 1]);

    expect(provider.currentGame?.team1Name, 'Equipo 1');
    expect(provider.currentGame?.team2Name, 'Equipo 2');
    expect(provider.currentGame?.rounds, isEmpty);
    expect(provider.currentGame?.playingOrder, [2, 0, 3, 1]);
    expect(provider.isProcessing, isFalse);
  });
}
