# Cómo publicar Domino Venezolano

La app se distribuye **gratis**, sin tiendas:

- **Android:** APK firmado en GitHub Releases.
- **iPhone:** versión web en GitHub Pages, que se añade a la pantalla de inicio
  desde Safari.
- **Página de descarga:** https://correiacristofer.github.io/domino-venezolano/
  (privacidad en `/privacidad.html`, app web en `/app/`).

Ningún secreto se escribe en el repositorio. Las tiendas quedan documentadas
más abajo como opción de pago para el futuro.

## Distribución gratuita

1. **Fusiona los PR pendientes** en `main`. El workflow `Pages` publica la
   página de descarga y la versión web cada vez que cambia `main`. GitHub
   Pages ya está activado con origen «GitHub Actions».
2. **Correo de contacto:** sustituye `[CORREO PENDIENTE]` en
   `docs/index.html` y `docs/privacidad.html`.
3. **Clave de firma (una sola vez).** Todas las versiones del APK deben ir
   firmadas con la misma clave; si no, Android no deja instalar una
   actualización encima de la anterior. Instala un JDK 17
   (`winget install EclipseAdoptium.Temurin.17.JDK`) y ejecuta:
   ```
   powershell -ExecutionPolicy Bypass -File tool\release\crear_clave_android.ps1
   ```
   Elige una contraseña, responde `s` para cargarla en GitHub y guarda el
   `.jks` y la contraseña en tu gestor de contraseñas.
4. **Publicar una versión:** crea y sube una etiqueta.
   ```
   git tag v1.0.0
   git push origin v1.0.0
   ```
   El workflow `Release` compila el APK firmado y crea la Release
   `v1.0.0` con `domino-venezolano.apk`. El botón de la página de descarga
   apunta siempre a la última versión.
5. **Versiones siguientes:** sube `version:` en `pubspec.yaml` si quieres y
   crea la etiqueta nueva (`v1.0.1`, `v1.1.0`…). La versión visible sale de
   la etiqueta.

**Aviso para 2027:** Google exigirá verificar al desarrollador también para
apps instaladas fuera de Play. Desde el 30-sep-2026 ya se aplica en Brasil,
Indonesia, Singapur y Tailandia; en 2027 llegará al resto. Instalar apps sin
verificar seguirá siendo posible con un paso extra, y la verificación para
distribuir a cualquiera cuesta 25 USD (lo mismo que Play). Si llega ese
momento, compensa más publicar en Google Play.

## Opcional (de pago): Google Play

1. **Cuenta de desarrollador** en https://play.google.com/console (25 USD, pago
   único). Si es una cuenta **personal creada después del 13-nov-2023**, Google
   exige una prueba cerrada con al menos 12 testers durante 14 días seguidos
   antes de poder publicar en producción. Una cuenta de organización (necesita
   número D-U-N-S) no tiene ese requisito.
2. **Clave:** usa la misma de la distribución gratuita
   (`%USERPROFILE%\claves\domino-venezolano-upload.jks`). Al crear la app, en
   «Firma de apps» elige **subir tu propia clave** (esta misma) en lugar de que
   Google genere una. Así, quien instaló el APK de GitHub puede actualizar
   desde Play sin desinstalar ni perder sus partidas.
3. **Build firmado:** en GitHub, *Actions → Builds → Run workflow* sobre `main`.
   Descarga el artefacto `android-firmado` y quédate con `app-release.aab`.
4. En Play Console: crea la app («Dominó Venezolano: La Libreta», español
   Latinoamérica, app gratuita), deja activada la firma de apps de Google Play y
   sube el `.aab` a **Prueba interna** (o **Prueba cerrada** si te aplica la
   regla de los 12 testers).
5. Rellena la ficha y los formularios con `store/ficha.md` y los recursos de
   `store/play/` y `store/screenshots/play/`.
6. Cuando se cumplan los requisitos, promociona la versión a **Producción**.

## Opcional (de pago): App Store

1. **Apple Developer Program** en https://developer.apple.com/programs/
   (99 USD al año). Como persona física, el vendedor que aparece en la tienda
   es tu nombre.
2. **App en App Store Connect** (*Apps → +*): plataforma iOS, nombre «Dominó
   Venezolano: La Libreta», idioma principal español (México), bundle ID
   `com.correiacristofer.dominovenezolano` (si no aparece, créalo antes en
   *Certificates, Identifiers & Profiles → Identifiers*). Si el nombre está
   ocupado, App Store Connect lo dirá aquí; alternativa: «Domino Venezolano:
   Anotador».
3. **Clave de API** en *Users and Access → Integrations → App Store Connect
   API → Team Keys*, con rol **Admin** (el workflow la usa para crear el
   certificado y el perfil de distribución). Descarga el `.p8`: solo se puede
   descargar una vez.
4. **Secretos en GitHub** (desde la carpeta del repo, con `gh` autenticado):
   ```
   Get-Content AuthKey_XXXXXXXXXX.p8 -Raw | gh secret set APP_STORE_CONNECT_API_KEY
   gh secret set APP_STORE_CONNECT_KEY_ID
   gh secret set APP_STORE_CONNECT_ISSUER_ID
   gh secret set APPLE_TEAM_ID
   ```
   `gh secret set` sin valor te lo pide en la consola. El Key ID y el Issuer ID
   están en la página de claves; el Team ID, en *Membership details*.
5. **Build y subida:** *Actions → Builds → Run workflow*. El job `ios` archiva,
   firma y sube a TestFlight. Tras unos minutos de procesado, la versión
   aparece en App Store Connect.
6. Completa la ficha con `store/ficha.md` y las capturas de
   `store/screenshots/appstore/`, rellena «Privacidad de la app» con «No se
   recopilan datos» y envía a revisión.

## Versiones con tiendas

La misma etiqueta `v1.0.1` que publica el APK en GitHub hace que el workflow
`Builds` genere también el `.aab` firmado para Play y, si existen los secretos
de Apple, suba la versión de iOS a TestFlight.

## Regenerar iconos y capturas

```
flutter test tool/brand/render_brand_assets_test.dart
powershell -ExecutionPolicy Bypass -File tool\brand\flatten_ios_icons.ps1
flutter test tool/store/render_store_assets_test.dart
node tool/store/check_ficha.js
```
