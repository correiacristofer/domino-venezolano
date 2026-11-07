<div align="center">

# 🎲 Domino Venezolano

### *La libreta digital del dominó venezolano*

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-lightgrey)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Made in Venezuela](https://img.shields.io/badge/Made%20in-Venezuela%20🇻🇪-FFCC00?labelColor=003893)]()

*Adiós lápiz, adiós servilleta. La libreta del dominó ahora cabe en tu bolsillo.*

</div>

---

## 🐷 ¿Qué es Domino Venezolano?

Una app minimalista para llevar la cuenta del **dominó criollo** (estilo venezolano, 2 vs 2, primero a 100 puntos). Sin anuncios, sin login, sin complicaciones. Solo tú, tu pana, los rivales y la libreta.

> *"¡Eso es puro talento, mi pana!"*

## ✨ Características

- 🎯 **Marcador automático** — anota la mano y la app calcula puntos del perdedor
- 🔒 **Trancas** — marca la mano como tranca y queda señalada en la libreta
- 🔄 **Mesa visual inteligente** — ubica a cada jugador y la app sienta automáticamente a su compañero al frente
- 📋 **La Libreta** — historial completo de manos con totales acumulados
- 🏆 **Marcador de revanchas** — ¿2-1? ¿3-2? La app te recuerda quién manda
- 💾 **Persistencia** — cierra la app, vuelve mañana, sigues donde quedaste
- 🎉 **Confeti de victoria** — porque ganar se celebra
- 📲 **Compartir resultado** — manda la libreta completa (marcador y todas las manos) como imagen por WhatsApp
- 🌗 **Tema claro / oscuro** — sigue el del teléfono hasta que eliges uno
- 📳 **Vibración háptica** — feedback al anotar puntos
- 🌶️ **Sabor criollo** — frases venezolanas integradas en la experiencia
- 🥚 **Easter egg** — toca el logo "LA LIBRETA" 3 veces seguidas durante una partida

## 📸 Capturas

> *Próximamente: screenshots reales del gameplay*

| Setup de equipos | Orden de juego | Partida en curso | Victoria |
|:---:|:---:|:---:|:---:|
| 📋 | 🔢 | 🎲 | 🏆 |

## 🚀 Instalación

### Como usuario
- Descarga el APK desde la pestaña [Releases](../../releases) e instálalo en tu Android
- O accede a la versión web (próximamente)

### Como desarrollador

```bash
# Requiere Flutter 3.35.4 / Dart 3.9.2
git clone https://github.com/correiacristofer/domino-venezolano.git
cd domino-venezolano
flutter pub get

# Web preview
flutter run -d chrome --release

# Android
flutter run -d android
flutter build apk --release
```

## 🏗️ Arquitectura

```
lib/
├── main.dart                  # Entry point + theme switching
├── models/
│   ├── game.dart              # Estado de la partida (con JSON serialization)
│   └── round.dart             # Una mano (con timestamp y totales)
├── providers/
│   ├── game_provider.dart     # Lógica de juego + persistencia + revanchas
│   └── theme_provider.dart    # Tema: sistema por defecto, claro/oscuro persistente
├── screens/
│   ├── team_setup_screen.dart # Configurar equipos y jugadores
│   ├── turn_order_screen.dart # Definir orden de juego con validación
│   ├── game_screen.dart       # La libreta + scoreboard
│   └── easter_egg_screen.dart # Sorpresa del autor
├── utils/
│   └── venezuelan_phrases.dart # Frases criollas por categoría
└── widgets/
    └── theme_toggle_button.dart
```

**Stack:**
- **State management**: Provider (`6.1.5+1`)
- **Persistencia**: `shared_preferences` (`2.5.3`)
- **Animaciones**: `confetti` (`^0.7.0`)
- **Compartir**: `share_plus` + `screenshot` + `path_provider`
- **Sonido**: clics del sistema (`SystemSound`), sin assets

## 📐 Reglas implementadas

1. Ganan el primer equipo en llegar a **100 puntos**
2. **Solo se cuentan las fichas del equipo perdedor**. La app acepta de 0 a 168 puntos por mano (todas las fichas de un dominó doble seis suman 168)
3. Las **trancas** se anotan activando «Fue tranca» al registrar la mano
4. El orden de juego no permite **dos jugadores del mismo equipo consecutivos**
5. Al ganar puedes pedir **revancha**, reconfigurar quién sale y conservar el marcador de partidas; una **nueva partida** resetea todo

## 🛣️ Roadmap

- [ ] Estadísticas históricas globales por jugador
- [ ] Modo "campeonato" multi-partida con copa final
- [ ] Sonidos custom (ficha cayendo, fanfarria al ganar)
- [ ] Versión iOS
- [ ] Modo offline-first 100% (ya casi)
- [ ] i18n (inglés y otros dialectos hispanos del dominó)

## 👨‍💻 Autor

**Cristofer Correia** — CEO de [GobernAI](https://gobernai.com), y según el easter egg de esta app, *"el mejor jugador de dominó de Venezuela y probablemente del mundo"*.

- [GitHub](https://github.com/correiacristofer)

## 📄 Licencia

MIT © 2025 Cristofer Correia — ver [LICENSE](LICENSE).

---

<div align="center">

**¿Te sirvió? Dale ⭐ al repo y compártelo con tu pana del dominó.**

*Que viva Venezuela, carajo.* 🇻🇪

</div>
