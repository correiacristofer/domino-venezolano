import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';
import '../models/round.dart';
import '../utils/venezuelan_phrases.dart';

class GameProvider extends ChangeNotifier {
  Game? _currentGame;
  bool _isProcessing = false;

  // Match scoreboard (revanchas)
  int _team1Wins = 0;
  int _team2Wins = 0;

  Game? get currentGame => _currentGame;
  bool get hasGame => _currentGame != null;
  bool get isProcessing => _isProcessing;
  int get team1Wins => _team1Wins;
  int get team2Wins => _team2Wins;

  // Backwards-compatible API: delegates to VenezuelanPhrases
  String getRandomPhrase() => VenezuelanPhrases.getRandomSplash();
  String getRandomVictory() => VenezuelanPhrases.getVictoryPhrase();
  String getManoPhrase(int points) => VenezuelanPhrases.getManoPhrase(points);
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
      playingOrder: playingOrder,
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

  Future<void> startRevancha() async {
    if (_currentGame == null) return;

    _currentGame = Game(
      team1Name: _currentGame!.team1Name,
      team2Name: _currentGame!.team2Name,
      team1Player1: _currentGame!.team1Player1,
      team1Player2: _currentGame!.team1Player2,
      team2Player1: _currentGame!.team2Player1,
      team2Player2: _currentGame!.team2Player2,
      playingOrder: _currentGame!.playingOrder,
      currentTurnIndex: 0,
    );

    await _persistCurrentGame();
    notifyListeners();
  }

  void addMano(int losingTeamIndex, int points, {bool isTranca = false}) {
    if (_currentGame == null || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

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
    if (_currentGame!.isGameOver) {
      if (_currentGame!.team1Score >= 100) {
        _team1Wins++;
      } else {
        _team2Wins++;
      }
      HapticFeedback.heavyImpact();
    }

    _persistCurrentGame();

    Future.delayed(const Duration(seconds: 1), () {
      _isProcessing = false;
      notifyListeners();
    });

    notifyListeners();
  }

  void undoLastMano() {
    if (_currentGame == null ||
        _currentGame!.rounds.isEmpty ||
        _isProcessing) {
      return;
    }

    final wasGameOver = _currentGame!.isGameOver;

    final rounds = List<Round>.from(_currentGame!.rounds);
    rounds.removeLast();

    final newTurnIndex = (_currentGame!.currentTurnIndex - 1 + 4) % 4;

    final updated = _currentGame!.copyWith(
      rounds: rounds,
      currentTurnIndex: newTurnIndex,
    );

    // If we are undoing the winning mano, roll back the match scoreboard
    if (wasGameOver && !updated.isGameOver) {
      if (_currentGame!.team1Score >= 100 && _team1Wins > 0) {
        _team1Wins--;
      } else if (_currentGame!.team2Score >= 100 && _team2Wins > 0) {
        _team2Wins--;
      }
    }

    _currentGame = updated;
    HapticFeedback.lightImpact();
    _persistCurrentGame();
    notifyListeners();
  }

  Future<void> resetGame() async {
    _currentGame = null;
    _isProcessing = false;
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
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to restore game: $e');
      return false;
    }
  }
}
