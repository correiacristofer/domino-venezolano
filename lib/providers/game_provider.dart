import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';
import '../models/round.dart';
import '../utils/venezuelan_phrases.dart';

class GameProvider extends ChangeNotifier {
  Game? _currentGame;
  bool _isRestoring = true;

  // Match scoreboard (revanchas)
  int _team1Wins = 0;
  int _team2Wins = 0;

  Game? get currentGame => _currentGame;
  bool get hasGame => _currentGame != null;
  bool get isRestoring => _isRestoring;
  int get team1Wins => _team1Wins;
  int get team2Wins => _team2Wins;

  // Backwards-compatible API: delegates to VenezuelanPhrases
  String getRandomPhrase() => VenezuelanPhrases.getRandomSplash();
  String getRandomVictory() => VenezuelanPhrases.getVictoryPhrase();
  String getManoPhrase(int points) => VenezuelanPhrases.getManoPhrase(points);
  String getTrancaPhrase() => VenezuelanPhrases.getTrancaPhrase();
  String getCloseToWinPhrase() => VenezuelanPhrases.getCloseToWinPhrase();
  String getLosingBigPhrase() => VenezuelanPhrases.getLosingBigPhrase();

  Future<void> startNewGame({
    required String team1Name,
    required String team2Name,
    required String team1Player1,
    required String team1Player2,
    required String team2Player1,
    required String team2Player2,
    required List<int> playingOrder,
  }) async {
    _currentGame = Game(
      team1Name: team1Name,
      team2Name: team2Name,
      team1Player1: team1Player1,
      team1Player2: team1Player2,
      team2Player1: team2Player1,
      team2Player2: team2Player2,
      playingOrder: List<int>.from(playingOrder),
      currentTurnIndex: 0,
    );

    // Reset match scoreboard for a brand new pairing
    _team1Wins = 0;
    _team2Wins = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_team1_name', team1Name);
    await prefs.setString('last_team2_name', team2Name);
    await prefs.setString('last_team1_player1', team1Player1);
    await prefs.setString('last_team1_player2', team1Player2);
    await prefs.setString('last_team2_player1', team2Player1);
    await prefs.setString('last_team2_player2', team2Player2);

    await _persistCurrentGame();
    notifyListeners();
  }

  Future<void> startRevancha({List<int>? playingOrder}) async {
    if (_currentGame == null) return;

    _currentGame = Game(
      team1Name: _currentGame!.team1Name,
      team2Name: _currentGame!.team2Name,
      team1Player1: _currentGame!.team1Player1,
      team1Player2: _currentGame!.team1Player2,
      team2Player1: _currentGame!.team2Player1,
      team2Player2: _currentGame!.team2Player2,
      playingOrder: List<int>.from(
        playingOrder ?? _currentGame!.playingOrder,
      ),
      currentTurnIndex: 0,
    );

    await _persistCurrentGame();
    notifyListeners();
  }

  /// Records a mano. Returns false when it was rejected (no game, partida
  /// already over or invalid input) so the UI never celebrates a mano that
  /// was not saved.
  bool addMano(int losingTeamIndex, int points, {bool isTranca = false}) {
    if (_currentGame == null ||
        _currentGame!.isGameOver ||
        losingTeamIndex < 0 ||
        losingTeamIndex > 1 ||
        points < 0 ||
        points > Game.maxManoPoints) {
      return false;
    }

    // Haptic feedback when a mano is anotated
    HapticFeedback.mediumImpact();

    final winningTeamIndex = losingTeamIndex == 0 ? 1 : 0;
    final currentTeam1Score = _currentGame!.team1Score;
    final currentTeam2Score = _currentGame!.team2Score;

    final newTeam1Score = winningTeamIndex == 0
        ? currentTeam1Score + points
        : currentTeam1Score;
    final newTeam2Score = winningTeamIndex == 1
        ? currentTeam2Score + points
        : currentTeam2Score;

    final newRound = Round(
      losingTeamIndex: losingTeamIndex,
      points: points,
      timestamp: DateTime.now(),
      isTranca: isTranca,
      team1Total: newTeam1Score,
      team2Total: newTeam2Score,
    );

    final newTurnIndex = (_currentGame!.currentTurnIndex + 1) % 4;

    _currentGame = _currentGame!.copyWith(
      rounds: [..._currentGame!.rounds, newRound],
      currentTurnIndex: newTurnIndex,
    );

    // If victory triggered now, register match win and stronger haptic
    final winner = _currentGame!.winningTeamIndex;
    if (winner != null) {
      if (winner == 0) {
        _team1Wins++;
      } else {
        _team2Wins++;
      }
      HapticFeedback.heavyImpact();
    }

    unawaited(_persistCurrentGame());
    notifyListeners();
    return true;
  }

  void undoLastMano() {
    if (_currentGame == null || _currentGame!.rounds.isEmpty) {
      return;
    }

    final previousWinner = _currentGame!.winningTeamIndex;

    final rounds = List<Round>.from(_currentGame!.rounds);
    rounds.removeLast();

    final newTurnIndex = (_currentGame!.currentTurnIndex - 1 + 4) % 4;

    final updated = _currentGame!.copyWith(
      rounds: rounds,
      currentTurnIndex: newTurnIndex,
    );

    // If we are undoing the winning mano, roll back the match scoreboard
    if (previousWinner != null && !updated.isGameOver) {
      if (previousWinner == 0 && _team1Wins > 0) {
        _team1Wins--;
      } else if (previousWinner == 1 && _team2Wins > 0) {
        _team2Wins--;
      }
    }

    _currentGame = updated;
    HapticFeedback.lightImpact();
    unawaited(_persistCurrentGame());
    notifyListeners();
  }

  Future<void> resetGame() async {
    _currentGame = null;
    _team1Wins = 0;
    _team2Wins = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_game');
    await prefs.remove('saved_team1_wins');
    await prefs.remove('saved_team2_wins');
    notifyListeners();
  }

  Future<Map<String, String>> getLastTeamNames() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'team1': prefs.getString('last_team1_name') ?? '',
      'team2': prefs.getString('last_team2_name') ?? '',
      'team1Player1': prefs.getString('last_team1_player1') ?? '',
      'team1Player2': prefs.getString('last_team1_player2') ?? '',
      'team2Player1': prefs.getString('last_team2_player1') ?? '',
      'team2Player2': prefs.getString('last_team2_player2') ?? '',
    };
  }

  // ---------------- Persistence ----------------

  Future<void> _persistCurrentGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentGame == null) {
        await prefs.remove('saved_game');
      } else {
        await prefs.setString('saved_game', jsonEncode(_currentGame!.toJson()));
      }
      await prefs.setInt('saved_team1_wins', _team1Wins);
      await prefs.setInt('saved_team2_wins', _team2Wins);
    } catch (e) {
      // Persistence is best-effort. Avoid crashing the UI.
      debugPrint('Failed to persist game: $e');
    }
  }

  Future<bool> tryRestoreGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_game');
      _team1Wins = prefs.getInt('saved_team1_wins') ?? 0;
      _team2Wins = prefs.getInt('saved_team2_wins') ?? 0;
      if (raw == null) return false;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _currentGame = Game.fromJson(map);
      return true;
    } catch (e) {
      debugPrint('Failed to restore game: $e');
      _currentGame = null;
      _team1Wins = 0;
      _team2Wins = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_game');
      await prefs.remove('saved_team1_wins');
      await prefs.remove('saved_team2_wins');
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }
}
