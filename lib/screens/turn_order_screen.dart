import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class TurnOrderScreen extends StatefulWidget {
  final String team1Name;
  final String team2Name;
  final String team1Player1;
  final String team1Player2;
  final String team2Player1;
  final String team2Player2;

  const TurnOrderScreen({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.team1Player1,
    required this.team1Player2,
    required this.team2Player1,
    required this.team2Player2,
  });

  @override
  State<TurnOrderScreen> createState() => _TurnOrderScreenState();
}

class _TurnOrderScreenState extends State<TurnOrderScreen> {
  // Store the playing order as indices (0-3), null means unassigned
  List<int?> playingOrder = [null, null, null, null];
  int? selectedPlayerId; // Currently selected player to assign

  List<Map<String, dynamic>> get allPlayers => [
        {
          'name': widget.team1Player1,
          'team': widget.team1Name,
          'teamIndex': 0,
          'playerIndex': 0,
          'id': 0,
        },
        {
          'name': widget.team1Player2,
          'team': widget.team1Name,
          'teamIndex': 0,
          'playerIndex': 1,
          'id': 1,
        },
        {
          'name': widget.team2Player1,
          'team': widget.team2Name,
          'teamIndex': 1,
          'playerIndex': 0,
          'id': 2,
        },
        {
          'name': widget.team2Player2,
          'team': widget.team2Name,
          'teamIndex': 1,
          'playerIndex': 1,
          'id': 3,
        },
      ];

  bool get isOrderComplete {
    return playingOrder.every((slot) => slot != null);
  }

  String? validateOrder() {
    if (!isOrderComplete) {
      return 'Debes asignar los 4 puestos';
    }

    // Check that no two consecutive players are from the same team
    for (int i = 0; i < 4; i++) {
      final currentPlayerId = playingOrder[i]!;
      final nextPlayerId = playingOrder[(i + 1) % 4]!;
      
      final currentPlayer = allPlayers[currentPlayerId];
      final nextPlayer = allPlayers[nextPlayerId];
      
      if (currentPlayer['teamIndex'] == nextPlayer['teamIndex']) {
        return 'No pueden jugar dos del mismo equipo seguidos.\n${currentPlayer['name']} y ${nextPlayer['name']} están consecutivos.';
      }
    }

    return null;
  }

  void _selectPlayer(int playerId) {
    setState(() {
      selectedPlayerId = playerId;
    });
  }

  void _assignToPosition(int position) {
    if (selectedPlayerId == null) return;
    
    setState(() {
      // Remove player from any previous position
      for (int i = 0; i < 4; i++) {
        if (playingOrder[i] == selectedPlayerId) {
          playingOrder[i] = null;
        }
      }
      // Assign to new position
      playingOrder[position] = selectedPlayerId;
      selectedPlayerId = null; // Deselect after assignment
    });
  }

  void _removeFromPosition(int position) {
    setState(() {
      playingOrder[position] = null;
    });
  }

  void _startGame() {
    final error = validateOrder();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final provider = Provider.of<GameProvider>(context, listen: false);

    provider.startNewGame(
      team1Name: widget.team1Name,
      team2Name: widget.team2Name,
      team1Player1: widget.team1Player1,
      team1Player2: widget.team1Player2,
      team2Player1: widget.team2Player1,
      team2Player2: widget.team2Player2,
      playingOrder: playingOrder.map((id) => id!).toList(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Title
              const Icon(
                Icons.swap_vert,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              const Text(
                'ORDEN DE JUEGO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '🐷 Define el orden: 1º, 2º, 3º y 4º',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Selecciona un jugador\n2. Haz click en una posición\n3. No pueden ir dos del mismo equipo seguidos',
                      style: TextStyle(
                        color: Colors.amber.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Position slots
              for (int pos = 0; pos < 4; pos++) ...[
                _buildPositionSlot(pos),
                if (pos < 3) const SizedBox(height: 12),
              ],

              const SizedBox(height: 30),

              // Available players
              const Text(
                'SELECCIONA JUGADOR',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Players grid
              for (int id = 0; id < 4; id++)
                if (!playingOrder.contains(id))
                  _buildAvailablePlayer(id),

              const SizedBox(height: 30),

              // Start button
              ElevatedButton(
                onPressed: isOrderComplete ? _startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade800,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  isOrderComplete ? '¡COMENZAR PARTIDA!' : 'COMPLETA EL ORDEN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionSlot(int position) {
    final playerId = playingOrder[position];
    final positionLabels = ['1º SALE', '2º', '3º', '4º'];

    return GestureDetector(
      onTap: () {
        if (playerId == null && selectedPlayerId != null) {
          _assignToPosition(position);
        }
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: playerId != null
              ? Colors.green.withValues(alpha: 0.15)
              : selectedPlayerId != null
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: playerId != null
                ? Colors.green
                : selectedPlayerId != null
                    ? Colors.amber
                    : Colors.white24,
            width: 2,
          ),
        ),
        child: playerId != null
            ? _buildAssignedPlayer(position, playerId)
            : Center(
                child: Text(
                  selectedPlayerId != null
                      ? 'Toca aquí para asignar → ${positionLabels[position]}'
                      : positionLabels[position],
                  style: TextStyle(
                    color: selectedPlayerId != null
                        ? Colors.amber.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }

  Widget _buildAssignedPlayer(int position, int playerId) {
    final player = allPlayers[playerId];
    final positionLabels = ['1º', '2º', '3º', '4º'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Position badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              positionLabels[position],
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  player['team'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () => _removeFromPosition(position),
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlayer(int playerId) {
    final player = allPlayers[playerId];
    final isSelected = selectedPlayerId == playerId;

    return GestureDetector(
      onTap: () => _selectPlayer(playerId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.amber
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.white24,
                  width: 2,
                ),
              ),
              child: Center(
                child: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.black,
                        size: 24,
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 24,
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player['team'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.amber.withValues(alpha: 0.7)
                          : Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              Icon(
                Icons.arrow_upward,
                color: Colors.amber,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
