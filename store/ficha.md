# Ficha de tienda · Domino Venezolano 1.0.0

Textos listos para copiar en Play Console y App Store Connect. Idioma
principal: español (Latinoamérica en Play, `es-419`; España y México en App
Store). Los límites de caracteres están comprobados con
`node tool/store/check_ficha.js`.

Pendiente antes de publicar: sustituir `[CORREO PENDIENTE]` aquí y en `docs/`.

---

## Comunes

| Campo | Valor |
|---|---|
| Nombre en tiendas | Dominó Venezolano: La Libreta |
| Nombre bajo el icono | Domino Venezolano |
| Categoría | Entretenimiento (App Store: secundaria Utilidades) |
| Precio | Gratis, sin compras dentro de la app, sin anuncios |
| Web / soporte | https://correiacristofer.github.io/domino-venezolano/ |
| Política de privacidad | https://correiacristofer.github.io/domino-venezolano/privacidad.html |
| Correo de contacto | [CORREO PENDIENTE] |
| Identificador | com.correiacristofer.dominovenezolano |

## Google Play

### Título (máx. 30)
<!-- field:play_title max:30 -->
Dominó Venezolano: La Libreta
<!-- /field -->

### Descripción breve (máx. 80)
<!-- field:play_short max:80 -->
La libreta del dominó criollo: anota manos, trancas y revanchas sin papel.
<!-- /field -->

### Descripción completa (máx. 4000)
<!-- field:play_full max:4000 -->
Adiós lápiz, adiós servilleta. Domino Venezolano es la libreta digital para llevar la cuenta del dominó criollo: dos parejas, primero a 100.

CÓMO FUNCIONA
• Escribe los nombres de los equipos y de los cuatro jugadores.
• Siéntalos como están en la mesa: al ubicar a uno, su compañero queda al frente.
• Al terminar cada mano, toca el equipo que ganó y anota los puntos.
• La app suma, marca quién sale en la siguiente mano y avisa cuando hay ganador.

LO QUE TRAE
• La libreta completa, con cada mano y los totales acumulados.
• Trancas: marca la mano como tranca y queda señalada.
• Marcador de revanchas: 1-0, 2-1… la app recuerda quién manda.
• Borrar la última mano, con confirmación para no perder nada por error.
• Compartir la libreta como imagen con tu grupo.
• Tema claro y oscuro.
• Frases criollas para ponerle sabor a la mesa.
• La partida se guarda sola: cierra la app y sigue mañana.

SIN COMPLICACIONES
Sin cuentas, sin anuncios y sin conexión. Tus partidas se quedan en tu teléfono.

Hecha para el dominó venezolano y útil en cualquier mesa de parejas a 100 puntos.
<!-- /field -->

### Novedades de la versión
<!-- field:release_notes max:500 -->
Primera versión: libreta de manos, trancas, marcador de revanchas, compartir resultado y tema claro u oscuro.
<!-- /field -->

### Recursos gráficos
- Icono 512×512: `store/play/icon_512.png`
- Gráfico destacado 1024×500: `store/play/feature_graphic.png`
- Capturas de teléfono 1080×1920: `store/screenshots/play/01…05`

### Formularios de Play Console
- **Seguridad de los datos:** la app no recoge ni comparte datos de usuario.
  Respuesta: «No» a recopilación y a compartición.
- **Anuncios:** la app no contiene anuncios.
- **Clasificación de contenido (IARC):** sin violencia, sexo, lenguaje
  ofensivo, drogas ni apuestas; sin interacción entre usuarios; sin compras.
  Resultado esperado: PEGI 3 / Para todos.
- **Público objetivo:** mayores de 13 años (evita los requisitos de apps
  dirigidas a niños; la app es apta para todos igualmente).
- **Acceso a la app:** no requiere inicio de sesión.

## App Store

### Nombre (máx. 30)
<!-- field:ios_name max:30 -->
Dominó Venezolano: La Libreta
<!-- /field -->

### Subtítulo (máx. 30)
<!-- field:ios_subtitle max:30 -->
Anotador de dominó criollo
<!-- /field -->

### Texto promocional (máx. 170)
<!-- field:ios_promo max:170 -->
La libreta del dominó criollo en tu bolsillo. Anota manos y trancas, lleva el marcador de revanchas y comparte el resultado con tu grupo.
<!-- /field -->

### Palabras clave (máx. 100, separadas por comas, sin repetir el nombre)
<!-- field:ios_keywords max:100 -->
puntos,marcador,tranca,parejas,mesa,venezuela,cochina,partida,contador,juego,fichas,revancha
<!-- /field -->

### Descripción (máx. 4000)
Igual que la descripción completa de Google Play.

### Notas para la revisión de Apple
<!-- field:ios_review_notes max:4000 -->
La app no necesita cuenta ni conexión. Para probarla: escribe dos nombres de equipo y cuatro jugadores, toca CONTINUAR, toca un jugador y luego un asiento de la mesa (su compañero se coloca enfrente), repite con otro jugador del otro equipo y toca COMENZAR PARTIDA. Toca el panel de un equipo para anotar los puntos de la mano; al llegar a 100 aparece el resultado. Tocar tres veces seguidas el título LA LIBRETA muestra una pantalla de créditos del autor.
<!-- /field -->

### Recursos gráficos
- Icono 1024×1024 (sin transparencia): incluido en el binario.
- Capturas iPhone 6,9" 1320×2868: `store/screenshots/appstore/01…05`

### Privacidad y cumplimiento
- **Privacidad de la app:** «No se recopilan datos».
- **Cifrado:** `ITSAppUsesNonExemptEncryption = false` en Info.plist; no hay
  que responder la pregunta de exportación en cada versión.
- **Clasificación por edad:** 4+.
- **Dispositivos:** solo iPhone (en iPad funciona en modo compatibilidad).
