import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/game.dart';
import '../models/round.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import 'team_setup_screen.dart';
import 'easter_egg_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _longPressCount = 0;
  DateTime? _lastPressTime;
  bool _victoryShown = false;

  late final ConfettiController _victoryConfetti;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScreenshotController _libretaController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _victoryConfetti = ConfettiController(duration: const Duration(seconds: 4));

    // If we restored a finished game, show the victory dialog after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      if (provider.currentGame?.isGameOver == true && !_victoryShown) {
        _victoryShown = true;
        _showVictoryDialog();
      }
    });
  }

  @override
  void dispose() {
    _victoryConfetti.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playClick() async {
    try {
      // System click is more reliable than bundling assets.
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {/* best-effort */}
  }

  Future<void> _playFanfare() async {
    try {
      // Triple click as a lightweight fanfare cue without external assets.
      for (int i = 0; i < 3; i++) {
        await SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 120));
      }
    } catch (_) {/* best-effort */}
  }

  void _handleLogoLongPress() {
    final now = DateTime.now();
    if (_lastPressTime != null &&
        now.difference(_lastPressTime!).inSeconds > 2) {
      _longPressCount = 0;
    }
    _lastPressTime = now;
    _longPressCount++;

    if (_longPressCount >= 3) {
      _longPressCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EasterEggScreen()),
      );
    }
  }

  void _showAddPointsDialog(int winningTeamIndex) {
    final provider = Provider.of<GameProvider>(context, listen: false);
    if (provider.isProcessing) return;

    final game = provider.currentGame!;
    final winningTeamName =
        winningTeamIndex == 0 ? game.team1Name : game.team2Name;
    final losingTeamIndex = winningTeamIndex == 0 ? 1 : 0;
    final losingTeamName =
        losingTeamIndex == 0 ? game.team1Name : game.team2Name;

    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events,
                    color: Colors.green.shade300, size: 28),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    winningTeamName,
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '¿Cuántos puntos ganaron?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '(puntos que tenía $losingTeamName)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 64,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.green.shade300,
                    width: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Rango válido: 0 - 84 puntos',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final points = int.tryParse(pointsController.text);
              if (points == null) {
                _showError(context, 'Ingresa un número válido');
                return;
              }
              if (points < 0 || points > 84) {
                _showError(context, 'Los puntos deben estar entre 0 y 84');
                return;
              }

              provider.addMano(losingTeamIndex, points, isTranca: false);
              _playClick();
              Navigator.pop(context);

              if (provider.currentGame!.isGameOver && !_victoryShown) {
                _victoryShown = true;
                _showVictoryDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text(
              'Anotar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareResult({required bool asImage}) async {
    final provider = context.read<GameProvider>();
    final game = provider.currentGame;
    if (game == null) return;

    final text = _buildShareText(game, provider);

    if (asImage) {
      try {
        final Uint8List? bytes = await _libretaController.capture(
          pixelRatio: 2.0,
          delay: const Duration(milliseconds: 100),
        );
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/domino_duel_libreta.png');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles(
            [XFile(file.path)],
            text: text,
            subject: 'Domino Duel - Libreta',
          );
          return;
        }
      } catch (e) {
        // fall back to text share
      }
    }
    await Share.share(text, subject: 'Domino Duel');
  }

  String _buildShareText(Game game, GameProvider provider) {
    final scoreLine =
        '${game.team1Name}: ${game.team1Score}  vs  ${game.team2Name}: ${game.team2Score}';
    final matchLine =
        'Partidas: ${game.team1Name} ${provider.team1Wins} - ${provider.team2Wins} ${game.team2Name}';
    final winner = game.winner;
    final header = winner != null
        ? '🏆 ¡$winner ganó la partida!'
        : '🎲 Domino Duel - Partida en curso';
    return '''$header

$scoreLine
$matchLine

Manos jugadas: ${game.rounds.length}

— Anotado con Domino Duel 🐷''';
  }

  void _showVictoryDialog() {
    final provider = Provider.of<GameProvider>(context, listen: false);
    final game = provider.currentGame!;
    final victoryMessage = provider.getRandomVictory();

    _victoryConfetti.play();
    _playFanfare();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          AlertDialog(
            backgroundColor: Colors.black,
            title: Column(
              children: [
                Icon(Icons.emoji_events,
                    size: 80, color: Colors.amber.shade400),
                const SizedBox(height: 16),
                Text(
                  victoryMessage,
                  style: TextStyle(
                    color: Colors.amber.shade400,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ganador: ${game.winner}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${game.team1Name}: ${game.team1Score}',
                        style: TextStyle(
                          color: game.team1Score >= 100
                              ? Colors.green
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${game.team2Name}: ${game.team2Score}',
                        style: TextStyle(
                          color: game.team2Score >= 100
                              ? Colors.green
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Match scoreboard
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Partidas: ${provider.team1Wins} - ${provider.team2Wins}',
                    style: TextStyle(
                      color: Colors.amber.shade300,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _shareResult(asImage: false),
                  icon: const Icon(Icons.share, color: Colors.white70),
                  label: const Text(
                    'Compartir resultado',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await provider.startRevancha();
                  _victoryShown = false;
                  navigator.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Revancha'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await provider.resetGame();
                  if (!mounted) return;
                  _victoryShown = false;
                  navigator.pop();
                  navigator.pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const TeamSetupScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Nueva Partida'),
              ),
            ],
          ),
          // Confetti overlay (top center)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _victoryConfetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.3,
              colors: const [
                Colors.yellow,
                Colors.amber,
                Colors.green,
                Colors.red,
                Colors.blue,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        final game = provider.currentGame;
        if (game == null) {
          return const TeamSetupScreen();
        }

        final team1Winning = game.team1Score > 75;
        final team2Winning = game.team2Score > 75;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, t, _) => IconButton(
                              tooltip: t.isDark ? 'Tema claro' : 'Tema oscuro',
                              onPressed: () => t.toggle(),
                              icon: Icon(
                                t.isDark
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleLogoLongPress,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.casino,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'LA LIBRETA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Compartir',
                            onPressed: () => _shareResult(asImage: true),
                            icon: const Icon(Icons.ios_share,
                                color: Colors.white70),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Match scoreboard pill
                      if (provider.team1Wins > 0 || provider.team2Wins > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Partidas: ${provider.team1Wins} - ${provider.team2Wins}',
                              style: TextStyle(
                                color: Colors.amber.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                      // Full turn order strip
                      _buildTurnOrderStrip(game),
                    ],
                  ),
                ),

                // Score panels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactTeamPanel(
                          game.team1Name,
                          game.team1Score,
                          team1Winning,
                          0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCompactTeamPanel(
                          game.team2Name,
                          game.team2Score,
                          team2Winning,
                          1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Round history (La Libreta) - wrapped in Screenshot for sharing
                Expanded(
                  child: Screenshot(
                    controller: _libretaController,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: game.rounds.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'La libreta está vacía\n¡Anota la primera mano!',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.5),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: game.rounds.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final reverseIndex =
                                    game.rounds.length - 1 - index;
                                final round = game.rounds[reverseIndex];
                                final manoNumber = reverseIndex + 1;
                                final losingTeamName = round.losingTeamIndex == 0
                                    ? game.team1Name
                                    : game.team2Name;
                                final winningTeamName = round.losingTeamIndex == 0
                                    ? game.team2Name
                                    : game.team1Name;

                                return _buildManoCard(
                                  manoNumber,
                                  round,
                                  losingTeamName,
                                  winningTeamName,
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: game.rounds.isEmpty || provider.isProcessing
                          ? null
                          : () {
                              provider.undoLastMano();
                            },
                      icon: const Icon(Icons.undo),
                      label: const Text('Borrar última'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledForegroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A1A),
                            title: const Text(
                              '¿Nueva Partida?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Se perderá el progreso actual.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final navigator = Navigator.of(context);
                                  await provider.resetGame();
                                  if (!mounted) return;
                                  navigator.pop();
                                  navigator.pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TeamSetupScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Nueva Partida'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nueva Partida'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTurnOrderStrip(Game game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(child: _buildTurnSlot(game, i)),
            if (i < 3)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTurnSlot(Game game, int orderIndex) {
    final isCurrent = orderIndex == game.currentTurnIndex;
    final teamIndex = game.teamIndexAt(orderIndex);
    final teamColor = teamIndex == 0
        ? Colors.lightBlue.shade300
        : Colors.orange.shade300;
    final name = game.playerNameAt(orderIndex);
    final positionLabel = ['1º', '2º', '3º', '4º'][orderIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.amber.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? Colors.amber
              : Colors.white.withValues(alpha: 0.05),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            positionLabel,
            style: TextStyle(
              color: isCurrent ? Colors.amber : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCurrent ? Colors.white : teamColor,
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTeamPanel(
    String teamName,
    int score,
    bool winning,
    int teamIndex,
  ) {
    return GestureDetector(
      onTap: () => _showAddPointsDialog(teamIndex),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: winning
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: winning ? Colors.green : Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              teamName.toUpperCase(),
              style: TextStyle(
                color: winning ? Colors.green.shade300 : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: TextStyle(
                color: winning ? Colors.green : Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'pts',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                winning ? Colors.green : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManoCard(
    int manoNumber,
    Round round,
    String losingTeamName,
    String winningTeamName,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$manoNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events,
                            color: Colors.green.shade300, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            winningTeamName,
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.close,
                            color: Colors.red.shade300, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            losingTeamName,
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '+${round.points}',
                      style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '${round.team1Total}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '-',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${round.team2Total}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
