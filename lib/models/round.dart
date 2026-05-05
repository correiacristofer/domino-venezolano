class Round {
  final int losingTeamIndex; // 0 or 1 - team that LOST the mano
  final int points; // Points the LOSING team had
  final DateTime timestamp;
  final bool isTranca; // Was this a blocked game?
  final int team1Total; // Running total for team 1 after this mano
  final int team2Total; // Running total for team 2 after this mano

  Round({
    required this.losingTeamIndex,
    required this.points,
    required this.timestamp,
    this.isTranca = false,
    required this.team1Total,
    required this.team2Total,
  });

  Map<String, dynamic> toJson() {
    return {
      'losingTeamIndex': losingTeamIndex,
      'points': points,
      'timestamp': timestamp.toIso8601String(),
      'isTranca': isTranca,
      'team1Total': team1Total,
      'team2Total': team2Total,
    };
  }

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      losingTeamIndex: json['losingTeamIndex'] as int,
      points: json['points'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isTranca: json['isTranca'] as bool? ?? false,
      team1Total: json['team1Total'] as int,
      team2Total: json['team2Total'] as int,
    );
  }
}
