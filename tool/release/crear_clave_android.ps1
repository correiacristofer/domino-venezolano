# Crea la clave de subida (upload key) de Google Play y, si quieres, la
# carga como secretos del repositorio para que GitHub Actions firme los
# builds de Android.
#
#   powershell -ExecutionPolicy Bypass -File tool\release\crear_clave_android.ps1
#
# Las contraseñas las escribes tú en esta consola; el script no las guarda en
# ningún archivo del repositorio. El almacén de claves queda FUERA del repo,
# en %USERPROFILE%\claves\. Guarda una copia del .jks y de la contraseña en tu
# gestor de contraseñas: sin ellos no podrás publicar actualizaciones con esta
# clave (con Play App Signing se puede pedir un cambio de clave, pero tarda).

$ErrorActionPreference = 'Stop'

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Host 'No encuentro keytool. Instala un JDK 17 y vuelve a ejecutar:' -ForegroundColor Yellow
    Write-Host '  winget install EclipseAdoptium.Temurin.17.JDK'
    exit 1
}

$keyDir = Join-Path $env:USERPROFILE 'claves'
$keystore = Join-Path $keyDir 'domino-venezolano-upload.jks'
$alias = 'upload'

if (Test-Path $keystore) {
    Write-Host "Ya existe $keystore. No lo sobrescribo." -ForegroundColor Yellow
    exit 1
}
New-Item -ItemType Directory -Force -Path $keyDir | Out-Null

function Read-Secret([string]$prompt) {
    $secure = Read-Host -AsSecureString $prompt
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

$password = Read-Secret 'Contraseña para la clave (mínimo 6 caracteres)'
$confirm = Read-Secret 'Repite la contraseña'
if ($password -ne $confirm -or $password.Length -lt 6) {
    Write-Host 'Las contraseñas no coinciden o son demasiado cortas.' -ForegroundColor Red
    exit 1
}

& keytool -genkeypair -v -keystore $keystore -storetype PKCS12 `
    -keyalg RSA -keysize 2048 -validity 10000 -alias $alias `
    -dname 'CN=Domino Venezolano, O=Cristofer Correia' `
    -storepass $password -keypass $password | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'keytool falló' }
Write-Host "Clave creada en $keystore" -ForegroundColor Green

# key.properties está en .gitignore; sirve para firmar en este PC.
$props = Join-Path $PSScriptRoot '..\..\android\key.properties'
@(
    "storePassword=$password"
    "keyPassword=$password"
    "keyAlias=$alias"
    "storeFile=$($keystore -replace '\\', '/')"
) | Set-Content -Encoding ascii $props
Write-Host 'android\key.properties escrito (no se sube a git).'

$answer = Read-Host '¿Cargar la clave como secretos de GitHub Actions? (s/n)'
if ($answer -eq 's') {
    $repo = 'correiacristofer/domino-venezolano'
    [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystore)) |
        gh secret set ANDROID_KEYSTORE_BASE64 --repo $repo
    $password | gh secret set ANDROID_KEYSTORE_PASSWORD --repo $repo
    $password | gh secret set ANDROID_KEY_PASSWORD --repo $repo
    $alias | gh secret set ANDROID_KEY_ALIAS --repo $repo
    Write-Host 'Secretos cargados en GitHub.' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Huella SHA-256 del certificado (la pide Play Console a veces):'
& keytool -list -v -keystore $keystore -alias $alias -storepass $password |
    Select-String 'SHA256'
