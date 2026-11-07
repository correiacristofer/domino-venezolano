import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/theme_toggle_button.dart';

class TurnOrderScreen extends StatefulWidget {
  final String team1Name;
  final String team2Name;
  final String team1Player1;
  final String team1Player2;
  final String team2Player1;
  final String team2Player2;
  final List<int>? initialPlayingOrder;
  final bool isRematch;

  const TurnOrderScreen({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.team1Player1,
    required this.team1Player2,
    required this.team2Player1,
    required this.team2Player2,
    this.initialPlayingOrder,
    this.isRematch = false,
  });

  @override
  State<TurnOrderScreen> createState() => _TurnOrderScreenState();
}

class _TurnOrderScreenState extends State<TurnOrderScreen> {
  late List<int?> playingOrder;
  int? selectedPlayerId;
  bool _isStarting = false;

  List<Map<String, Object>> get allPlayers => [
        {
          'name': widget.team1Player1,
          'team': widget.team1Name,
          'teamIndex': 0,
          'id': 0,
        },
        {
          'name': widget.team1Player2,
          'team': widget.team1Name,
          'teamIndex': 0,
          'id': 1,
        },
        {
          'name': widget.team2Player1,
          'team': widget.team2Name,
          'teamIndex': 1,
          'id': 2,
        },
        {
          'name': widget.team2Player2,
          'team': widget.team2Name,
          'teamIndex': 1,
          'id': 3,
        },
      ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPlayingOrder;
    final isValid = initial != null &&
        initial.length == 4 &&
        initial.toSet().length == 4 &&
        initial.every((id) => id >= 0 && id <= 3);
    playingOrder = isValid
        ? initial.map<int?>((id) => id).toList()
        : <int?>[null, null, null, null];
  }

  bool get isOrderComplete => playingOrder.every((slot) => slot != null);

  int _teamOf(int playerId) => playerId < 2 ? 0 : 1;

  int _teammateOf(int playerId) {
    if (playerId == 0) return 1;
    if (playerId == 1) return 0;
    if (playerId == 2) return 3;
    return 2;
  }

  int _oppositeOf(int position) => (position + 2) % 4;

  String? _validateOrder() {
    if (!isOrderComplete) return 'Debes ubicar a los dos equipos';

    for (int i = 0; i < 4; i++) {
      final current = playingOrder[i]!;
      final next = playingOrder[(i + 1) % 4]!;
      if (_teamOf(current) == _teamOf(next)) {
        return 'Los compañeros deben quedar uno frente al otro';
      }
    }
    return null;
  }

  void _selectPlayer(int playerId) {
    setState(() {
      selectedPlayerId = selectedPlayerId == playerId ? null : playerId;
    });
  }

  void _assignToPosition(int position) {
    final playerId = selectedPlayerId;
    if (playerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona primero un jugador')),
      );
      return;
    }

    final teammateId = _teammateOf(playerId);
    final oppositePosition = _oppositeOf(position);
    final nextOrder = List<int?>.from(playingOrder);

    final displaced = <int>[];
    for (final seat in [position, oppositePosition]) {
      final occupant = nextOrder[seat];
      if (occupant != null && _teamOf(occupant) != _teamOf(playerId)) {
        displaced.add(occupant);
      }
    }

    for (int i = 0; i < nextOrder.length; i++) {
      final occupant = nextOrder[i];
      if (occupant == playerId ||
          occupant == teammateId ||
          (occupant != null &&
              displaced.isNotEmpty &&
              _teamOf(occupant) == _teamOf(displaced.first))) {
        nextOrder[i] = null;
      }
    }

    nextOrder[position] = playerId;
    nextOrder[oppositePosition] = teammateId;

    if (displaced.isNotEmpty) {
      final displacedPlayer = displaced.first;
      final remainingPosition = nextOrder.indexOf(null);
      nextOrder[remainingPosition] = displacedPlayer;
      nextOrder[_oppositeOf(remainingPosition)] =
          _teammateOf(displacedPlayer);
    }

    setState(() {
      playingOrder = nextOrder;
      selectedPlayerId = null;
    });
  }

  void _clearTeamAtPosition(int position) {
    final playerId = playingOrder[position];
    if (playerId == null) return;
    final teammateId = _teammateOf(playerId);
    setState(() {
      for (int i = 0; i < playingOrder.length; i++) {
        if (playingOrder[i] == playerId || playingOrder[i] == teammateId) {
          playingOrder[i] = null;
        }
      }
      selectedPlayerId = playerId;
    });
  }

  Future<void> _startGame() async {
    final error = _validateOrder();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isStarting = true);
    final provider = context.read<GameProvider>();
    final order = playingOrder.cast<int>();

    if (widget.isRematch) {
      await provider.startRevancha(playingOrder: order);
    } else {
      await provider.startNewGame(
        team1Name: widget.team1Name,
        team2Name: widget.team2Name,
        team1Player1: widget.team1Player1,
        team1Player2: widget.team1Player2,
        team2Player1: widget.team2Player1,
        team2Player2: widget.team2Player2,
        playingOrder: order,
      );
    }

    if (!mounted) return;
    // The root route already shows the game once the provider has one, so
    // going back to it avoids stacking a second GameScreen (and a stale
    // setup screen) underneath.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isRematch ? 'Revancha' : 'Orden de juego',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isRematch
                    ? 'Los equipos se mantienen. Cambia quién sale y confirma cómo están sentados.'
                    : 'Ubica a cada jugador tal como está sentado en la mesa.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              _buildPlayersSelector(),
              const SizedBox(height: 22),
              Text(
                selectedPlayerId == null
                    ? 'Selecciona un jugador y luego toca su puesto'
                    : 'Ahora toca el puesto de ${allPlayers[selectedPlayerId!]['name']}',
                style: TextStyle(
                  color: selectedPlayerId == null
                      ? colors.onSurfaceVariant
                      : colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildTable(),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_outlined,
                        color: colors.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El compañero se coloca automáticamente al frente: 1.º con 3.º y 2.º con 4.º.',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('start-game'),
                onPressed: isOrderComplete && !_isStarting ? _startGame : null,
                icon: _isStarting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  isOrderComplete
                      ? widget.isRematch
                          ? 'COMENZAR REVANCHA'
                          : 'COMENZAR PARTIDA'
                      : 'UBICA A LOS 4 JUGADORES',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersSelector() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          _buildTeamRow(0, widget.team1Name),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: colors.outlineVariant),
          ),
          _buildTeamRow(1, widget.team2Name),
        ],
      ),
    );
  }

  Widget _buildTeamRow(int teamIndex, String teamName) {
    final colors = Theme.of(context).colorScheme;
    final playerIds = teamIndex == 0 ? const [0, 1] : const [2, 3];
    final teamColor = teamIndex == 0 ? colors.primary : colors.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final playerId in playerIds) ...[
              Expanded(child: _buildPlayerChip(playerId, teamColor)),
              if (playerId == playerIds.first) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerChip(int playerId, Color teamColor) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = selectedPlayerId == playerId;
    final seat = playingOrder.indexOf(playerId);
    final isAssigned = seat >= 0;

    return Material(
      color: isSelected
          ? teamColor.withValues(alpha: 0.18)
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('player-$playerId'),
        onTap: () => _selectPlayer(playerId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? teamColor : colors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAssigned ? Icons.event_seat : Icons.person_outline,
                size: 18,
                color: isSelected || isAssigned
                    ? teamColor
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  allPlayers[playerId]['name']! as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isAssigned)
                Text(
                  '${seat + 1}º',
                  style: TextStyle(
                    color: teamColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension = math.min(constraints.maxWidth, 360.0).toDouble();
        final seatWidth = math.min(112.0, dimension * 0.34).toDouble();
        const seatHeight = 76.0;
        final colors = Theme.of(context).colorScheme;

        return Center(
          child: SizedBox.square(
            dimension: dimension,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Narrow enough to leave a gap next to the side seats.
                Container(
                  width: dimension * 0.3,
                  height: dimension * 0.3,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.casino_outlined,
                          color: colors.onPrimaryContainer, size: 30),
                      const SizedBox(height: 4),
                      Text(
                        'MESA',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(Icons.rotate_right,
                          color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                          size: 18),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: (dimension - seatWidth) / 2,
                  child: _buildSeat(0, seatWidth, seatHeight),
                ),
                Positioned(
                  right: 0,
                  top: (dimension - seatHeight) / 2,
                  child: _buildSeat(1, seatWidth, seatHeight),
                ),
                Positioned(
                  bottom: 0,
                  left: (dimension - seatWidth) / 2,
                  child: _buildSeat(2, seatWidth, seatHeight),
                ),
                Positioned(
                  left: 0,
                  top: (dimension - seatHeight) / 2,
                  child: _buildSeat(3, seatWidth, seatHeight),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeat(int position, double width, double height) {
    final colors = Theme.of(context).colorScheme;
    final playerId = playingOrder[position];
    final player = playerId == null ? null : allPlayers[playerId];
    final teamColor = playerId == null
        ? colors.outline
        : _teamOf(playerId) == 0
            ? colors.primary
            : colors.tertiary;

    return Material(
      color: playerId == null
          ? colors.surfaceContainerHigh
          : teamColor.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('seat-$position'),
        onTap: () => _assignToPosition(position),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: playerId == null && selectedPlayerId != null
                  ? colors.primary
                  : teamColor,
              width: playerId == null ? 1.5 : 2,
            ),
          ),
          child: player == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: colors.onSurfaceVariant, size: 20),
                    Text(
                      '${position + 1}º${position == 0 ? ' · SALE' : ''}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${position + 1}º${position == 0 ? ' · SALE' : ''}',
                            style: TextStyle(
                              color: teamColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            player['name']! as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IconButton(
                        tooltip: 'Quitar equipo',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        iconSize: 15,
                        onPressed: () => _clearTeamAtPosition(position),
                        icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
