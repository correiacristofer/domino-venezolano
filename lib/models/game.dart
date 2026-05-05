import 'round.dart';

class Game {
  final String team1Name;
  final String team2Name;
  final String team1Player1;
  final String team1Player2;
  final String team2Player1;
  final String team2Player2;
  final List<Round> rounds;
  final List<int> playingOrder; // [0-3] representing player IDs in order
  final int currentTurnIndex; // Index in playingOrder (0-3)

  Game({
    required this.team1Name,
    required this.team2Name,
    required this.team1Player1,
    required this.team1Player2,
    required this.team2Player1,
    required this.team2Player2,
    List<Round>? rounds,
    required this.playingOrder,
    this.currentTurnIndex = 0,
  }) : rounds = rounds ?? [];

  int get team1Score {
    return rounds
        .where((round) => round.losingTeamIndex == 1)
        .fold(0, (sum, round) => sum + round.points);
  }

  int get team2Score {
    return rounds
        .where((round) => round.losingTeamIndex == 0)
        .fold(0, (sum, round) => sum + round.points);
  }

  bool get isGameOver {
    return team1Score >= 100 || team2Score >= 100;
  }

  String? get winner {
    if (!isGameOver) return null;
    return team1Score >= 100 ? team1Name : team2Name;
  }

  Map<String, dynamic> _getPlayerInfo(int playerId) {
    switch (playerId) {
      case 0:
        return {'name': team1Player1, 'team': team1Name, 'teamIndex': 0, 'playerIndex': 0};
      case 1:
        return {'name': team1Player2, 'team': team1Name, 'teamIndex': 0, 'playerIndex': 1};
      case 2:
        return {'name': team2Player1, 'team': team2Name, 'teamIndex': 1, 'playerIndex': 0};
      case 3:
        return {'name': team2Player2, 'team': team2Name, 'teamIndex': 1, 'playerIndex': 1};
      default:
        return {'name': '', 'team': '', 'teamIndex': 0, 'playerIndex': 0};
    }
  }

  String playerNameAt(int orderIndex) {
    final playerId = playingOrder[orderIndex];
    return _getPlayerInfo(playerId)['name'] as String;
  }

  String teamNameAt(int orderIndex) {
    final playerId = playingOrder[orderIndex];
    return _getPlayerInfo(playerId)['team'] as String;
  }

  int teamIndexAt(int orderIndex) {
    final playerId = playingOrder[orderIndex];
    return _getPlayerInfo(playerId)['teamIndex'] as int;
  }

  String get nextPlayerName => playerNameAt(currentTurnIndex);
  String get nextTeamName => teamNameAt(currentTurnIndex);
  int get nextTurnTeam => teamIndexAt(currentTurnIndex);

  int get nextTurnPlayer {
    final playerId = playingOrder[currentTurnIndex];
    return _getPlayerInfo(playerId)['playerIndex'] as int;
  }

  Game copyWith({
    String? team1Name,
    String? team2Name,
    String? team1Player1,
    String? team1Player2,
    String? team2Player1,
    String? team2Player2,
    List<Round>? rounds,
    List<int>? playingOrder,
    int? currentTurnIndex,
  }) {
    return Game(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Player1: team1Player1 ?? this.team1Player1,
      team1Player2: team1Player2 ?? this.team1Player2,
      team2Player1: team2Player1 ?? this.team2Player1,
      team2Player2: team2Player2 ?? this.team2Player2,
      rounds: rounds ?? this.rounds,
      playingOrder: playingOrder ?? this.playingOrder,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team1Name': team1Name,
      'team2Name': team2Name,
      'team1Player1': team1Player1,
      'team1Player2': team1Player2,
      'team2Player1': team2Player1,
      'team2Player2': team2Player2,
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'playingOrder': playingOrder,
      'currentTurnIndex': currentTurnIndex,
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      team1Name: json['team1Name'] as String,
      team2Name: json['team2Name'] as String,
      team1Player1: json['team1Player1'] as String,
      team1Player2: json['team1Player2'] as String,
      team2Player1: json['team2Player1'] as String,
      team2Player2: json['team2Player2'] as String,
      rounds: (json['rounds'] as List<dynamic>)
          .map((r) => Round.fromJson(r as Map<String, dynamic>))
          .toList(),
      playingOrder: (json['playingOrder'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      currentTurnIndex: json['currentTurnIndex'] as int? ?? 0,
    );
  }
}
