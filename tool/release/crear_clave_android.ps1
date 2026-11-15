# Crea la clave de firma del APK y la sube a GitHub para que el workflow
# Release pueda publicar versiones. Se hace UNA sola vez.
#
# Lo más fácil: doble clic en tool\release\crear_clave_android.cmd
#
# Hace todo solo: instala el JDK si falta, comprueba tu sesión de GitHub,
# crea la clave y la sube como secretos del repositorio. Tú solo eliges la
# contraseña. La clave queda FUERA del repo, en %USERPROFILE%\claves\, y la
# contraseña no se guarda en ningún archivo del repositorio. Guarda una copia
# del .jks y de la contraseña en tu gestor de contraseñas: sin ellos no podrás
# publicar actualizaciones que se instalen encima de las anteriores.

# No global 'Stop': in Windows PowerShell 5.1 that turns any stderr output of
# gh or keytool into an exception even when they succeed. Every step checks
# $LASTEXITCODE instead.

$repo = 'correiacristofer/domino-venezolano'
$keyDir = Join-Path $env:USERPROFILE 'claves'
$keystore = Join-Path $keyDir 'domino-venezolano-upload.jks'
$alias = 'upload'

function Write-Step([string]$text) { Write-Host "`n$text" -ForegroundColor Cyan }

function Read-Secret([string]$prompt) {
    $secure = Read-Host -AsSecureString $prompt
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

# winget does not refresh PATH in this window, so look in the usual JDK
# folders as well.
function Find-Keytool {
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($root in @("$env:ProgramFiles\Eclipse Adoptium", "$env:ProgramFiles\Java", "$env:ProgramFiles\Microsoft")) {
        if (Test-Path $root) {
            $found = Get-ChildItem $root -Recurse -Filter keytool.exe -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

# 1. JDK (keytool) --------------------------------------------------------
Write-Step '1/4  Herramienta para crear la clave (JDK)'
$keytool = Find-Keytool
if (-not $keytool) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host 'No encuentro winget. Instala "Instalador de aplicación" desde Microsoft Store y vuelve a abrir este archivo.' -ForegroundColor Red
        exit 1
    }
    Write-Host 'No está instalado. Lo instalo ahora (Windows puede pedirte permiso)...'
    winget install --id EclipseAdoptium.Temurin.17.JDK -e
    $keytool = Find-Keytool
    if (-not $keytool) {
        Write-Host 'La instalación no terminó. Cierra esta ventana y vuelve a abrir el archivo.' -ForegroundColor Red
        exit 1
    }
}
Write-Host "Listo: $keytool" -ForegroundColor Green

# 2. GitHub session -------------------------------------------------------
Write-Step '2/4  Sesión de GitHub'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host 'No encuentro GitHub CLI. Instálalo con: winget install GitHub.cli' -ForegroundColor Red
    exit 1
}
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Tienes que iniciar sesión en GitHub (se abre el navegador).'
    gh auth login --web
    if ($LASTEXITCODE -ne 0) { Write-Host 'No se pudo iniciar sesión.' -ForegroundColor Red; exit 1 }
}
Write-Host 'Sesión iniciada.' -ForegroundColor Green

# 3. Key ------------------------------------------------------------------
Write-Step '3/4  Clave de firma'
if (Test-Path $keystore) {
    # A previous run created it: reuse it, never overwrite it.
    Write-Host "Ya tienes una clave en $keystore. La reutilizo."
    $password = Read-Secret 'Escribe su contraseña'
    & $keytool -list -keystore $keystore -storepass $password *> $null
    if ($LASTEXITCODE -ne 0) { Write-Host 'Esa contraseña no abre la clave.' -ForegroundColor Red; exit 1 }
} else {
    Write-Host 'Inventa una contraseña y guárdala en tu gestor de contraseñas.'
    $password = Read-Secret 'Contraseña (mínimo 6 caracteres)'
    $confirm = Read-Secret 'Repite la contraseña'
    if ($password -ne $confirm -or $password.Length -lt 6) {
        Write-Host 'Las contraseñas no coinciden o son demasiado cortas. Vuelve a abrir el archivo.' -ForegroundColor Red
        exit 1
    }
    New-Item -ItemType Directory -Force -Path $keyDir -ErrorAction Stop | Out-Null
    & $keytool -genkeypair -keystore $keystore -storetype PKCS12 `
        -keyalg RSA -keysize 2048 -validity 10000 -alias $alias `
        -dname 'CN=Domino Venezolano, O=Cristofer Correia' `
        -storepass $password -keypass $password *> $null
    if ($LASTEXITCODE -ne 0) { Write-Host 'No se pudo crear la clave.' -ForegroundColor Red; exit 1 }
    Write-Host "Clave creada en $keystore" -ForegroundColor Green
}

# key.properties is git-ignored; it lets this PC sign release builds too.
$props = Join-Path $PSScriptRoot '..\..\android\key.properties'
@(
    "storePassword=$password"
    "keyPassword=$password"
    "keyAlias=$alias"
    "storeFile=$($keystore -replace '\\', '/')"
) | Set-Content -Encoding ascii -ErrorAction Stop $props

# 4. GitHub secrets -------------------------------------------------------
Write-Step '4/4  Subir la clave a GitHub'
$answer = Read-Host 'Pulsa Enter para subirla (o escribe n para no hacerlo)'
if ($answer -ne 'n') {
    # Values go in --body: piping them would add a trailing newline and break
    # the password or the base64 in the workflow.
    $secrets = [ordered]@{
        ANDROID_KEYSTORE_BASE64   = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystore))
        ANDROID_KEYSTORE_PASSWORD = $password
        ANDROID_KEY_PASSWORD      = $password
        ANDROID_KEY_ALIAS         = $alias
    }
    foreach ($name in $secrets.Keys) {
        gh secret set $name --repo $repo --body $secrets[$name]
        if ($LASTEXITCODE -ne 0) { Write-Host "No se pudo subir $name." -ForegroundColor Red; exit 1 }
    }
    Write-Host 'Clave subida a GitHub.' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Todo listo. Ya se puede publicar la versión 1.0.0 del APK.' -ForegroundColor Green
Write-Host "Recuerda guardar $keystore y la contraseña en tu gestor de contraseñas."
