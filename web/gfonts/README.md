# Fuentes de respaldo de la versión web

La versión web dibuja el texto con Roboto (incluida en el build). Para los
caracteres que Roboto no tiene, como los emoji de los nombres o los símbolos
«→» y «🐷» de la primera pantalla, el motor de Flutter descarga por defecto
fuentes Noto desde Google (`fonts.gstatic.com`). Esta carpeta sirve esas
fuentes desde el propio sitio, para que la versión web no haga peticiones a
terceros, como dice la política de privacidad.

- `web/flutter_bootstrap.js` apunta el motor aquí (`fontFallbackBaseUrl`).
- Las rutas son las mismas que en Google Fonts, porque el motor las pide así.
- Solo están emoji, símbolos y matemáticas (20 archivos, 2,7 MB). Cada
  teléfono descarga únicamente los trozos que necesita. Otros alfabetos
  (chino, japonés, coreano...) no se sirven y se verían como cuadros.
- Licencia: SIL Open Font License 1.1 (`OFL-*.txt`).

Al actualizar Flutter, `test/web_fonts_test.dart` falla si el motor pide
versiones nuevas de estas fuentes. Para renovarlas, descarga cada ruta que
indique el test desde `https://fonts.gstatic.com/s/<ruta>` a esta carpeta y
borra la versión anterior.
