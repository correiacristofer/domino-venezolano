import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/game.dart';
import '../models/round.dart';
import '../providers/game_provider.dart';
import '../widgets/theme_toggle_button.dart';
import 'easter_egg_screen.dart';
import 'turn_order_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _logoTapCount = 0;
  DateTime? _lastLogoTapTime;
  bool _victoryShown = false;

  final ScreenshotController _shareController = ScreenshotController();

  Color get _successColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.green.shade300
      : Colors.green.shade700;

  Color get _dangerColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.red.shade300
      : Colors.red.shade700;

  @override
  void initState() {
    super.initState();

    // If we restored a finished game, show the victory dialog after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<GameProvider>();
      if (provider.currentGame?.isGameOver == true && !_victoryShown) {
        _victoryShown = true;
        _showVictoryDialog();
      }
    });
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

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_lastLogoTapTime != null &&
        now.difference(_lastLogoTapTime!).inSeconds > 2) {
      _logoTapCount = 0;
    }
    _lastLogoTapTime = now;
    _logoTapCount++;

    if (_logoTapCount >= 3) {
      _logoTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EasterEggScreen()),
      );
    }
  }

  Future<void> _showAddPointsDialog(int winningTeamIndex) async {
    final provider = context.read<GameProvider>();
    final game = provider.currentGame;
    if (game == null || game.isGameOver) return;

    final winningTeamName =
        winningTeamIndex == 0 ? game.team1Name : game.team2Name;
    final losingTeamIndex = winningTeamIndex == 0 ? 1 : 0;
    final losingTeamName =
        losingTeamIndex == 0 ? game.team1Name : game.team2Name;

    final entry = await showDialog<_ManoEntry>(
      context: context,
      builder: (context) => _AddManoDialog(
        winningTeamName: winningTeamName,
        losingTeamName: losingTeamName,
        successColor: _successColor,
      ),
    );
    if (entry == null || !mounted) return;

    final saved = provider.addMano(
      losingTeamIndex,
      entry.points,
      isTranca: entry.isTranca,
    );
    if (!saved) return;
    _playClick();

    if (provider.currentGame!.isGameOver && !_victoryShown) {
      _victoryShown = true;
      _showVictoryDialog();
      return;
    }

    // Show contextual Venezuelan phrase based on points scored
    final messenger = ScaffoldMessenger.of(context);
    final phrase = entry.isTranca
        ? provider.getTrancaPhrase()
        : provider.getManoPhrase(entry.points);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          phrase,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // If a team just crossed the 75pt threshold, show extra hype
    final updated = provider.currentGame!;
    final winnerScore =
        winningTeamIndex == 0 ? updated.team1Score : updated.team2Score;
    final justCrossed75 = winnerScore >= 75 && winnerScore - entry.points < 75;
    if (justCrossed75) {
      Future.delayed(const Duration(milliseconds: 1900), () {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              provider.getCloseToWinPhrase(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.deepOrange.shade700,
            duration: const Duration(milliseconds: 2200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _confirmUndo(Game game) async {
    final last = game.rounds.last;
    final winningTeamName =
        last.losingTeamIndex == 0 ? game.team2Name : game.team1Name;
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar la mano ${game.rounds.length}?'),
        content: Text(
          'Se quitarán los +${last.points} puntos de $winningTeamName.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm-undo'),
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<GameProvider>().undoLastMano();
  }

  /// iPad presents the share sheet as a popover anchored to this rect;
  /// share_plus fails there without it.
  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareResult({
    required bool asImage,
    required BuildContext originContext,
  }) async {
    final provider = context.read<GameProvider>();
    final game = provider.currentGame;
    if (game == null) return;

    final text = _buildShareText(game, provider);
    final origin = _shareOrigin(originContext);

    if (asImage) {
      try {
        final Uint8List bytes = await _shareController.captureFromLongWidget(
          // Rendered off-screen, so it needs the theme, media query and text
          // direction handed over explicitly.
          InheritedTheme.captureAll(
            context,
            MediaQuery(
              data: MediaQuery.of(context),
              child: Directionality(
                textDirection: Directionality.of(context),
                child: Material(
                  child: _LibretaShareCard(
                    game: game,
                    team1Wins: provider.team1Wins,
                    team2Wins: provider.team2Wins,
                  ),
                ),
              ),
            ),
          ),
          context: context,
          pixelRatio: 2.0,
          delay: const Duration(milliseconds: 100),
        );
        await Share.shareXFiles(
          [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'domino_venezolano_libreta.png',
            ),
          ],
          text: text,
          subject: 'Domino Venezolano - Libreta',
          sharePositionOrigin: origin,
        );
        return;
      } catch (e) {
        // fall back to text share
        debugPrint('Image share failed, falling back to text: $e');
      }
    }
    await Share.share(
      text,
      subject: 'Domino Venezolano',
      sharePositionOrigin: origin,
    );
  }

  String _buildShareText(Game game, GameProvider provider) {
    final scoreLine =
        '${game.team1Name}: ${game.team1Score}  vs  ${game.team2Name}: ${game.team2Score}';
    final matchLine =
        'Partidas: ${game.team1Name} ${provider.team1Wins} - ${provider.team2Wins} ${game.team2Name}';
    final winner = game.winner;
    final header = winner != null
        ? '🏆 ¡$winner ganó la partida!'
        : '🎲 Domino Venezolano - Partida en curso';
    return '''$header

$scoreLine
$matchLine

Manos jugadas: ${game.rounds.length}

— Anotado con Domino Venezolano 🇻🇪''';
  }

  Future<void> _openRematchOrder(Game game, BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TurnOrderScreen(
          team1Name: game.team1Name,
          team2Name: game.team2Name,
          team1Player1: game.team1Player1,
          team1Player2: game.team1Player2,
          team2Player1: game.team2Player1,
          team2Player2: game.team2Player2,
          initialPlayingOrder: game.playingOrder,
          isRematch: true,
        ),
      ),
    );
    // Backing out of the rematch setup leaves the finished partida on screen;
    // bring the result back instead of letting the panels look playable.
    if (!mounted) return;
    if (context.read<GameProvider>().currentGame?.isGameOver == true) {
      _showVictoryDialog(celebrate: false);
    }
  }

  Future<void> _startNewGame(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    // The root router swaps to the setup screen once the game is cleared.
    await context.read<GameProvider>().resetGame();
  }

  void _showVictoryDialog({bool celebrate = true}) {
    final provider = context.read<GameProvider>();
    final game = provider.currentGame!;

    if (celebrate) _playFanfare();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VictoryDialog(
        game: game,
        team1Wins: provider.team1Wins,
        team2Wins: provider.team2Wins,
        victoryMessage: provider.getRandomVictory(),
        successColor: _successColor,
        celebrate: celebrate,
        onShare: (originContext) =>
            _shareResult(asImage: true, originContext: originContext),
        onRematch: () => _openRematchOrder(game, dialogContext),
        onNewGame: () => _startNewGame(dialogContext),
      ),
    );
  }

  void _confirmNewGame() {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '¿Nueva Partida?',
          style: TextStyle(color: colors.onSurface),
        ),
        content: Text(
          'Se perderá el progreso actual.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => _startNewGame(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            child: const Text('Nueva Partida'),
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
          // Only for the frame in which the root router swaps screens.
          return const Scaffold();
        }
        // A rematch reuses this screen, so arm the victory dialog again.
        if (!game.isGameOver) _victoryShown = false;

        final colors = Theme.of(context).colorScheme;

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final header = _buildHeader(game, provider);
                final scorePanels = _buildScorePanels(game);
                final libreta = _buildLibreta(game);

                // Phones in landscape and tablets: side by side, so the
                // libreta never gets squeezed to nothing.
                if (constraints.maxWidth > constraints.maxHeight) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(children: [header, scorePanels]),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: libreta,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    header,
                    scorePanels,
                    const SizedBox(height: 16),
                    Expanded(child: libreta),
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.18),
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
                      key: const Key('undo-mano'),
                      onPressed:
                          game.rounds.isEmpty ? null : () => _confirmUndo(game),
                      icon: const Icon(Icons.undo),
                      label: const Text('Borrar última'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: colors.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledForegroundColor:
                            colors.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _confirmNewGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nueva Partida'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
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

  Widget _buildHeader(Game game, GameProvider provider) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              ThemeToggleButton(color: colors.onSurfaceVariant),
              Expanded(
                child: GestureDetector(
                  onTap: _handleLogoTap,
                  // Scales down instead of overflowing on narrow phones or
                  // with large accessibility text.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.casino, color: colors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'LA LIBRETA',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: 'Compartir',
                  onPressed: () => _shareResult(
                    asImage: true,
                    originContext: buttonContext,
                  ),
                  icon: Icon(Icons.ios_share, color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Match scoreboard pill
          if (provider.team1Wins > 0 || provider.team2Wins > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: colors.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Partidas: ${provider.team1Wins} - ${provider.team2Wins}',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
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
    );
  }

  Widget _buildScorePanels(Game game) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactTeamPanel(
              game.team1Name,
              game.team1Score,
              game.team1Score >= 75,
              0,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCompactTeamPanel(
              game.team2Name,
              game.team2Score,
              game.team2Score >= 75,
              1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibreta(Game game) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: game.rounds.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 64,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'La libreta está vacía\n'
                      'Toca el equipo que ganó la mano para anotarla',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: game.rounds.length,
              reverse: true,
              itemBuilder: (context, index) {
                final reverseIndex = game.rounds.length - 1 - index;
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
    );
  }

  Widget _buildTurnOrderStrip(Game game) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(child: _buildTurnSlot(game, i)),
            if (i < 3)
              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.3),
                size: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTurnSlot(Game game, int orderIndex) {
    final colors = Theme.of(context).colorScheme;
    final isCurrent = orderIndex == game.currentTurnIndex;
    final teamIndex = game.teamIndexAt(orderIndex);
    final teamColor = teamIndex == 0
        ? colors.primary
        : colors.tertiary;
    final name = game.playerNameAt(orderIndex);
    // The highlighted player is the one who sale in the next mano.
    final positionLabel =
        isCurrent ? 'SALE' : ['1º', '2º', '3º', '4º'][orderIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? colors.primaryContainer.withValues(alpha: 0.7)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? colors.primary
              : colors.outlineVariant,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            positionLabel,
            style: TextStyle(
              color: isCurrent ? colors.primary : colors.onSurfaceVariant,
              fontSize: 10,
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
              color: isCurrent ? colors.onSurface : teamColor,
              fontSize: 12,
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
    final colors = Theme.of(context).colorScheme;
    final successColor = _successColor;
    return Semantics(
      button: true,
      label: 'Anotar mano ganada por $teamName',
      child: GestureDetector(
        key: Key('team-panel-$teamIndex'),
        onTap: () => _showAddPointsDialog(teamIndex),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: winning
                ? successColor.withValues(alpha: 0.1)
                : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: winning ? successColor : colors.outlineVariant,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                teamName.toUpperCase(),
                style: TextStyle(
                  color: winning ? successColor : colors.onSurface,
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
                  color: winning ? successColor : colors.onSurface,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'pts',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (score / Game.targetScore).clamp(0.0, 1.0),
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  winning ? successColor : colors.primary,
                ),
              ),
            ],
          ),
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
    final colors = Theme.of(context).colorScheme;
    final successColor = _successColor;
    final dangerColor = _dangerColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant,
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
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$manoNumber',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'M',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
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
                            color: successColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            winningTeamName,
                            style: TextStyle(
                              color: successColor,
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
                        Icon(Icons.close, color: dangerColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            losingTeamName,
                            style: TextStyle(
                              color: dangerColor,
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
                  color: successColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: successColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '+${round.points}',
                      style: TextStyle(
                        color: successColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (round.isTranca)
                      Text(
                        'TRANCA',
                        style: TextStyle(
                          color: successColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
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
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '${round.team1Total}',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '-',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${round.team2Total}',
                  style: TextStyle(
                    color: colors.onSurface,
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

/// Result of a finished partida. Owns its confetti so the animation can never
/// outlive (or be disposed under) the dialog that shows it.
class _VictoryDialog extends StatefulWidget {
  final Game game;
  final int team1Wins;
  final int team2Wins;
  final String victoryMessage;
  final Color successColor;
  final bool celebrate;
  final void Function(BuildContext originContext) onShare;
  final VoidCallback onRematch;
  final VoidCallback onNewGame;

  const _VictoryDialog({
    required this.game,
    required this.team1Wins,
    required this.team2Wins,
    required this.victoryMessage,
    required this.successColor,
    required this.celebrate,
    required this.onShare,
    required this.onRematch,
    required this.onNewGame,
  });

  @override
  State<_VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends State<_VictoryDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    if (widget.celebrate) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final colors = Theme.of(context).colorScheme;
    final successColor = widget.successColor;

    return Stack(
      children: [
        AlertDialog(
          title: Column(
            children: [
              Icon(Icons.emoji_events, size: 80, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                widget.victoryMessage,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ganador: ${game.winner}',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${game.team1Name}: ${game.team1Score}',
                        style: TextStyle(
                          color: game.winningTeamIndex == 0
                              ? successColor
                              : colors.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${game.team2Name}: ${game.team2Score}',
                        style: TextStyle(
                          color: game.winningTeamIndex == 1
                              ? successColor
                              : colors.onSurface,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Partidas: ${widget.team1Wins} - ${widget.team2Wins}',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (buttonContext) => TextButton.icon(
                    onPressed: () => widget.onShare(buttonContext),
                    icon: Icon(Icons.share, color: colors.onSurfaceVariant),
                    label: Text(
                      'Compartir resultado',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: widget.onRematch,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
              ),
              child: const Text('Revancha · elegir salida'),
            ),
            ElevatedButton(
              onPressed: widget.onNewGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: const Text('Nueva Partida'),
            ),
          ],
        ),
        // Confetti overlay (top center)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
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
    );
  }
}

/// What the user entered in the "anotar mano" dialog.
class _ManoEntry {
  final int points;
  final bool isTranca;

  const _ManoEntry(this.points, this.isTranca);
}

class _AddManoDialog extends StatefulWidget {
  final String winningTeamName;
  final String losingTeamName;
  final Color successColor;

  const _AddManoDialog({
    required this.winningTeamName,
    required this.losingTeamName,
    required this.successColor,
  });

  @override
  State<_AddManoDialog> createState() => _AddManoDialogState();
}

class _AddManoDialogState extends State<_AddManoDialog> {
  final _pointsController = TextEditingController();
  bool _isTranca = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    final points = int.tryParse(_pointsController.text.trim());
    if (points == null) {
      setState(() => _error = 'Ingresa un número válido');
      return;
    }
    if (points < 0 || points > Game.maxManoPoints) {
      setState(() =>
          _error = 'Los puntos deben estar entre 0 y ${Game.maxManoPoints}');
      return;
    }
    _submitted = true;
    Navigator.pop(context, _ManoEntry(points, _isTranca));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final successColor = widget.successColor;

    return AlertDialog(
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: successColor, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.winningTeamName,
                  style: TextStyle(
                    color: successColor,
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
              color: colors.onSurface,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _isTranca
                ? '(puntos que se anotan por la tranca)'
                : '(puntos que tenía ${widget.losingTeamName})',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('points-field'),
              controller: _pointsController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: successColor,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '0',
                errorText: _error,
                hintStyle: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.2),
                  fontSize: 64,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: successColor.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: successColor,
                    width: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('tranca-switch'),
              contentPadding: EdgeInsets.zero,
              value: _isTranca,
              onChanged: (value) => setState(() => _isTranca = value),
              title: const Text('Fue tranca'),
              subtitle: const Text('Nadie dominó: se trancó el juego'),
            ),
            const SizedBox(height: 8),
            Text(
              'Rango válido: 0 - ${Game.maxManoPoints} puntos',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
          ),
        ),
        ElevatedButton(
          key: const Key('submit-mano'),
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: successColor,
            foregroundColor: colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: const Text(
            'Anotar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Self-contained picture of the partida for sharing: score, revanchas and
/// every mano, not just the part of the libreta that fits on screen.
class _LibretaShareCard extends StatelessWidget {
  final Game game;
  final int team1Wins;
  final int team2Wins;

  const _LibretaShareCard({
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
