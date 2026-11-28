param([switch]$Stop, [switch]$PortableDatabase, [switch]$SkipAi)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$runtimePython = Join-Path $projectRoot 'ai/.venv/Scripts/python.exe'
if ($env:FIRSTAID_PYTHON) {
    $runtimePython = $env:FIRSTAID_PYTHON
    if (-not (Test-Path -LiteralPath $runtimePython)) { throw 'FIRSTAID_PYTHON must point to a Python executable.' }
} elseif (-not (Test-Path -LiteralPath $runtimePython)) {
    $localPython = Join-Path $projectRoot '.local-tools/python/python.exe'
    if (Test-Path -LiteralPath $localPython) { $runtimePython = $localPython }
}
if (-not (Test-Path -LiteralPath $runtimePython)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        py -3.11 -m venv ai/.venv
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        python -m venv ai/.venv
    } else {
        throw 'Install Python 3.11 or later, then run this command again.'
    }
    if ($LASTEXITCODE -ne 0) { throw 'Cannot create the Python environment.' }
}
if (-not $Stop) {
    & $runtimePython -m pip install --quiet --disable-pip-version-check --no-warn-script-location -r ai/requirements-lock.txt -r tools/runtime-requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'Cannot install Python dependencies.' }
}
$launcherArgs = @('tools/run_local.py')
if ($Stop) { $launcherArgs += '--stop' }
if ($PortableDatabase) { $launcherArgs += '--portable-database' }
if ($SkipAi) { $launcherArgs += '--skip-ai' }
& $runtimePython @launcherArgs
exit $LASTEXITCODE
