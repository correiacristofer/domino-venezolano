import 'package:flutter/material.dart';

import '../models/game.dart';

/// Self-contained picture of the partida for sharing: score, revanchas and
/// every mano, not just the part of the libreta that fits on screen.
class LibretaShareCard extends StatelessWidget {
  final Game game;
  final int team1Wins;
  final int team2Wins;

  const LibretaShareCard({
    super.key,
    required this.game,
    required this.team1Wins,
    required this.team2Wins,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final winnerIndex = game.winningTeamIndex;

    Widget scoreBox(String name, int score, bool isWinner) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isWinner
                ? colors.primaryContainer
                : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isWinner ? colors.primary : colors.outlineVariant,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$score',
                style: TextStyle(
                  color: isWinner ? colors.primary : colors.onSurface,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 420,
      color: colors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino, color: colors.primary, size: 26),
              const SizedBox(width: 8),
              Text(
                'LA LIBRETA',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            winnerIndex == null
                ? 'Partida en curso'
                : '¡Ganó ${game.winner}!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: winnerIndex == null ? colors.onSurfaceVariant : colors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              scoreBox(game.team1Name, game.team1Score, winnerIndex == 0),
              const SizedBox(width: 12),
              scoreBox(game.team2Name, game.team2Score, winnerIndex == 1),
            ],
          ),
          if (team1Wins > 0 || team2Wins > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Partidas: $team1Wins - $team2Wins',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(color: colors.outlineVariant),
          if (game.rounds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Todavía no hay manos anotadas',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          for (int i = 0; i < game.rounds.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      game.rounds[i].losingTeamIndex == 0
                          ? game.team2Name
                          : game.team1Name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (game.rounds[i].isTranca)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'TRANCA',
                        style: TextStyle(
                          color: colors.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '+${game.rounds[i].points}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '${game.rounds[i].team1Total} - ${game.rounds[i].team2Total}',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Anotado con Domino Venezolano',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
