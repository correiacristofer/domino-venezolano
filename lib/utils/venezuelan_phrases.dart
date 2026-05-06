import 'dart:math';

/// Categorized Venezuelan phrases used across the app.
///
/// Sources: research on Venezuelan dominoes slang (Steemit "modismos y
/// venezolanismos usados en el juego de Dominó"), common Venezuelan
/// expressions ("mi pana", "chamo", "naguará", "molleja", "épale"),
/// and verified user feedback (we DO NOT use "se picó" — that's Cuban
/// slang; in Venezuela we say "se trancó").
class VenezuelanPhrases {
  static final Random _rng = Random();

  static String _pick(List<String> list) =>
      list[_rng.nextInt(list.length)];

  // ---------------------------------------------------------------------------
  // Splash / Header rotating phrases (shown on team setup screen)
  // ---------------------------------------------------------------------------
  static const List<String> splashPhrases = [
    '¡Eso es puro talento, mi pana!',
    '¡Se trancó el dominó, chamo!',
    '¡Guárdame esa ficha, vale!',
    '¡Qué molleja de jugada!',
    '¡Tá barato, dame dos!',
    '¡Ajá, y ahora qué hacemos?',
    '¡Naguará, qué mesa!',
    '¡Échale pichón a esa partida!',
    '¡A cuadrar la mesa, chamo!',
    '¡Saquen las piedras, llegó la hora!',
    '¡Esto va a estar bueno, mi pana!',
    '¡Épale, que arrancó la partida!',
  ];

  static String getRandomSplash() => _pick(splashPhrases);

  // ---------------------------------------------------------------------------
  // Phrase shown when a mano is anotated, based on points scored.
  // The "ranges" correspond to the points the LOSING team had.
  // ---------------------------------------------------------------------------

  /// 0-15 points: small win
  static const List<String> manoSmallPhrases = [
    '¡Apenitas, pero contó!',
    '¡Salieron raspados!',
    '¡Por un pelito, vale!',
    '¡Bueno, algo es algo!',
  ];

  /// 16-40 points: standard win
  static const List<String> manoMediumPhrases = [
    '¡Buena mano, mi pana!',
    '¡Cayó bonita esa!',
    '¡Eso se trabajó, chamo!',
    '¡Bien jugado, vale!',
  ];

  /// 41-60 points: big win
  static const List<String> manoBigPhrases = [
    '¡Manota, chamo!',
    '¡Eso fue una matanza!',
    '¡Qué molleja de mano!',
    '¡Naguará, qué pegada!',
  ];

  /// 61+ points: huge tranca
  static const List<String> manoHugePhrases = [
    '¡Vergación, los enterraron!',
    '¡Naguará, qué castigo!',
    '¡Eso fue una tranca con todo!',
    '¡Los hicieron polvo, chamo!',
  ];

  /// Picks a phrase based on the points scored in a single mano.
  static String getManoPhrase(int points) {
    if (points <= 15) return _pick(manoSmallPhrases);
    if (points <= 40) return _pick(manoMediumPhrases);
    if (points <= 60) return _pick(manoBigPhrases);
    return _pick(manoHugePhrases);
  }

  // ---------------------------------------------------------------------------
  // Phrase shown when a team is close to winning (75+ pts but not yet 100).
  // ---------------------------------------------------------------------------
  static const List<String> closeToWinPhrases = [
    '¡Ya casi se llevan la partida, mi pana!',
    '¡Están a una manito, chamo!',
    '¡Échale pichón, que ya casi!',
    '¡Huele a victoria, vale!',
  ];

  static String getCloseToWinPhrase() => _pick(closeToWinPhrases);

  // ---------------------------------------------------------------------------
  // Phrase shown when a team is significantly behind (40+ point gap).
  // Friendly trash-talk vibe ("mamadera de gallo").
  // ---------------------------------------------------------------------------
  static const List<String> losingBigPhrases = [
    '¡Esos están echando puro humo!',
    '¡Van pelando bola, chamo!',
    "¡Mente e' pollo los otros!",
    "¡Cara e' tabla, no se rinden!",
  ];

  static String getLosingBigPhrase() => _pick(losingBigPhrases);

  // ---------------------------------------------------------------------------
  // Victory messages (shown in winner dialog).
  // ---------------------------------------------------------------------------
  static const List<String> victoryPhrases = [
    '¡DOMINÓ! ¡GANARON ESTOS CACHACOS!',
    '¡Eso es juego, mano!',
    '¡Que viva Venezuela, carajo!',
    '¡Naguará, qué partidón!',
    '¡Se la comieron, mi pana!',
    '¡Dominaron la mesa, chamos!',
    '¡Eso es talento criollo, vale!',
    '¡A celebrar con cervecita fría!',
  ];

  static String getVictoryPhrase() => _pick(victoryPhrases);

  // ---------------------------------------------------------------------------
  // Tranca-specific phrases (when a hand ends without anyone dominating).
  // ---------------------------------------------------------------------------
  static const List<String> trancaPhrases = [
    '¡Se trancó esto, vale!',
    '¡Quedó cerrada la mano!',
    '¡Tranca limpia, chamo!',
  ];

  static String getTrancaPhrase() => _pick(trancaPhrases);
}
