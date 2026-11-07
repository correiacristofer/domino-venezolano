# Cómo publicar Domino Venezolano

Lo que ya está hecho en el repositorio: identificadores, iconos, capturas,
gráfico destacado, textos de la ficha (`store/ficha.md`), política de
privacidad y página de soporte (`docs/`), y el workflow `Builds` que compila
Android e iOS en cada PR.

Lo que solo puedes hacer tú: crear y pagar las cuentas de desarrollador,
generar las claves de firma y cargarlas como secretos. Ningún secreto se
escribe en el repositorio.

## 0. Antes de nada

1. Fusiona los PR pendientes en `main`.
2. Sustituye `[CORREO PENDIENTE]` en `docs/index.html`, `docs/privacidad.html`
   y `store/ficha.md` por el correo de contacto de la app.
3. Activa GitHub Pages: *Settings → Pages → Deploy from a branch → `main` /
   `/docs`*. Las URLs quedarán así:
   - Soporte: https://correiacristofer.github.io/domino-venezolano/
   - Privacidad: https://correiacristofer.github.io/domino-venezolano/privacidad.html

## 1. Google Play

1. **Cuenta de desarrollador** en https://play.google.com/console (25 USD, pago
   único). Si es una cuenta **personal creada después del 13-nov-2023**, Google
   exige una prueba cerrada con al menos 12 testers durante 14 días seguidos
   antes de poder publicar en producción. Una cuenta de organización (necesita
   número D-U-N-S) no tiene ese requisito.
2. **Clave de subida.** Instala un JDK 17 si no lo tienes
   (`winget install EclipseAdoptium.Temurin.17.JDK`) y ejecuta:
   ```
   powershell -ExecutionPolicy Bypass -File tool\release\crear_clave_android.ps1
   ```
   El script te pide la contraseña, crea `%USERPROFILE%\claves\domino-venezolano-upload.jks`
   y ofrece cargarla en GitHub como secretos (`ANDROID_KEYSTORE_BASE64`,
   `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`).
   Guarda el `.jks` y la contraseña en tu gestor de contraseñas.
3. **Build firmado:** en GitHub, *Actions → Builds → Run workflow* sobre `main`.
   Descarga el artefacto `android-firmado` y quédate con `app-release.aab`.
4. En Play Console: crea la app («Dominó Venezolano: La Libreta», español
   Latinoamérica, app gratuita), deja activada la firma de apps de Google Play y
   sube el `.aab` a **Prueba interna** (o **Prueba cerrada** si te aplica la
   regla de los 12 testers).
5. Rellena la ficha y los formularios con `store/ficha.md` y los recursos de
   `store/play/` y `store/screenshots/play/`.
6. Cuando se cumplan los requisitos, promociona la versión a **Producción**.

## 2. App Store

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

## 3. Versiones siguientes

- Sube `version:` en `pubspec.yaml` (por ejemplo `1.0.1+1`; el número tras el
  `+` lo sustituye el workflow por el número de ejecución, que siempre crece).
- Crea una etiqueta `v1.0.1` y súbela: el workflow genera los builds firmados
  y sube el de iOS a TestFlight.

## Regenerar iconos y capturas

```
flutter test tool/brand/render_brand_assets_test.dart
powershell -ExecutionPolicy Bypass -File tool\brand\flatten_ios_icons.ps1
flutter test tool/store/render_store_assets_test.dart
node tool/store/check_ficha.js
```
