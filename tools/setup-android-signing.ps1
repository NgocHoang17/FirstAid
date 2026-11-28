# Run once on the machine responsible for signing the coursework Android release.
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$keyDir = Join-Path $project '.local/android-signing'
$keyPath = Join-Path $keyDir 'firstaid-upload.p12'
$properties = Join-Path $project 'mobile/android/key.properties'
if ((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath $properties)) {
    throw 'Signing files already exist. Restore or use the existing pair.'
}
New-Item -ItemType Directory -Force -Path $keyDir | Out-Null
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 36
$rng.GetBytes($bytes)
$rng.Dispose()
$password = [Convert]::ToBase64String($bytes)
$env:FIRSTAID_SIGN_PASSWORD = $password
try {
    & keytool -genkeypair -keystore $keyPath -storetype PKCS12 -storepass:env FIRSTAID_SIGN_PASSWORD -keypass:env FIRSTAID_SIGN_PASSWORD -alias upload -keyalg RSA -keysize 3072 -validity 9132 -dname "CN=FirstAid Coursework"
    if ($LASTEXITCODE -ne 0) { throw 'keytool failed' }
    [IO.File]::WriteAllLines($properties, @('storeFile=../../.local/android-signing/firstaid-upload.p12','keyAlias=upload',"storePassword=$password","keyPassword=$password"))
} finally {
    Remove-Item Env:FIRSTAID_SIGN_PASSWORD -ErrorAction SilentlyContinue
}
Write-Output 'Android signing is configured. Back up the keystore and key.properties privately.'
