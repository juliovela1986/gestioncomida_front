# Genera upload-keystore.jks + key.properties para firma release Play.
# Uso interactivo:  .\create_upload_keystore.ps1
# Uso automatico:   .\create_upload_keystore.ps1 -Auto
# Backup offline del .jks y de las contraseñas — sin ellos no podrás actualizar la app en Play.

param(
    [switch]$Auto
)

$ErrorActionPreference = "Stop"
$androidDir = $PSScriptRoot
$jksPath = Join-Path $androidDir "upload-keystore.jks"
$propsPath = Join-Path $androidDir "key.properties"

if (Test-Path $jksPath) {
    Write-Error "Ya existe $jksPath. No se sobrescribe. Haz backup y renombra si quieres regenerar."
}
if (Test-Path $propsPath) {
    Write-Error "Ya existe $propsPath. No se sobrescribe."
}

$keytoolCmd = $null
$kt = Get-Command keytool -ErrorAction SilentlyContinue
if ($kt) {
    $keytoolCmd = $kt.Source
} else {
    $candidates = @(
        "$env:JAVA_HOME\bin\keytool.exe",
        "${env:ProgramFiles}\Android\Android Studio\jbr\bin\keytool.exe",
        "${env:LocalAppData}\Programs\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:USERPROFILE\scoop\apps\temurin21-jdk\current\bin\keytool.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { $keytoolCmd = $c; break }
    }
}
if (-not $keytoolCmd) {
    Write-Error "keytool no encontrado. Instala JDK o Android Studio y reintenta."
}

function New-StorePassword {
    $bytes = New-Object byte[] 24
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return [Convert]::ToBase64String($bytes) -replace '[+/=]', 'x'
}

if ($Auto) {
    $storePlain = New-StorePassword
    $keyPlain = $storePlain
    Write-Host "Modo -Auto: passwords generadas solo en key.properties (NO se imprimen)."
} else {
    $storePassword = Read-Host "storePassword (min 6 chars)" -AsSecureString
    $keyPassword = Read-Host "keyPassword (min 6 chars, puede ser igual)" -AsSecureString
    $storePlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword))
    $keyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword))
}

if ($storePlain.Length -lt 6 -or $keyPlain.Length -lt 6) {
    Write-Error "Passwords demasiado cortas."
}

& $keytoolCmd -genkeypair -v `
    -keystore $jksPath `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -alias upload `
    -storepass $storePlain `
    -keypass $keyPlain `
    -dname "CN=ScanTicketFresh, OU=Mobile, O=GestionComida, L=ES, C=ES"

# Sin BOM: Properties de Gradle falla con UTF-8 BOM de Set-Content -Encoding UTF8
$props = @"
storePassword=$storePlain
keyPassword=$keyPlain
keyAlias=upload
storeFile=upload-keystore.jks
"@
[System.IO.File]::WriteAllText($propsPath, $props)

Write-Host ""
Write-Host "OK: $jksPath"
Write-Host "OK: $propsPath (gitignored)"
Write-Host "IMPORTANTE: copia YA el .jks + abre key.properties y guarda las passwords en tu gestor."
Write-Host "Luego: cd .. ; flutter build appbundle --release"
